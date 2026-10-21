/**
 * Local-only security/load audit. Requires the isolated integration fixture DB.
 * Usage: AUDIT_BACKEND=/absolute/backend AUDIT_DATABASE_URL=postgres://.../gm_survey_audit
 *        node run-audit.cjs [--serve]
 * Never reads .env or starts AppModule, jobs, Firebase, or production clients.
 */
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const assert = require('assert/strict');
const { performance } = require('perf_hooks');
const backend = process.env.AUDIT_BACKEND;
const dbUrl = process.env.AUDIT_DATABASE_URL;
if (!backend || !dbUrl) throw Error('Explicit backend and isolated database required');
const parsed = new URL(dbUrl);
if (parsed.hostname !== '127.0.0.1' || parsed.port !== '55449' ||
    parsed.pathname !== '/gm_survey_audit') throw Error('Refusing non-audit database');
process.env.NODE_ENV = 'test';
process.env.TS_NODE_PROJECT = path.join(backend, 'tsconfig.json');
require(path.join(backend, 'node_modules/ts-node/register/transpile-only'));
require(path.join(backend, 'node_modules/reflect-metadata'));
const dep = p => require(path.join(backend, 'node_modules', p));
const src = p => require(path.join(backend, 'src', p));
const { Sequelize, DataTypes } = dep('sequelize');
const { Test } = dep('@nestjs/testing');
const { SurveyV3Controller } = src('surveyIntegrity/surveyV3.controller');
const { SurveyV3Service } = src('surveyIntegrity/surveyV3.service');
const { SurveyResultsService } = src('surveyIntegrity/results/surveyResults.service');
const { SequelizeSurveyStore } = src('surveyIntegrity/store/sequelizeSurveyStore');
const { loadSurveyIntegrityConfig } = src('surveyIntegrity/surveyIntegrity.config');
const { FakeAppCheckVerifier } = src('surveyIntegrity/appCheck/fakeAppCheck.verifier');
const { FixedWindowRateLimiter } = src('surveyIntegrity/util');
const { SurveyController } = src('survey/surveyController');
const { SurveyService } = src('survey/surveyService');
const { registerBodyParsers } = src('common/bodyLimits');
const { resolveTrustProxy } = src('common/trustProxy');
const APP = '1:111:ios:aaa';
const R1 = '11111111-1111-4111-8111-111111111111';
const R2 = '22222222-2222-4222-8222-222222222222';
const CAT = 'Mejor-Guachinche-Tradicional';
const report = { generatedAt: new Date().toISOString(), backend, environment: {
  database: 'isolated localhost:55449/gm_survey_audit', node: process.version,
  appCheck: 'FAKE verifier; no Apple/Google attestation or quotas tested',
  poolMax: 5, verifierDelayMsForLoad: 25,
}, checks: [], load: [] };
const burstMode = process.argv.includes('--burst');
const outputFile = path.join(__dirname, 'hardening-load-results.json');
const sequelize = new Sequelize(dbUrl, { logging: false, pool: { max: 5 } });
const store = new SequelizeSurveyStore(sequelize);
const config = (overrides = {}) => loadSurveyIntegrityConfig({
  NODE_ENV: 'test', SURVEY_INTEGRITY_MODE: 'fake',
  SURVEY_ALLOW_FAKE_INTEGRITY: 'true',
  SURVEY_ID_PEPPER: Buffer.alloc(32, 7).toString('base64'),
  FIREBASE_APP_ID_IOS: APP, FIREBASE_APP_ID_ANDROID: APP,
  ...overrides,
});
const cfg = config();
const verifier = new FakeAppCheckVerifier();
let verifyDelay = 0;
const delayedVerifier = { async verify(...args) {
  if (verifyDelay) await new Promise(r => setTimeout(r, verifyDelay));
  return verifier.verify(...args);
} };
const service = new SurveyV3Service(cfg, store, delayedVerifier, () => new Date(), new (src('surveyIntegrity/quotas').PostgresSurveyQuotas)(sequelize, cfg.idPepper));
const ranking = new SurveyResultsService(cfg, store, () => new Date());
const schema = sequelize.define('AuditSchema', {
  id: { type: DataTypes.INTEGER, primaryKey: true }, content: DataTypes.JSONB,
  integrity_policy: DataTypes.STRING, voting_starts_at: DataTypes.DATE,
  voting_ends_at: DataTypes.DATE, results_visibility: DataTypes.STRING,
}, { tableName: 'SurveySchemas' });
const resultModel = sequelize.define('AuditResult', {
  id: { type: DataTypes.INTEGER, primaryKey: true }, survey_schema_id: DataTypes.INTEGER,
  content: DataTypes.JSONB, user_id: DataTypes.UUID,
}, { tableName: 'SurveyResults' });
const legacy = new SurveyService(schema, resultModel);
const token = () => `fake-appcheck.${APP}.${crypto.randomUUID()}`;
const body = (id = crypto.randomBytes(32).toString('hex'), value = R1) => ({
  platform: 'ios', localIdHash: id, votes: [{ category: CAT, value }],
});
const q = (sql, replacements = {}) => sequelize.query(sql, { replacements });
const count = async () => Number((await q('SELECT COUNT(*) n FROM survey_device_votes'))[0][0].n);
let app, base;
async function http(method, route, data, tok = token(), ip = '198.51.100.1') {
  const start = performance.now();
  const res = await fetch(`${base}${route}`, {
    method, headers: { 'Content-Type': 'application/json', 'X-Firebase-AppCheck': tok,
      'X-Forwarded-For': ip }, body: data === undefined ? undefined : JSON.stringify(data),
    signal: AbortSignal.timeout(20000),
  });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text.slice(0, 100); }
  return { status: res.status, body: json, ms: performance.now() - start,
    retryAfter: res.headers.get('retry-after') };
}
const vote = (b, t, ip) => http('POST', '/surveys/v3/editions/2/votes', b, t, ip);
async function check(name, fn) {
  const evidence = await fn();
  report.checks.push({ name, ...evidence });
  console.log(JSON.stringify({ check: name, ...evidence }));
}
async function main() {
  const module = await Test.createTestingModule({
    controllers: [SurveyV3Controller],
    providers: [{ provide: SurveyV3Service, useValue: service }, {provide: SurveyResultsService, useValue: ranking}],
  }).compile();
  app = module.createNestApplication();
  app.useLogger(false);
  app.getHttpAdapter().getInstance().set('trust proxy', resolveTrustProxy({}));
  registerBodyParsers(app);
  await app.listen(3831, '127.0.0.1'); base = await app.getUrl();
  await q(`UPDATE "SurveySchemas" SET voting_starts_at=now()-interval '1 day',
    voting_ends_at=now()+interval '1 day', results_visibility='live', rate_limits=NULL WHERE id=2`);
  await q('TRUNCATE survey_device_votes, "SurveyResults", survey_devices, survey_rate_buckets RESTART IDENTITY CASCADE');
  verifyDelay = 25;
  async function run(n, concurrency, retry) {
    const statuses = {}, times = []; let next = 0;
    const start = performance.now();
    await Promise.all(Array.from({length: concurrency}, async () => {
      while (next < n) {
        const i = next++; const b = body();
        let r;
        for (let attempt = 0; attempt < 60; attempt++) {
          r = await vote(b, token(), `10.${Math.floor(i/60000)+1}.${Math.floor(i/250)%240}.${i%250+1}`);
          statuses[r.status] = (statuses[r.status] || 0) + 1;
          times.push(r.ms);
          if (r.status !== 503 || !retry) break;
          assert.ok(Number(r.retryAfter) >= 1);
          await new Promise(resolve => setTimeout(resolve, Number(r.retryAfter)*1000 + Math.random()*500));
        }
        if (retry) assert.equal(r.status, 201, JSON.stringify(r));
      }
    }));
    times.sort((a,b)=>a-b);
    return {n, concurrency, statuses, seconds: +( (performance.now()-start)/1000 ).toFixed(2),
      p95Ms: +times[Math.floor(times.length*.95)].toFixed(1), maxMs:+times.at(-1).toFixed(1)};
  }
  report.load.push(await run(10000,20,true)); console.log(JSON.stringify(report.load[0]));
  assert.equal(await count(),10000);
  sequelize.addHook('beforeQuery','slow',()=>new Promise(r=>setTimeout(r,20)));
  report.load.push(await run(600,200,true));
  sequelize.removeHook('beforeQuery','slow');
  assert.equal(await count(),10600);
  const [duplicates] = await q(`SELECT device_id, restaurant_id FROM survey_device_votes
    GROUP BY device_id, restaurant_id HAVING COUNT(*) > 1`);
  assert.equal(duplicates.length,0);
  report.persisted = await count(); report.duplicates = 0;
  fs.writeFileSync(outputFile, JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report.load));
}
main().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{
  if(app) await app.close(); await sequelize.close();
});
