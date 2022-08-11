import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay(
      {Key key, @required this.controller, this.canShowPlayback})
      : super(key: key);

  static const _examplePlaybackRates = [0.5, 1.0, 1.5, 2.0, 3.0];

  final VideoPlayerController controller;
  final bool canShowPlayback;

  @override
  Widget build(BuildContext context) {
    bool shouldShowSpeed = canShowPlayback ?? true;
    IconData childIcon = Icons.play_arrow;
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: Container(
            color: Colors.black26,
            child: Center(
                child: Icon(childIcon, color: Colors.white, size: 60.0)
                // controller.value.isPlaying
                //     ? const Icon(Icons.play_arrow,
                //         color: Colors.white, size: 60.0)
                //     : const Icon(Icons.pause, color: Colors.white, size: 60.0),
                ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              childIcon = Icons.play_arrow;
              controller.pause();
            } else {
              childIcon = Icons.pause;
              controller.play();
            }
          },
        ),
        shouldShowSpeed
            ? Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<double>(
                  initialValue: controller.value.playbackSpeed,
                  tooltip: 'Playback speed',
                  onSelected: (speed) {
                    controller.setPlaybackSpeed(speed);
                  },
                  itemBuilder: (context) {
                    return [
                      for (final speed in _examplePlaybackRates)
                        PopupMenuItem(
                          value: speed,
                          child: Text('${speed}x'),
                        )
                    ];
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      // Using less vertical padding as the text is also longer
                      // horizontally, so it feels like it would need more spacing
                      // horizontally (matching the aspect ratio of the video).
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Text(
                      '${controller.value.playbackSpeed}x',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
