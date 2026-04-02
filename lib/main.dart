import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'features/premium/presentation/pages/subscription_page.dart';
import 'core/network/api_client.dart';
import 'core/network/token_storage.dart';
import 'navigation/app_router.dart';
import 'data/providers/auth_provider.dart';
import 'data/services/auth_service.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/onboarding/presentation/pages/onboarding_screen.dart';
import 'data/services/comment_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/artist_request_service.dart';
import 'data/services/video_service.dart';
import 'data/services/gift_service.dart';
import 'data/services/stripe_service.dart';
import 'data/services/music_service.dart';
import 'data/services/subscription_service.dart';
import 'data/services/mixer_service.dart';
import 'data/providers/audio_provider.dart';
import 'features/store/presentation/pages/store_page.dart';
import 'features/mixer/presentation/pages/mixer_page.dart';
import 'ui/widgets/mini_player.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';

final ValueNotifier<String> appStatus = ValueNotifier<String>("Initalizing...");

void main() async {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
  ));

  try {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.lugmatic.music.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
    
    // Initialize Stripe SDK (non-fatal — app still launches if this fails)
    try {
      appStatus.value = "Initializing Stripe...";
      await StripeService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      appStatus.value = "Stripe Error: $e";
    }
    
    appStatus.value = "Setting orientations...";
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Core dependencies
    appStatus.value = "Initializing storage...";
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    
    appStatus.value = "Setting up services...";
    final authService = AuthService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    final commentService = CommentService(apiClient: apiClient);
    final notificationService = NotificationService(apiClient: apiClient);
    final artistRequestService = ArtistRequestService(apiClient: apiClient);
    final videoService = VideoService(apiClient: apiClient);
    final giftService = GiftService(apiClient: apiClient);
    final stripeService = StripeService(giftService: giftService);
    final musicService = MusicService(apiClient: apiClient);
    final subscriptionService = SubscriptionService(apiClient: apiClient);
    final mixerService = MixerService(apiClient: apiClient);

    runApp(
      MultiProvider(
        providers: [
          Provider<TokenStorage>.value(value: tokenStorage),
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              authService: authService,
              tokenStorage: tokenStorage,
            ),
          ),
          Provider<CommentService>.value(value: commentService),
          Provider<NotificationService>.value(value: notificationService),
          Provider<ArtistRequestService>.value(value: artistRequestService),
          Provider<VideoService>.value(value: videoService),
          Provider<GiftService>.value(value: giftService),
          Provider<StripeService>.value(value: stripeService),
          Provider<MusicService>.value(value: musicService),
          Provider<SubscriptionService>.value(value: subscriptionService),
          Provider<MixerService>.value(value: mixerService),
          ChangeNotifierProvider(
            create: (_) => AudioProvider(musicService: musicService),
          ),
        ],
        child: const LugmaticApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('FATAL STARTUP ERROR: $e\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Fatal Error: $e', style: const TextStyle(color: Colors.red)),
        )),
      ),
    ));
  }
}


class LugmaticApp extends StatelessWidget {
  const LugmaticApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lugmatic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/store': (context) => const StorePage(),
        '/mixer': (context) => const MixerPage(),
        '/premium': (context) => const SubscriptionPage(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: MiniPlayer(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    
    // Auto-navigate after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  /// Check stored auth and navigate accordingly.
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      appStatus.value = "Checking authentication...";
      await authProvider.checkAuthStatus();
    } catch (e) {
      appStatus.value = "Auth check failed: $e";
    }

    if (!mounted) return;

    final Widget destination;
    if (authProvider.isAuthenticated) {
      destination = const HomePage();
    } else {
      destination = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/app_logo_transparent.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'LUGMATIC',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Music Universe',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Status
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: appStatus,
                      builder: (context, status, child) {
                        return Text(
                          status,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF10B981).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
