import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  if (options.help) {
    _printUsage(options.doctor);
    return;
  }

  final projectRoot = Directory.current;

  if (!File('${projectRoot.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this command from your Flutter app root.');
    exitCode = 64;
    return;
  }

  final returnScheme = options.returnScheme?.trim().isNotEmpty == true
      ? options.returnScheme!.trim()
      : _defaultReturnScheme(projectRoot);

  if (options.doctor && !options.fix) {
    _runDiagnostics(
      projectRoot: projectRoot,
      returnScheme: returnScheme,
    );
    return;
  }

  if (options.fix) {
    _patchAndroidMainActivity(projectRoot);
    _patchIosInfoPlist(projectRoot, returnScheme);
    _runDiagnostics(
      projectRoot: projectRoot,
      returnScheme: returnScheme,
    );
    stdout.writeln('');
    stdout.writeln('Telebirr doctor auto-fix complete.');
    return;
  }

  _runDiagnostics(
    projectRoot: projectRoot,
    returnScheme: returnScheme,
  );
}

void _patchAndroidMainActivity(Directory projectRoot) {
  final androidSrc = Directory('${projectRoot.path}/android/app/src/main');
  if (!androidSrc.existsSync()) {
    stdout.writeln('Android host app not found. Skipped MainActivity patch.');
    return;
  }

  final files = androidSrc
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('MainActivity.kt') ||
          file.path.endsWith('MainActivity.java'))
      .toList();

  if (files.isEmpty) {
    stdout.writeln('MainActivity not found. Skipped Android activity patch.');
    return;
  }

  for (final file in files) {
    var content = file.readAsStringSync();
    if (content.contains('FlutterFragmentActivity')) {
      stdout.writeln(
          'Android MainActivity already uses FlutterFragmentActivity.');
      return;
    }

    if (file.path.endsWith('.kt')) {
      content = content
          .replaceAll('import io.flutter.embedding.android.FlutterActivity',
              'import io.flutter.embedding.android.FlutterFragmentActivity')
          .replaceAll(': FlutterActivity()', ': FlutterFragmentActivity()');
    } else {
      content = content
          .replaceAll('import io.flutter.embedding.android.FlutterActivity;',
              'import io.flutter.embedding.android.FlutterFragmentActivity;')
          .replaceAll(
              'extends FlutterActivity', 'extends FlutterFragmentActivity');
    }

    file.writeAsStringSync(content);
    stdout.writeln('Patched Android MainActivity: ${file.path}');
    return;
  }
}

void _patchIosInfoPlist(Directory projectRoot, String scheme) {
  final plist = File('${projectRoot.path}/ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    stdout.writeln('iOS Info.plist not found. Skipped iOS URL setup.');
    return;
  }

  var content = plist.readAsStringSync();
  if (!content.contains('telebirrcustomerApp')) {
    content = content.replaceFirst(
      '</dict>',
      '''
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>telebirrcustomerApp</string>
	</array>
</dict>''',
    );
  }

  if (!content.contains('<string>$scheme</string>')) {
    content = content.replaceFirst(
      '</dict>',
      '''
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>$scheme</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>$scheme</string>
			</array>
		</dict>
	</array>
</dict>''',
    );
  }

  plist.writeAsStringSync(content);
  stdout.writeln('Patched iOS Info.plist for return scheme: $scheme.');
}

void _runDiagnostics({
  required Directory projectRoot,
  required String returnScheme,
}) {
  stdout.writeln('');
  stdout.writeln('Telebirr Doctor');
  stdout.writeln('');
  _check(
      'Flutter project', File('${projectRoot.path}/pubspec.yaml').existsSync());
  _check(
      'Android project', Directory('${projectRoot.path}/android').existsSync());
  _check('iOS project', Directory('${projectRoot.path}/ios').existsSync());
  _check(
      'Android MainActivity', _mainActivityUsesFragmentActivity(projectRoot));
  _check('iOS telebirrcustomerApp',
      _iosPlistContains(projectRoot, 'telebirrcustomerApp'));
  _check('iOS return scheme $returnScheme',
      _iosPlistContains(projectRoot, returnScheme));

  stdout.writeln('');
  stdout.writeln('Generated return scheme: $returnScheme');
}

void _check(String label, bool passed) {
  stdout.writeln('${passed ? '✓' : '✗'} $label');
}

bool _mainActivityUsesFragmentActivity(Directory projectRoot) {
  final androidSrc = Directory('${projectRoot.path}/android/app/src/main');
  if (!androidSrc.existsSync()) return false;
  return androidSrc
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('MainActivity.kt') ||
          file.path.endsWith('MainActivity.java'))
      .any((file) =>
          file.readAsStringSync().contains('FlutterFragmentActivity'));
}

bool _iosPlistContains(Directory projectRoot, String value) {
  final plist = File('${projectRoot.path}/ios/Runner/Info.plist');
  return plist.existsSync() && plist.readAsStringSync().contains(value);
}

String _defaultReturnScheme(Directory projectRoot) {
  final appId = _detectAndroidApplicationId(projectRoot) ??
      _detectIosBundleId(projectRoot) ??
      'flutter-app';
  return 'telebirr-${appId.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}'
      .toLowerCase();
}

String? _detectAndroidApplicationId(Directory projectRoot) {
  final candidates = <File>[
    File('${projectRoot.path}/android/app/build.gradle.kts'),
    File('${projectRoot.path}/android/app/build.gradle'),
  ];
  for (final file in candidates) {
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    final match =
        RegExp(r'applicationId\s*[= ]\s*["' "'" r']([^"' "'" r']+)["' "'" r']')
            .firstMatch(content);
    if (match != null) return match.group(1);
  }
  return null;
}

String? _detectIosBundleId(Directory projectRoot) {
  final project =
      File('${projectRoot.path}/ios/Runner.xcodeproj/project.pbxproj');
  if (!project.existsSync()) return null;
  final match = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
      .firstMatch(project.readAsStringSync());
  return match?.group(1)?.replaceAll(r'$(PRODUCT_NAME)', 'app').trim();
}

void _printUsage(bool doctor) {
  stdout.writeln('''
Telebirr ${doctor ? 'doctor' : 'setup'} helper

Run from your Flutter app root:

  dart run telebirr_inapp_purchase_plus:doctor

Auto-fix common setup issues:

  dart run telebirr_inapp_purchase_plus:doctor --fix

Use a custom return scheme:

  dart run telebirr_inapp_purchase_plus:doctor --fix --return-scheme yourappscheme

The command:
- validates Android and iOS setup
- changes Android MainActivity to FlutterFragmentActivity
- adds iOS telebirrcustomerApp and return URL scheme entries
''');
}

class _Options {
  final String? returnScheme;
  final bool help;
  final bool doctor;
  final bool fix;

  const _Options({
    required this.returnScheme,
    required this.help,
    required this.doctor,
    required this.fix,
  });

  factory _Options.parse(List<String> args) {
    String? returnScheme;
    var help = false;
    var doctor = false;
    var fix = false;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg == '--doctor') {
        doctor = true;
      } else if (arg == '--fix') {
        fix = true;
      } else if (arg == '--return-scheme' && index + 1 < args.length) {
        returnScheme = args[++index];
      } else if (arg.startsWith('--return-scheme=')) {
        returnScheme = arg.substring('--return-scheme='.length);
      }
    }

    return _Options(
      returnScheme: returnScheme,
      help: help,
      doctor: doctor,
      fix: fix,
    );
  }
}
