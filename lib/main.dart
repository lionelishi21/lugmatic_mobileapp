import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'features/premium/presentation/pages/subscription_page.dart';
import 'core/network/api_client.dart';
import 'core/network/token_storage.dart';
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
import 'data/providers/audio_provider.dart';
import 'features/store/presentation/pages/store_page.dart';
import 'features/mixer/presentation/pages/mixer_page.dart';
import 'ui/widgets/mini_player.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
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
              child: MiniPlayer(),
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

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/splash_video.mp4');
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint("Video splash error: $e");
      _checkAuthAndNavigate();
    }
  }

  void _videoListener() {
    if (_controller.value.position >= _controller.value.duration) {
      _controller.removeListener(_videoListener);
      _checkAuthAndNavigate();
    }
  }

  /// Check stored auth and navigate accordingly.
  Future<void> _checkAuthAndNavigate() async {
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
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Video Splash
                if (_isInitialized)
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                const SizedBox(height: 32),



                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Your Music Universe',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 40),

                // Debug Status text
                ValueListenableBuilder<String>(
                  valueListenable: appStatus,
                  builder: (context, status, child) {
                    return Text(
                      status,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Loading indicator
                if (!_isInitialized)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFA855F7).withOpacity(0.6),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
