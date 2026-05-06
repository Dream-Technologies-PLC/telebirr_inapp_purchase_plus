import 'dart:io';
import 'dart:isolate';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  if (options.help) {
    _printUsage();
    return;
  }

  if (options.sdkDir == null) {
    stderr.writeln('Missing --sdk-dir.');
    _printUsage();
    exitCode = 64;
    return;
  }

  final projectRoot = Directory.current;
  final packageRoot = await _packageRoot();
  final sdkDir = Directory(options.sdkDir!);

  if (!File('${projectRoot.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this command from your Flutter app root.');
    exitCode = 64;
    return;
  }
  if (!sdkDir.existsSync()) {
    stderr.writeln('SDK folder not found: ${sdkDir.path}');
    exitCode = 66;
    return;
  }

  _copyAndroidSdkFiles(sdkDir, packageRoot);
  _copyIosFramework(sdkDir, packageRoot);
  _patchAndroidMainActivity(projectRoot);
  if (options.returnScheme != null && options.returnScheme!.trim().isNotEmpty) {
    _patchIosInfoPlist(projectRoot, options.returnScheme!.trim());
  }

  stdout.writeln('');
  stdout.writeln('Telebirr setup complete.');
  stdout.writeln('Next steps:');
  stdout.writeln('1. Run flutter clean');
  stdout.writeln('2. Run flutter pub get');
  stdout.writeln('3. On iOS, run cd ios && pod install');
}

Future<Directory> _packageRoot() async {
  final libraryUri = await Isolate.resolvePackageUri(
    Uri.parse(
        'package:telebirr_inapp_purchase_plus/telebirr_inapp_purchase_plus.dart'),
  );
  if (libraryUri == null || libraryUri.scheme != 'file') {
    stderr.writeln(
        'Could not locate telebirr_inapp_purchase_plus package files.');
    exit(70);
  }
  return File(libraryUri.toFilePath()).parent.parent;
}

void _copyAndroidSdkFiles(Directory sdkDir, Directory packageRoot) {
  final libsDir = Directory('${packageRoot.path}/android/libs')
    ..createSync(recursive: true);
  final uat = _findFirst(sdkDir, 'EthiopiaPaySdkModule-uat-release.aar');
  final prod = _findFirst(sdkDir, 'EthiopiaPaySdkModule-prod-release.aar');

  if (uat == null) {
    stdout.writeln('Android UAT AAR not found. Skipped.');
  } else {
    uat.copySync('${libsDir.path}/EthiopiaPaySdkModule-uat-release.aar');
    stdout.writeln('Copied Android UAT AAR.');
  }

  if (prod == null) {
    stdout.writeln('Android production AAR not found. Skipped.');
  } else {
    prod.copySync('${libsDir.path}/EthiopiaPaySdkModule-prod-release.aar');
    stdout.writeln('Copied Android production AAR.');
  }

  _createMavenArtifact(
    packageRoot: packageRoot,
    artifactId: 'ethiopia-pay-sdk-uat',
    aarName: 'EthiopiaPaySdkModule-uat-release.aar',
  );
  _createMavenArtifact(
    packageRoot: packageRoot,
    artifactId: 'ethiopia-pay-sdk-prod',
    aarName: 'EthiopiaPaySdkModule-prod-release.aar',
  );
}

void _createMavenArtifact({
  required Directory packageRoot,
  required String artifactId,
  required String aarName,
}) {
  final aar = File('${packageRoot.path}/android/libs/$aarName');
  if (!aar.existsSync()) {
    return;
  }

  final artifactDir = Directory(
    '${packageRoot.path}/android/libs-maven/com/telebirr/sdk/$artifactId/1.0.0',
  )..createSync(recursive: true);

  aar.copySync('${artifactDir.path}/$artifactId-1.0.0.aar');
  File('${artifactDir.path}/$artifactId-1.0.0.pom').writeAsStringSync('''
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.telebirr.sdk</groupId>
  <artifactId>$artifactId</artifactId>
  <version>1.0.0</version>
  <packaging>aar</packaging>
</project>
''');
  stdout.writeln('Created local Maven artifact: $artifactId.');
}

void _copyIosFramework(Directory sdkDir, Directory packageRoot) {
  final framework = _findFirstDirectory(sdkDir, 'EthiopiaPaySDK.framework');
  if (framework == null) {
    stdout.writeln('iOS EthiopiaPaySDK.framework not found. Skipped.');
    return;
  }

  final destination =
      Directory('${packageRoot.path}/ios/Frameworks/EthiopiaPaySDK.framework');
  if (destination.existsSync()) {
    destination.deleteSync(recursive: true);
  }
  destination.parent.createSync(recursive: true);
  _copyDirectory(framework, destination);
  stdout.writeln('Copied iOS EthiopiaPaySDK.framework.');
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

File? _findFirst(Directory root, String name) {
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && entity.uri.pathSegments.last == name) {
      return entity;
    }
  }
  return null;
}

Directory? _findFirstDirectory(Directory root, String name) {
  for (final entity in root.listSync(recursive: true)) {
    if (entity is Directory && entity.uri.pathSegments.last == name) {
      return entity;
    }
  }
  return null;
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync(recursive: false)) {
    final newPath = '${destination.path}/${entity.uri.pathSegments.last}';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(newPath));
    } else if (entity is File) {
      entity.copySync(newPath);
    }
  }
}

void _printUsage() {
  stdout.writeln('''
Telebirr setup helper

Run from your Flutter app root:

  dart run telebirr_inapp_purchase_plus:telebirr_setup \\
    --sdk-dir /path/to/TelebirrSDKFolder \\
    --return-scheme yourappscheme

The command:
- copies Telebirr Android AAR files into the package cache
- creates Android local Maven artifacts
- copies EthiopiaPaySDK.framework into the package cache
- changes Android MainActivity to FlutterFragmentActivity
- adds iOS telebirrcustomerApp and return URL scheme entries
''');
}

class _Options {
  final String? sdkDir;
  final String? returnScheme;
  final bool help;

  const _Options({
    required this.sdkDir,
    required this.returnScheme,
    required this.help,
  });

  factory _Options.parse(List<String> args) {
    String? sdkDir;
    String? returnScheme;
    var help = false;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg == '--sdk-dir' && index + 1 < args.length) {
        sdkDir = args[++index];
      } else if (arg.startsWith('--sdk-dir=')) {
        sdkDir = arg.substring('--sdk-dir='.length);
      } else if (arg == '--return-scheme' && index + 1 < args.length) {
        returnScheme = args[++index];
      } else if (arg.startsWith('--return-scheme=')) {
        returnScheme = arg.substring('--return-scheme='.length);
      }
    }

    return _Options(
      sdkDir: sdkDir,
      returnScheme: returnScheme,
      help: help,
    );
  }
}
