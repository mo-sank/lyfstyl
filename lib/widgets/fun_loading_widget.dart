import 'package:flutter/material.dart';
import 'dart:math';

class FunLoadingWidget extends StatefulWidget {
  final String? customMessage;
  final List<String>? messages;
  final Color? color;

  const FunLoadingWidget({
    super.key,
    this.customMessage,
    this.messages,
    this.color,
  });

  // Predefined message sets for different contexts
  static const List<String> bookMessages = [
    '📚 Turning pages to find the best reads...',
    '✨ Discovering your next favorite story...',
    '📖 Scanning the literary universe...',
    '🔍 Hunting down bestsellers...',
    '💫 Curating the perfect book list...',
    '📕 Gathering the hottest titles...',
  ];

  static const List<String> musicMessages = [
    '🎵 Tuning into the hottest tracks...',
    '🎸 Finding those earworms for you...',
    '🎧 Spinning up the best playlists...',
    '🎤 Searching for chart-toppers...',
    '🎹 Composing the perfect mix...',
    '🎶 Vibing with the latest hits...',
  ];

  static const List<String> movieMessages = [
    '🎬 Rolling out the red carpet...',
    '🍿 Finding blockbusters for you...',
    '🎥 Scanning the cinema universe...',
    '⭐ Discovering award-winners...',
    '🎞️ Curating the best flicks...',
    '🌟 Hunting down must-watch films...',
  ];

  static const List<String> searchMessages = [
    '🔍 Searching high and low...',
    '🚀 Launching search mission...',
    '💫 Finding exactly what you want...',
    '✨ Scanning the database...',
    '🎯 Targeting your perfect match...',
    '🔎 Digging through the archives...',
  ];

  static const List<String> genericMessages = [
    '⏳ Loading awesome content...',
    '✨ Making magic happen...',
    '🚀 Getting things ready...',
    '💫 Almost there...',
    '⚡ Powering up...',
    '🌟 Preparing something special...',
  ];

  @override
  State<FunLoadingWidget> createState() => _FunLoadingWidgetState();
}

class _FunLoadingWidgetState extends State<FunLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _currentMessage;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Set up rotation animation for the progress indicator
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Pick a random message to display
    _currentMessage = _getRandomMessage();
  }

  String _getRandomMessage() {
    List<String> messageList;

    if (widget.customMessage != null) {
      return widget.customMessage!;
    } else if (widget.messages != null && widget.messages!.isNotEmpty) {
      messageList = widget.messages!;
    } else {
      messageList = FunLoadingWidget.genericMessages;
    }

    return messageList[_random.nextInt(messageList.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated circular progress indicator
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    effectiveColor.withOpacity(0.2),
                    effectiveColor,
                    effectiveColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: effectiveColor,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Progress bar
          Container(
            width: 250,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Fun message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Pulsing dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final value = (_controller.value + delay) % 1.0;
                  final opacity = (sin(value * pi * 2) + 1) / 2;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveColor.withOpacity(opacity * 0.7 + 0.3),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
