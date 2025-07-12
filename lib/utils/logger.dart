import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(
  level: kReleaseMode ? Level.warning : Level.debug, // 本番はwarning以上、開発はdebug以上
);
