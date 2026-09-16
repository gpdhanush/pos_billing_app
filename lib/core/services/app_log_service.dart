import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local file logger for offline crash / error diagnosis.
class AppLogService {
  AppLogService._();

  static const fileName = 'pos_billing_crash.log';
  static const _maxBytes = 512 * 1024; // 512 KB

  static IOSink? _sink;
  static File? _file;
  static String? _deviceBlock;
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(p.join(dir.path, 'logs'));
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      _file = File(p.join(logsDir.path, fileName));
      await _rotateIfNeeded();
      _deviceBlock = await _buildDeviceBlock();
      _sink = _file!.openWrite(mode: FileMode.append);
      await _writeLine('===== SESSION START ${_now()} =====');
      await _writeRaw(_deviceBlock!);
      _ready = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppLogService.init failed: $e\n$st');
      }
    }
  }

  static Future<File?> logFile() async {
    await init();
    return _file;
  }

  static Future<String> deviceSummary() async {
    await init();
    return _deviceBlock ?? await _buildDeviceBlock();
  }

  static Future<void> info(String message) => _append('INFO', message);

  static Future<void> warn(String message) => _append('WARN', message);

  static Future<void> error(
    Object error, [
    StackTrace? stack,
    String? context,
  ]) async {
    final buf = StringBuffer();
    if (context != null && context.trim().isNotEmpty) {
      buf.writeln('context: $context');
    }
    buf.writeln(error.toString());
    if (stack != null) {
      buf.writeln(stack.toString());
    }
    await _append('ERROR', buf.toString().trimRight());
  }

  static Future<void> crash(
    Object error, [
    StackTrace? stack,
    String? source,
  ]) async {
    final buf = StringBuffer();
    if (source != null) buf.writeln('source: $source');
    buf.writeln(error.toString());
    if (stack != null) buf.writeln(stack.toString());
    await _append('CRASH', buf.toString().trimRight());
  }

  /// Shares [pos_billing_crash.log] via the system share sheet so it can be
  /// sent on WhatsApp (wa.me cannot attach files).
  static Future<bool> sendLogsToSupport({String? userNote}) async {
    await init();
    final source = _file;
    if (source == null) return false;

    // Flush so the shared copy includes the latest lines.
    try {
      await _sink?.flush();
    } catch (_) {}

    if (!await source.exists()) {
      await _writeLine('[${_now()}] [INFO] Log file created for diagnostics');
      try {
        await _sink?.flush();
      } catch (_) {}
    }
    if (!await source.exists()) return false;

    // Copy to cache — WhatsApp/share intents are more reliable with a fresh
    // temp file and a clear .log name than an open append handle.
    File shareFile;
    try {
      final cache = await getTemporaryDirectory();
      shareFile = File(p.join(cache.path, fileName));
      await source.copy(shareFile.path);
      // Touch mtime / ensure readable.
      if (!await shareFile.exists() || await shareFile.length() == 0) {
        final fallback = StringBuffer()
          ..writeln('POS Billing diagnostic log')
          ..writeln(await deviceSummary())
          ..writeln('---')
          ..writeln('Generated: ${_now()}');
        await shareFile.writeAsString(fallback.toString(), flush: true);
      }
    } catch (_) {
      shareFile = source;
    }

    final note = userNote?.trim() ?? '';
    final text = StringBuffer()
      ..writeln('POS Billing crash / diagnostic log ($fileName)')
      ..writeln('Please send this file to ${AppLinks.supportPhone}')
      ..writeln('App ${DbConstants.appVersion}');
    if (note.isNotEmpty) {
      text
        ..writeln()
        ..writeln('Note: $note');
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              shareFile.path,
              mimeType: 'text/plain',
              name: fileName,
            ),
          ],
          subject: 'POS Billing log — ${DbConstants.appVersion}',
          text: text.toString(),
        ),
      );
      // success / dismissed both mean the sheet opened with the file.
      return result.status != ShareResultStatus.unavailable;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('sendLogsToSupport share failed: $e\n$st');
      }
      // Last resort: open WhatsApp chat (text only — no file).
      try {
        final wa = Uri.parse(
          'https://wa.me/${AppLinks.supportWhatsAppE164}'
          '?text=${Uri.encodeComponent(
            'Hi, I need help with POS Billing ${DbConstants.appVersion}. '
            'I could not attach $fileName — please reply so I can resend.',
          )}',
        );
        return await launchUrl(wa, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<void> _append(String level, String message) async {
    await init();
    final stamped = '[${_now()}] [$level] $message';
    await _writeLine(stamped);
    if (kDebugMode) debugPrint(stamped);
  }

  static Future<void> _writeLine(String line) async {
    await _writeRaw('$line\n');
  }

  static Future<void> _writeRaw(String text) async {
    try {
      if (_sink != null) {
        _sink!.write(text);
        await _sink!.flush();
      } else if (_file != null) {
        await _file!.writeAsString(text, mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }

  static Future<void> _rotateIfNeeded() async {
    final file = _file;
    if (file == null || !await file.exists()) return;
    final len = await file.length();
    if (len <= _maxBytes) return;
    final bak = File('${file.path}.1');
    if (await bak.exists()) await bak.delete();
    await file.rename(bak.path);
    _file = File(p.join(p.dirname(bak.path), fileName));
  }

  static String _now() =>
      DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());

  static Future<String> _buildDeviceBlock() async {
    final buf = StringBuffer()..writeln('--- DEVICE ---');
    try {
      final pkg = await PackageInfo.fromPlatform();
      buf
        ..writeln('app: ${pkg.appName}')
        ..writeln('package: ${pkg.packageName}')
        ..writeln('version: ${pkg.version}+${pkg.buildNumber}')
        ..writeln('db_schema: ${DbConstants.schemaVersion}');
    } catch (_) {
      buf.writeln('version: ${DbConstants.appVersion}');
    }

    buf
      ..writeln('platform: ${defaultTargetPlatform.name}')
      ..writeln('dart: ${Platform.version.split(' ').first}')
      ..writeln('locale: ${Platform.localeName}');

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        buf
          ..writeln(
            'os: Android ${a.version.release} (SDK ${a.version.sdkInt})',
          )
          ..writeln('brand: ${a.brand}')
          ..writeln('manufacturer: ${a.manufacturer}')
          ..writeln('model: ${a.model}')
          ..writeln('device: ${a.device}')
          ..writeln('product: ${a.product}')
          ..writeln('hardware: ${a.hardware}')
          ..writeln('isPhysicalDevice: ${a.isPhysicalDevice}');
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        buf
          ..writeln('os: ${i.systemName} ${i.systemVersion}')
          ..writeln('model: ${i.model}')
          ..writeln('name: ${i.name}')
          ..writeln('utsname: ${i.utsname.machine}')
          ..writeln('isPhysicalDevice: ${i.isPhysicalDevice}');
      } else {
        buf.writeln(
          'os: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        );
      }
    } catch (e) {
      buf.writeln('device_info_error: $e');
    }
    buf.writeln('--- END DEVICE ---');
    return buf.toString();
  }
}
