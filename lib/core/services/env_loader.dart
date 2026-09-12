import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads `.env` (preferred) or falls back to `.env.example`.
Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('load .env failed, trying .env.example: $e');
    }
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (e2) {
      if (kDebugMode) {
        debugPrint('load .env.example failed: $e2');
      }
    }
  }
}
