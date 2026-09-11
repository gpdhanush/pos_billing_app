import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billing/app/app.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/errors/app_error_handler.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorHandler.install();

    final db = await AppDatabase.open();
    runApp(
      ProviderScope(
        overrides: [
          // Seed DB; logout wipe / backup restore may replace via notifier.
          databaseHolderProvider.overrideWith((ref) => db),
        ],
        child: const PosApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
      return;
    }
    appCrashNotifier.value = AppCrashInfo.fromObject(error, stack);
  });
}
