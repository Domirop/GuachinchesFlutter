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
const outputFile = path.join(__dirname, burstMode ? 'burst-results.json' : 'results.json');
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
const service = new SurveyV3Service(cfg, store, delayedVerifier, () => new Date());
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
    controllers: [SurveyV3Controller, SurveyController],
    providers: [{ provide: SurveyV3Service, useValue: service },
      { provide: SurveyResultsService, useValue: ranking },
      { provide: SurveyService, useValue: legacy }],
  }).compile();
  app = module.createNestApplication();
  app.useLogger(false);
  app.getHttpAdapter().getInstance().set('trust proxy', resolveTrustProxy({}));
  registerBodyParsers(app);
  await app.listen(burstMode ? 3830 : 3829, '127.0.0.1');
  base = await app.getUrl();
  await q(`UPDATE "SurveySchemas" SET voting_starts_at=now()-interval '1 day',
    voting_ends_at=now()+interval '1 day', results_visibility='live', rate_limits=NULL WHERE id=2`);
  if (burstMode) {
    const bodies = Array.from({ length: 600 }, () => body());
    const { identityHash } = src('surveyIntegrity/identity');
    const hashes = bodies.map(b => identityHash(cfg.idPepper, b.platform, b.localIdHash));
    verifyDelay = 25;
    sequelize.addHook('beforeQuery', 'audit-burst-latency',
      () => new Promise(resolve => setTimeout(resolve, 20)));
    const statuses = {};
    const start = performance.now();
    await Promise.all(bodies.map(async (b, i) => {
      try {
        const r = await vote(b, token(), `10.200.${i % 256}.${Math.floor(i / 256) + 1}`);
        statuses[r.status] = (statuses[r.status] || 0) + 1;
      } catch (e) {
        statuses[e.name] = (statuses[e.name] || 0) + 1;
      }
    }));
    const clientsFinishedSeconds = (performance.now() - start) / 1000;
    let persisted = 0;
    for (let i = 0; i < 40; i++) {
      const [rows] = await q(`SELECT COUNT(*) n FROM survey_device_votes v
        JOIN survey_devices d ON d.id=v.device_id WHERE d.identity_hash IN (:hashes)`, { hashes });
      persisted = Number(rows[0].n);
      if (persisted === 600) break;
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    report.burst = { concurrency: 600, attempts: 600, perQueryDelayMs: 20,
      clientTimeoutMs: 20000, statuses, clientsFinishedSeconds: +clientsFinishedSeconds.toFixed(2),
      persistedAfterDrain: persisted, totalSeconds: +((performance.now() - start) / 1000).toFixed(2) };
    console.log(JSON.stringify(report.burst));
    sequelize.removeHook('beforeQuery', 'audit-burst-latency');
    return;
  }
  if (process.argv.includes('--serve')) {
    console.log('AUDIT_READY localhost:3829; synthetic tokens only; Ctrl-C to stop');
    return;
  }
  await q('TRUNCATE survey_device_votes, "SurveyResults", survey_devices RESTART IDENTITY CASCADE');
  await check('missing token / invalid DTO / SQL payload / oversized JSON', async () => {
    const a = await vote(body(), '');
    const b = await vote({ ...body(), localIdHash: 'x', unexpected: true });
    const c = await vote({ ...body(), votes: [{ category: "'; SELECT pg_sleep(5)--", value: R1 }] });
    const d = await vote({ ...body(), padding: 'x'.repeat(17000) });
    assert.deepEqual([a.status, b.status, c.status, d.status], [403, 400, 422, 413]);
    assert.equal(await count(), 0);
    return { status: 'pass', http: [403, 400, 422, 413], votes: 0 };
  });
  await check('50 concurrent same-identity submissions', async () => {
    cfg.limits.votesPerDevicePerMin = 1000;
    const b = body();
    const res = await Promise.all(Array.from({ length: 50 }, () => vote(b)));
    const codes = res.reduce((a, r) => (a[r.status] = (a[r.status] || 0) + 1, a), {});
    assert.deepEqual(codes, { 201: 1, 409: 49 });
    assert.equal(await count(), 1);
    return { status: 'pass', http: codes, persisted: 1 };
  });
  await check('replay same token', async () => {
    const t = token();
    assert.equal((await vote(body(), t)).status, 201);
    const r = await vote(body(), t);
    assert.equal(r.status, 403);
    return { status: 'pass', http: r.status, reason: r.body.details.reason };
  });
  await check('identity substitution with fresh accepted tokens', async () => {
    const before = await count();
    const outcomes = [];
    for (let i = 0; i < 10; i++) outcomes.push((await vote(body())).status);
    assert(outcomes.every(x => x === 201));
    return { status: 'risk reproduced', freshCallerChosenIdentities: 10,
      addedVotesForSameBusiness: (await count()) - before,
      caveat: 'Verifier is fake. Demonstrates absent identity binding, not a real attestation bypass.' };
  });
  await check('hidden ranking exposed through legacy route', async () => {
    await q(`UPDATE "SurveySchemas" SET results_visibility='after_close' WHERE id=2`);
    const modern = await http('GET', '/surveys/v3/editions/2/results');
    const old = await http('GET', `/surveys/results/2/${CAT}`);
    assert.equal(modern.body.hidden, true);
    assert.equal(old.status, 200);
    assert(Number(old.body[0].votes) > 0);
    return { status: 'finding confirmed', modernHidden: modern.body.hidden,
      legacyHttp: old.status, leakedVotes: old.body };
  });
  await check('legacy ranking ignores read rate limit', async () => {
    const old = cfg.limits.readsPerIpPerMin;
    cfg.limits.readsPerIpPerMin = 1;
    const current = [];
    const legacyCodes = [];
    for (let i = 0; i < 3; i++) {
      current.push((await http('GET', '/surveys/v3/editions/current', undefined, '', '198.18.2.1')).status);
      legacyCodes.push((await http('GET', `/surveys/results/2/${CAT}`, undefined, '', '198.18.2.1')).status);
    }
    cfg.limits.readsPerIpPerMin = old;
    assert.deepEqual(current, [200, 429, 429]);
    assert.deepEqual(legacyCodes, [200, 200, 200]);
    return { status: 'finding confirmed', modern: current, legacy: legacyCodes };
  });
  await check('Firebase unavailable fails closed and recovers', async () => {
    const before = await count();
    verifier.unavailable = true;
    const b = body();
    const res = await vote(b);
    assert.equal(res.status, 503);
    assert.equal(await count(), before);
    verifier.unavailable = false;
    assert.equal((await vote(b)).status, 201);
    return { status: 'pass', unavailableHttp: res.status, retryAfter: res.retryAfter,
      recoveryHttp: 201 };
  });
  await check('read failure after COMMIT returns 500 although vote persisted', async () => {
    const original = store.votedBy.bind(store);
    const before = await count();
    store.votedBy = async () => { throw Error('injected post-commit read outage'); };
    const b = body();
    const first = await vote(b);
    store.votedBy = original;
    const persisted = (await count()) - before;
    const retry = await vote(b);
    assert.deepEqual([first.status, persisted, retry.status], [500, 1, 409]);
    return { status: 'finding confirmed', firstHttp: 500, persisted: 1, retryHttp: 409 };
  });
  await check('request verified after edition closes', async () => {
    await q(`UPDATE "SurveySchemas" SET voting_ends_at=now()+interval '100 milliseconds' WHERE id=2`);
    verifyDelay = 300;
    const res = await vote(body());
    verifyDelay = 0;
    const [rows] = await q(`SELECT COUNT(*) n FROM survey_device_votes v JOIN "SurveySchemas" s
      ON s.id=v.survey_schema_id WHERE v.created_at>s.voting_ends_at`);
    await q(`UPDATE "SurveySchemas" SET voting_ends_at=now()+interval '1 day' WHERE id=2`);
    assert.equal(res.status, 201);
    assert(Number(rows[0].n) > 0);
    return { status: 'finding confirmed', http: res.status,
      committedAfterClose: Number(rows[0].n), verifierDelayMs: 300 };
  });
  await check('shared network: 301 fresh voters over four simulated minutes', async () => {
    const nat = new SurveyV3Service(config(), store, new FakeAppCheckVerifier(), () => new Date());
    let time = Date.now();
    nat.limiter = new FixedWindowRateLimiter(() => time);
    const codes = {};
    for (let i = 0; i < 301; i++) {
      if (i > 0 && i % 100 === 0) time += 61000;
      try { await nat.vote(2, body(), token(), '203.0.113.50'); codes[201] = (codes[201] || 0) + 1; }
      catch (e) { codes[e.getStatus()] = (codes[e.getStatus()] || 0) + 1; }
    }
    assert.deepEqual(codes, { 201: 300, 429: 1 });
    return { status: 'capacity constraint confirmed', http: codes,
      scope: 'one /24, default 300 new identities/hour/pod; limiter clock accelerated' };
  });
  // Fresh baseline for the exactly 10,000 accepted vote load test.
  await q('TRUNCATE survey_device_votes, "SurveyResults", survey_devices RESTART IDENTITY CASCADE');
  await q(`UPDATE "SurveySchemas" SET results_visibility='live', rate_limits=NULL WHERE id=2`);
  service.limiter = new FixedWindowRateLimiter();
  ranking.cache.clear();
  verifyDelay = 25;
  let issued = 0;
  for (const [concurrency, n] of [[10, 2000], [50, 3000], [200, 5000]]) {
    const durations = [];
    const codes = {};
    let cursor = 0;
    const start = performance.now();
    const rssBefore = process.memoryUsage().rss;
    await Promise.all(Array.from({ length: concurrency }, async () => {
      while (cursor < n) {
        const i = cursor++;
        const serial = issued++;
        const ip = `10.${Math.floor(serial / 256)}.${serial % 256}.1`;
        const b = body();
        // 20% of users also open current edition + consult my-votes.
        if (i % 5 === 0) {
          const current = await http('GET', '/surveys/v3/editions/current', undefined, '', ip);
          const mine = await http('POST', '/surveys/v3/editions/2/my-votes',
            { platform: b.platform, localIdHash: b.localIdHash }, token(), ip);
          assert.equal(current.status, 200);
          assert.equal(mine.status, 200);
        }
        const r = await vote(b, token(), ip);
        codes[r.status] = (codes[r.status] || 0) + 1;
        durations.push(r.ms);
      }
    }));
    durations.sort((a, b) => a - b);
    const seconds = (performance.now() - start) / 1000;
    const metric = { concurrency, attempts: n, statuses: codes, seconds: +seconds.toFixed(2),
      acceptedVotesPerSecond: +((codes[201] || 0) / seconds).toFixed(1),
      p50Ms: +durations[Math.floor(n * .50)].toFixed(1),
      p95Ms: +durations[Math.floor(n * .95)].toFixed(1),
      p99Ms: +durations[Math.floor(n * .99)].toFixed(1),
      rssBeforeMB: +(rssBefore / 1048576).toFixed(1),
      rssAfterMB: +(process.memoryUsage().rss / 1048576).toFixed(1) };
    report.load.push(metric);
    console.log(JSON.stringify({ load: metric }));
    assert.deepEqual(codes, { 201: n });
  }
  const [integrity] = await q(`SELECT
    (SELECT COUNT(*) FROM survey_device_votes) AS votes,
    (SELECT COUNT(*) FROM survey_devices) AS devices,
    (SELECT COUNT(*) FROM "SurveyResults") AS results,
    (SELECT COUNT(*) FROM (SELECT survey_schema_id, device_id, restaurant_id
       FROM survey_device_votes GROUP BY 1,2,3 HAVING COUNT(*)>1) d) AS duplicates,
    (SELECT COUNT(*) FROM survey_device_votes v LEFT JOIN "SurveyResults" r
       ON r.id=v.survey_result_id WHERE r.id IS NULL) AS orphan_votes`);
  report.integrity = integrity[0];
  assert.equal(Number(report.integrity.votes), 10000);
  assert.equal(Number(report.integrity.results), 10000);
  assert.equal(Number(report.integrity.duplicates), 0);
  assert.equal(Number(report.integrity.orphan_votes), 0);
  await check('ranking after 10,000 votes and concurrent cache miss', async () => {
    ranking.cache.clear();
    let loads = 0;
    const original = store.loadResultsData.bind(store);
    store.loadResultsData = (...args) => { loads++; return original(...args); };
    const start = performance.now();
    const res = await Promise.all(Array.from({ length: 100 }, () =>
      http('GET', '/surveys/v3/editions/2/results', undefined, '', '198.19.1.1')));
    assert(res.every(r => r.status === 200));
    assert.equal(loads, 1);
    return { status: 'pass', simultaneousReads: 100, databaseLoads: loads,
      elapsedMs: +(performance.now() - start).toFixed(1) };
  });
  const [timeouts] = await q("SELECT current_setting('statement_timeout') AS statement_timeout");
  report.databaseStatementTimeout = timeouts[0].statement_timeout;
  // Sensitivity test, not a production benchmark: simulate 20 ms on every
  // database query while holding its acquired connection.
  let slowQueries = 0;
  sequelize.addHook('beforeQuery', 'audit-latency', async () => {
    slowQueries++;
    await new Promise(resolve => setTimeout(resolve, 20));
  });
  try {
    const durations = [], statuses = {};
    let cursor = 0;
    const start = performance.now();
    await Promise.all(Array.from({ length: 100 }, async () => {
      while (cursor < 300) {
        const serial = cursor++;
        const r = await vote(body(), token(), `172.20.${serial % 256}.1`);
        statuses[r.status] = (statuses[r.status] || 0) + 1;
        durations.push(r.ms);
      }
    }));
    durations.sort((a, b) => a - b);
    report.slowDatabase = { injectedQueryDelayMs: 20, concurrency: 100, attempts: 300,
      queries: slowQueries, statuses, seconds: +((performance.now() - start) / 1000).toFixed(2),
      p95Ms: +durations[Math.floor(durations.length * .95)].toFixed(1) };
    console.log(JSON.stringify({ slowDatabase: report.slowDatabase }));
    assert.deepEqual(statuses, { 201: 300 });
  } finally {
    sequelize.removeHook('beforeQuery', 'audit-latency');
  }
}
main().then(async () => {
  if (process.argv.includes('--serve')) return;
  fs.writeFileSync(outputFile, JSON.stringify(report, null, 2));
  await app?.close();
  await sequelize.close();
}).catch(async e => {
  report.failure = { name: e.name, message: e.message };
  fs.writeFileSync(outputFile, JSON.stringify(report, null, 2));
  console.error(e.name, e.message);
  await app?.close();
  await sequelize.close();
  process.exitCode = 1;
});
