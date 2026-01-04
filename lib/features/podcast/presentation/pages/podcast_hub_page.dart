import 'package:flutter/material.dart';
import 'package:lugmatic_flutter/features/podcast/presentation/pages/podcast_stream_page.dart';
import 'package:lugmatic_flutter/features/podcast/presentation/pages/podcast_discover_page.dart';

class PodcastHubPage extends StatefulWidget {
  const PodcastHubPage({Key? key}) : super(key: key);

  @override
  State<PodcastHubPage> createState() => _PodcastHubPageState();
}

class _PodcastHubPageState extends State<PodcastHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Podcasts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.live_tv, size: 24),
              text: 'Stream',
            ),
            Tab(
              icon: Icon(Icons.explore, size: 24),
              text: 'Discover',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PodcastStreamPage(),
          PodcastDiscoverPage(),
        ],
      ),
    );
  }
}
