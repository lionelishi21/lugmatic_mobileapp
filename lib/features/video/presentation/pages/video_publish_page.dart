import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../data/services/video_service.dart';
import '../../../../data/providers/auth_provider.dart';
import 'package:path/path.dart' as p;

class VideoPublishPage extends StatefulWidget {
  final XFile videoFile;
  const VideoPublishPage({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<VideoPublishPage> createState() => _VideoPublishPageState();
}

class _VideoPublishPageState extends State<VideoPublishPage> {
  late VideoPlayerController _videoController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoFile.path))
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
      });
  }

  Future<void> _handlePost() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final videoService = context.read<VideoService>();
      final authProvider = context.read<AuthProvider>();
      final artistId = authProvider.user?.artistId;

      if (artistId == null) throw Exception("Artist profile not found");

      final file = File(widget.videoFile.path);
      final fileName = p.basename(file.path);
      const contentType = 'video/mp4';

      // 1. Get presigned URL
      final presignData = await videoService.getPresignedUrl(fileName, contentType);
      final uploadUrl = presignData['uploadUrl'];
      final s3Key = presignData['key'];

      // 2. Upload to S3
      await videoService.uploadToS3(uploadUrl, file, contentType);

      // 3. Create database record
      await videoService.createVideoRecord(
        title: title,
        description: _descController.text.trim(),
        videoUrl: s3Key,
        thumbnailUrl: '', // For now, we don't have thumbnail generation
        artistId: artistId,
      );

      if (mounted) {
        // Return to dashboard and show success
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video posted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post video: $e')));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Post Video'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Preview
            if (_videoController.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              )
            else
              const AspectRatio(
                aspectRatio: 9 / 16,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handlePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Post Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
