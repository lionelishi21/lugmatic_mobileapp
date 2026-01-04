import 'package:lugmatic_flutter/data/models/music_model.dart';
import 'package:lugmatic_flutter/data/models/artist_model.dart';
import 'package:lugmatic_flutter/data/models/podcast_model.dart';
import 'package:lugmatic_flutter/data/models/gift_model.dart';

class HomeService {
  // In a real app, these would be API calls
  static Future<List<MusicModel>> getTrendingSongs() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      MusicModel(
        id: '4',
        title: 'Under The Influence',
        artist: 'Chris Brown',
        album: 'Breezy',
        imageUrl: 'assets/images/onboarding_guy.png',
        audioUrl: 'https://example.com/audio4.mp3',
        duration: const Duration(minutes: 3, seconds: 4),
        genre: 'R&B',
        releaseDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MusicModel(
        id: '1',
        title: 'Midnight Dreams',
        artist: 'Luna Nova',
        album: 'Cosmic Vibes',
        imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        audioUrl: 'https://example.com/audio1.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        genre: 'Electronic',
        releaseDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      MusicModel(
        id: '2',
        title: 'Ocean Waves',
        artist: 'Marine Sounds',
        album: 'Nature Therapy',
        imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
        audioUrl: 'https://example.com/audio2.mp3',
        duration: const Duration(minutes: 4, seconds: 12),
        genre: 'Ambient',
        releaseDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MusicModel(
        id: '3',
        title: 'City Lights',
        artist: 'Urban Beats',
        album: 'Metropolitan',
        imageUrl: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400',
        audioUrl: 'https://example.com/audio3.mp3',
        duration: const Duration(minutes: 3, seconds: 28),
        genre: 'Hip-Hop',
        releaseDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Future<List<ArtistModel>> getFeaturedArtists() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      ArtistModel(
        id: '4',
        name: 'Chris Brown',
        imageUrl: 'assets/images/onboarding_guy.png',
        bio: 'Multi-platinum R&B and hip-hop artist, dancer, and actor',
        followers: 45000000,
        genres: ['R&B', 'Hip-Hop', 'Pop'],
        isVerified: true,
        location: 'Tappahannock, VA',
        totalSongs: 200,
        totalAlbums: 15,
        rating: 4.9,
      ),
      ArtistModel(
        id: '1',
        name: 'Luna Nova',
        imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
        bio: 'Electronic music producer creating cosmic soundscapes',
        followers: 125000,
        genres: ['Electronic', 'Ambient', 'Synthwave'],
        isVerified: true,
        location: 'Los Angeles, CA',
        totalSongs: 45,
        totalAlbums: 8,
        rating: 4.8,
      ),
      ArtistModel(
        id: '2',
        name: 'Marine Sounds',
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        bio: 'Nature-inspired ambient music for relaxation',
        followers: 89000,
        genres: ['Ambient', 'Nature', 'Meditation'],
        isVerified: true,
        location: 'Portland, OR',
        totalSongs: 32,
        totalAlbums: 6,
        rating: 4.9,
      ),
      ArtistModel(
        id: '3',
        name: 'Urban Beats',
        imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
        bio: 'Hip-hop artist bringing fresh urban vibes',
        followers: 156000,
        genres: ['Hip-Hop', 'Rap', 'Urban'],
        isVerified: true,
        location: 'New York, NY',
        totalSongs: 67,
        totalAlbums: 12,
        rating: 4.7,
      ),
    ];
  }

  static Future<List<PodcastModel>> getFeaturedPodcasts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      PodcastModel(
        id: '1',
        title: 'The Future of Music Technology',
        description: 'Exploring how AI and technology are reshaping the music industry',
        host: 'Tech Music Podcast',
        imageUrl: 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400',
        audioUrl: 'https://example.com/podcast1.mp3',
        duration: const Duration(minutes: 45, seconds: 30),
        category: 'Technology',
        publishDate: DateTime.now().subtract(const Duration(days: 2)),
        episodeNumber: 15,
        totalEpisodes: 50,
        seriesId: 'tech-music',
        seriesTitle: 'Tech Music Podcast',
      ),
      PodcastModel(
        id: '2',
        title: 'Artist Stories: Behind the Music',
        description: 'Intimate conversations with rising artists about their creative process',
        host: 'Music Stories',
        imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
        audioUrl: 'https://example.com/podcast2.mp3',
        duration: const Duration(minutes: 38, seconds: 15),
        category: 'Interviews',
        publishDate: DateTime.now().subtract(const Duration(days: 1)),
        episodeNumber: 23,
        totalEpisodes: 75,
        seriesId: 'artist-stories',
        seriesTitle: 'Artist Stories',
      ),
    ];
  }

  static Future<List<GiftModel>> getPopularGifts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      GiftModel(
        id: '1',
        name: 'Virtual Rose',
        description: 'Send a beautiful virtual rose to show your appreciation',
        imageUrl: 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=400',
        price: 2.99,
        category: 'Flowers',
        isPopular: true,
        artistId: '1',
        artistName: 'Luna Nova',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      GiftModel(
        id: '2',
        name: 'Golden Crown',
        description: 'Crown your favorite artist with this golden gift',
        imageUrl: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400',
        price: 9.99,
        category: 'Premium',
        isPopular: true,
        isLimited: true,
        artistId: '2',
        artistName: 'Marine Sounds',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      GiftModel(
        id: '3',
        name: 'Heart Emoji',
        description: 'Simple and sweet way to show love',
        imageUrl: 'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=400',
        price: 1.99,
        category: 'Emotions',
        artistId: '3',
        artistName: 'Urban Beats',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  static Future<void> likeMusic(String musicId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('Liked music: $musicId');
  }

  static Future<void> followArtist(String artistId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('Followed artist: $artistId');
  }

  static Future<void> purchaseGift(String giftId, String artistId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('Purchased gift: $giftId for artist: $artistId');
  }

  static Future<void> playMusic(String musicId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('Playing music: $musicId');
  }

  static Future<void> playPodcast(String podcastId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('Playing podcast: $podcastId');
  }
}

