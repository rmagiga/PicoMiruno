import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

late final Logger logger;

void setupLogger() {
  if (kReleaseMode) {
    logger = Logger(level: Level.warning, output: NullOutput());
  } else {
    logger = Logger(level: Level.debug, output: ConsoleOutput());
  }
}

// ignore: unreachable_from_main
class NullOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // No output in release mode
  }
}
