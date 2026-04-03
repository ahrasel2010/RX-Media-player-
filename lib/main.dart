import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/media_scanner_service.dart';

ValueNotifier<bool> isDark = ValueNotifier(true);

Future<void> requestPermissions() async {
  await [
    Permission.storage,
    Permission.audio,
    Permission.videos,
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Permission + Scan
  await requestPermissions();
  await MediaScannerService().scanDevice();

  runApp(const RXMediaPlayerApp());
}

class RXMediaPlayerApp extends StatelessWidget {
  const RXMediaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDark,
      builder: (context, value, _) {
        return MaterialApp(
          title: 'RX Player', // ✔ fixed name
          debugShowCheckedModeBanner: false,

          themeMode: value ? ThemeMode.dark : ThemeMode.light,

          theme: AppTheme.lightTheme, // ✔ light theme
          darkTheme: AppTheme.darkTheme, // ✔ dark theme

          home: const HomeScreen(),
        );
      },
    );
  }
}
