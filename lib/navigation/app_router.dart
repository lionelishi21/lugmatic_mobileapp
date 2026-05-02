import 'package:flutter/material.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/artist_detail_page.dart';
import '../features/home/presentation/pages/album_detail_page.dart';
import '../features/home/presentation/pages/create_playlist_screen.dart';
import '../features/song/presentation/pages/song_detail_page.dart';
import '../features/store/presentation/pages/store_page.dart';
import '../features/mixer/presentation/pages/mixer_page.dart';
import '../features/music/presentation/pages/new_releases_page.dart';
import '../features/music/presentation/pages/trending_songs_page.dart';
import '../features/live_stream/presentation/pages/tiktok_live_page.dart';
import '../features/live_stream/presentation/pages/clash_details_page.dart';
import '../features/live_stream/presentation/pages/go_live_setup_page.dart';
import '../features/live_stream/presentation/pages/live_host_screen.dart';
import '../features/home/presentation/pages/artist_dashboard_page.dart';
import '../features/home/presentation/pages/admin_dashboard_page.dart';
import '../features/legal/presentation/pages/privacy_policy_page.dart';
import '../features/legal/presentation/pages/terms_of_service_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());

      case '/privacy':
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());

      case '/terms':
        return MaterialPageRoute(builder: (_) => const TermsOfServicePage());

      case '/song':
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute(
            builder: (_) => SongDetailPage(
              songId: args['id'] as String,
              initialData: args['initialData'],
            ),
          );
        }
        if (args is String) {
          return MaterialPageRoute(builder: (_) => SongDetailPage(songId: args));
        }
        return _notFound();

      case '/artist':
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute(
            builder: (_) => ArtistDetailPage(
              artistId: args['id'] as String,
              initialData: args['initialData'],
            ),
          );
        }
        if (args is String) {
          return MaterialPageRoute(builder: (_) => ArtistDetailPage(artistId: args));
        }
        return _notFound();

      case '/album':
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute(
            builder: (_) => AlbumDetailPage(
              albumId: args['id'] as String,
              initialData: args['initialData'],
            ),
          );
        }
        if (args is String) {
          return MaterialPageRoute(builder: (_) => AlbumDetailPage(albumId: args));
        }
        return _notFound();

      case '/create_playlist':
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const CreatePlaylistScreen(),
        );

      case '/store':
        return MaterialPageRoute(builder: (_) => const StorePage());

      case '/new_releases':
        return MaterialPageRoute(builder: (_) => const NewReleasesPage());

      case '/trending':
        return MaterialPageRoute(builder: (_) => const TrendingSongsPage());

      case '/mixer':
        return MaterialPageRoute(builder: (_) => const MixerPage());

      case '/live':
        return MaterialPageRoute(builder: (_) => const TikTokLivePage());

      case '/clash':
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute(
            builder: (_) => ClashDetailsPage(
              clashId: args['id'] as String,
              initialData: args['initialData'],
            ),
          );
        }
        if (args is String) {
          return MaterialPageRoute(builder: (_) => ClashDetailsPage(clashId: args));
        }
        return _notFound();

      case '/go_live':
        return MaterialPageRoute(builder: (_) => const GoLiveSetupPage());

      case '/live_host':
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(builder: (_) => LiveHostScreen(streamId: args));
        }
        if (args is Map && args.containsKey('id')) {
          return MaterialPageRoute(builder: (_) => LiveHostScreen(streamId: args['id'] as String));
        }
        return _notFound();

      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());

      case '/artist_dashboard':
        return MaterialPageRoute(builder: (_) => const ArtistDashboardPage());

      default:
        return _notFound();
    }
  }

  static MaterialPageRoute _notFound() => MaterialPageRoute(
    builder: (_) => const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Text('Page not found', style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
