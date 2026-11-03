import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // Capture the device framebuffer while the test waits at each evidence state.
  // This preserves system UI and the fixed AppBar after scrolling.
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 18766);
  server.listen((request) async {
    final name = request.uri.pathSegments.firstOrNull ?? '';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(name)) {
      request.response.statusCode = 400;
    } else {
      final capture = await Process.run('adb', [
        '-s',
        'emulator-5554',
        'exec-out',
        'screencap',
        '-p',
      ], stdoutEncoding: null);
      if (capture.exitCode != 0) {
        request.response.statusCode = 500;
      } else {
        await Directory('outputs/ui-preview').create(recursive: true);
        await File('outputs/ui-preview/$name.png')
            .writeAsBytes(capture.stdout as List<int>);
        request.response.write('captured');
      }
    }
    await request.response.close();
  });
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final directory = Directory('outputs/ui-preview');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
