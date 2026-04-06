import 'package:flutter/material.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/artist_detail_page.dart';
import '../features/home/presentation/pages/album_detail_page.dart';
import '../features/home/presentation/pages/create_playlist_screen.dart';
import '../features/song/presentation/pages/song_detail_page.dart';
import '../features/store/presentation/pages/store_page.dart';
import '../features/mixer/presentation/pages/mixer_page.dart';
import '../features/live_stream/presentation/pages/tiktok_live_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());

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

      case '/mixer':
        return MaterialPageRoute(builder: (_) => const MixerPage());

      case '/live':
        return MaterialPageRoute(builder: (_) => const TikTokLivePage());

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
