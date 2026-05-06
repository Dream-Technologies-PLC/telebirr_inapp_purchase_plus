import 'telebirr_setup.dart' as telebirr_setup;

Future<void> main(List<String> args) {
  return telebirr_setup.main(<String>['--doctor', ...args]);
}
