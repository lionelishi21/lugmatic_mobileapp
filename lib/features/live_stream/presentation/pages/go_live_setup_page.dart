import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../data/services/live_stream_service.dart';
import 'live_host_screen.dart';

class GoLiveSetupPage extends StatefulWidget {
  const GoLiveSetupPage({Key? key}) : super(key: key);

  @override
  State<GoLiveSetupPage> createState() => _GoLiveSetupPageState();
}

class _GoLiveSetupPageState extends State<GoLiveSetupPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Music';
  bool _isLoading = false;

  final List<String> _categories = ['Music', 'Talk', 'Clash', 'DJ Set', 'Live Performance'];

  Future<void> _startLiveStream() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a stream title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final liveStreamService = LiveStreamService(apiClient: context.read<ApiClient>());
      
      // 1. Create the stream
      final stream = await liveStreamService.createStream(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      // 2. Start the stream
      await liveStreamService.startStream(stream.id);

      if (mounted) {
        // 3. Navigate to Host Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LiveHostScreen(streamId: stream.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start stream: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeumorphicTheme.backgroundColor,
            NeumorphicTheme.surfaceColor,
            NeumorphicTheme.backgroundColor,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Go Live Setup', 
            style: TextStyle(color: NeumorphicTheme.textPrimary, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: NeumorphicTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stream Title',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              NeumorphicContainer(
                isConcave: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(15),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: NeumorphicTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'What is your stream about?',
                    hintStyle: TextStyle(color: NeumorphicTheme.textTertiary.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Category',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              NeumorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                borderRadius: BorderRadius.circular(15),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: NeumorphicTheme.surfaceColor,
                    style: const TextStyle(color: NeumorphicTheme.textPrimary, fontSize: 16),
                    icon: const Icon(Icons.keyboard_arrow_down, color: NeumorphicTheme.primaryAccent),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCategory = newValue);
                      }
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              NeumorphicContainer(
                isConcave: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(15),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: NeumorphicTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tell your fans more...',
                    hintStyle: TextStyle(color: NeumorphicTheme.textTertiary.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  height: 60,
                  borderRadius: BorderRadius.circular(30),
                  isGradient: true,
                  gradientColors: [
                    NeumorphicTheme.accentGradientStart,
                    NeumorphicTheme.accentGradientEnd,
                  ],
                  onPressed: _isLoading ? null : _startLiveStream,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'GO LIVE NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'By going live, you agree to our Content Guidelines.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: NeumorphicTheme.textTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
