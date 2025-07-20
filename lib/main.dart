import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_page.dart';
import 'providers/auth_provider.dart';
import 'config/supabase_config.dart';
import 'package:google_fonts/google_fonts.dart';
// dotenv import 제거
import 'lobby_screen.dart';
import 'screens/shop_page.dart';
import 'screens/legal/privacy_policy_page.dart';
import 'screens/legal/terms_of_service_page.dart';
import 'screens/apple_grade_splash_screen.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // dotenv.load() 제거
  
  // 가로 모드 강제 설정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // 전체 화면 모드 (선택사항)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // GlobalKey 중복 오류 로그 숨기기
  FlutterError.onError = (FlutterErrorDetails details) {
    // GlobalKey 중복 오류는 무시
    if (details.exception.toString().contains('Multiple widgets used the same GlobalKey')) {
      return;
    }
    // 다른 오류는 정상적으로 처리
    FlutterError.presentError(details);
  };
  
  // 디버그 모드에서만 특정 로그 숨기기
  if (kDebugMode) {
    // GlobalKey 관련 로그 숨기기
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('Multiple widgets used the same GlobalKey')) {
        return;
      }
      // 다른 로그는 정상 출력
      print(message);
    };
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const GoStopApp(),
    ),
  );
}

class GoStopApp extends StatelessWidget {
  const GoStopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: '고스톱 MVP',
          theme: ThemeData(
            primarySwatch: Colors.red,
            useMaterial3: true,
            textTheme: GoogleFonts.notoSansTextTheme().copyWith(
              titleLarge: GoogleFonts.workSans(fontWeight: FontWeight.bold),
              labelLarge: GoogleFonts.notoSans(fontWeight: FontWeight.w600, letterSpacing: 0.6),
            ),
          ),
          locale: localeProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthWrapper(),
          routes: {
            // 로그인 라우트 비활성화
            // '/login': (context) => const LoginPage(),
            '/home': (context) => const LobbyScreen(),
            '/lobby': (context) => const LobbyScreen(),
            '/shop': (context) => const ShopPage(),
            '/privacy': (context) => const PrivacyPolicyPage(),
            '/terms': (context) => const TermsOfServicePage(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 스플래시 스크린 비활성화 - 바로 로비로 이동
        return const LobbyScreen();
      },
    );
  }
}

