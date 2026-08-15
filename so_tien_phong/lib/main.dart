import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/root_screen.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi', null);
  Intl.defaultLocale = 'vi';

  // Không chặn màn hình khởi động chỉ vì thông báo.
  NotificationService.instance.init();

  runApp(const SoTienPhongApp());
}

class SoTienPhongApp extends StatelessWidget {
  const SoTienPhongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState()..load(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'Sổ tiền phòng',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: const Locale('vi', 'VN'),
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
