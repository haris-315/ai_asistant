import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String moodyVar(String key) {
  if (!kReleaseMode) {
    return dotenv.env[key] ?? "";
  } else {
    return String.fromEnvironment(key);
  }
}
