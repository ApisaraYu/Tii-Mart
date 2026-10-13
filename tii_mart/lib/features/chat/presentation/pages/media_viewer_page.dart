import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ดูรูปเต็มจอ (ซูมได้)
class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const CircularProgressIndicator(color: Colors.white),
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

/// เล่นวิดีโอเต็มจอ
class VideoViewerPage extends StatefulWidget {
  const VideoViewerPage({super.key, required this.url});

  final String url;

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
    _controller.addListener(() {
      if (mounted) setState(() {}); // อัพเดตปุ่ม play/pause และแถบเวลา
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _failed
            ? const Text(
                'เล่นวิดีโอไม่ได้',
                style: TextStyle(color: Colors.white70),
              )
            : !_ready
                ? const CircularProgressIndicator(color: Colors.white)
                 : Column(
                    children: [
                      // Expanded: วิดีโอแนวตั้งสูงมาก ต้องย่อให้พอดีพื้นที่ที่เหลือ
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: GestureDetector(
                              onTap: () => _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play(),
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                      ),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.all(16),
                      ),
                      SafeArea(
                        top: false,
                        child: IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                          onPressed: () => _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play(),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
