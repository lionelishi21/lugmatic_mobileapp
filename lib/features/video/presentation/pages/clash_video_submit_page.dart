import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/video_service.dart';
import '../../../../data/services/regular_clash_service.dart';

class ClashVideoSubmitPage extends StatefulWidget {
  final XFile videoFile;
  final String clashId;

  const ClashVideoSubmitPage({Key? key, required this.videoFile, required this.clashId}) : super(key: key);

  @override
  State<ClashVideoSubmitPage> createState() => _ClashVideoSubmitPageState();
}

class _ClashVideoSubmitPageState extends State<ClashVideoSubmitPage> {
  late VideoPlayerController _videoController;
  bool _isSubmitting = false;

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

  Future<void> _submitToClash() async {
    setState(() => _isSubmitting = true);

    try {
      final videoService = context.read<VideoService>();
      final clashService = RegularClashService(apiClient: context.read());

      final file = File(widget.videoFile.path);
      final fileName = p.basename(file.path);
      const contentType = 'video/mp4';

      // 1. Get presigned URL and upload to S3
      final presignData = await videoService.getPresignedUrl(fileName, contentType);
      final uploadUrl = presignData['uploadUrl'] as String;
      final s3Key = presignData['key'] as String;
      await videoService.uploadToS3(uploadUrl, file, contentType);

      // 2. Derive the public video URL (strip query string from signed URL)
      final videoUrl = uploadUrl.split('?').first;
      final duration = _videoController.value.duration.inSeconds;

      // 3. Submit to clash endpoint
      await clashService.submitVideo(
        widget.clashId,
        videoUrl: videoUrl,
        videoKey: s3Key,
        duration: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video submitted to clash!'), backgroundColor: AppColors.primary),
        );
        // Pop back to the clashes screen
        Navigator.popUntil(context, (route) => route.settings.name == '/artist_home' || route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Submit to Clash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Video preview
          Expanded(
            child: _videoController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),

          // Info + submit button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'This 60-second clip will be submitted as your clash video. Your opponent\'s clip will play right after yours.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitToClash,
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit to Clash',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
