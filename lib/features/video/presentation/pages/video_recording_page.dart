import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'video_publish_page.dart';
import 'clash_video_submit_page.dart';

class VideoRecordingPage extends StatefulWidget {
  /// If set, recording is locked to 6 seconds and the video is submitted to this clash.
  final String? clashId;

  const VideoRecordingPage({Key? key, this.clashId}) : super(key: key);

  bool get isClashMode => clashId != null;

  @override
  State<VideoRecordingPage> createState() => _VideoRecordingPageState();
}

class _VideoRecordingPageState extends State<VideoRecordingPage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _timer;

  int get _maxSeconds => 60;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _onNewCameraSelected(_cameras.first);
    }
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint('Camera error: $e');
    }

    if (mounted) setState(() {});
  }

  void _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordSeconds++;
        });
        if (_recordSeconds >= _maxSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Record error: $e');
    }
  }

  void _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    _timer?.cancel();
    try {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        if (widget.isClashMode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClashVideoSubmitPage(videoFile: file, clashId: widget.clashId!),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPublishPage(videoFile: file),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Stop record error: $e');
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    final lens = _controller!.description.lensDirection;
    final newCamera = _cameras.firstWhere(
      (c) => c.lensDirection != lens,
      orElse: () => _cameras.first,
    );
    _onNewCameraSelected(newCamera);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF86E560))),
      );
    }

    final pct = _isRecording ? _recordSeconds / _maxSeconds : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Clash mode badge
          if (widget.isClashMode)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF86E560).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF86E560).withOpacity(0.5)),
                  ),
                  child: const Text(
                    '⚡ Clash Mode — 60s max',
                    style: TextStyle(color: Color(0xFF86E560), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),

          // Top Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '00:${_recordSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                    onPressed: _isRecording ? null : _toggleCamera,
                  ),
                ],
              ),
            ),
          ),

          // Progress bar (clash mode)
          if (widget.isClashMode && _isRecording)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white24,
                color: const Color(0xFF86E560),
                minHeight: 3,
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: _isRecording ? 40 : 64,
                      height: _isRecording ? 40 : 64,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(_isRecording ? 8 : 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
