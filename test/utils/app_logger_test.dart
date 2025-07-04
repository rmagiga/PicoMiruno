import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:pico_miruno/utils/app_logger.dart';

void main() {
  test('setupLoggerでloggerがdebugログを出力できる', () {
    setupLogger();
    expect(() => logger.log(Level.debug, 'test'), returnsNormally);
  });

  test('NullOutput.outputで例外が出ない', () {
    final NullOutput output = NullOutput();
    final OutputEvent event = OutputEvent(LogEvent(Level.debug, 'test'), <String>['test']);
    expect(() => output.output(event), returnsNormally);
  });
}
