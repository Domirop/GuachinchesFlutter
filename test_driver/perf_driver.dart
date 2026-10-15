// Driver de `integration_test/perf/`: guarda el informe de cada ejecución
// en build/perf/<nombre>.json.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        await writeResponseData(
          data,
          testOutputFilename: 'energy_census',
          destinationDirectory: 'build/perf',
        );
      },
    );
