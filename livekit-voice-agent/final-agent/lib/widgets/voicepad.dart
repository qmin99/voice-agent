import 'package:flutter/material.dart';

class HiddenVoicePad extends StatefulWidget {
  const HiddenVoicePad({super.key});

  @override
  State<HiddenVoicePad> createState() => _HiddenVoicePadState();
}

class _HiddenVoicePadState extends State<HiddenVoicePad> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isHovered = false;
  bool _isCancelHovered = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _blinkAnimation = ColorTween(
      begin: const Color(0xFFF1F5F9).withOpacity(0.7),
      end: const Color(0xFFF1F5F9).withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    _animationController.repeat(reverse: true);
    // TODO: Implement actual recording functionality
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _animationController.stop();
    _animationController.reset();
    // TODO: Implement stop recording and send
  }

  void _cancelRecording() {
    setState(() {
      _isRecording = false;
    });
    _animationController.stop();
    _animationController.reset();
    // TODO: Implement cancel recording
  }

  void _handleTap() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isRecording 
                    ? (_blinkAnimation.value ?? const Color(0xFFF1F5F9).withOpacity(0.7))
                    : _isHovered 
                      ? const Color(0xFFF8FAFC) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isRecording 
                      ? const Color.fromARGB(74, 11, 56, 41).withOpacity(0.2)
                      : const Color(0xFFE2E8F0).withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: _isRecording 
                  ? _buildRecordingState()
                  : _buildIdleState(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return const SizedBox();
  }

  Widget _buildRecordingState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, right: 16),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isCancelHovered = true),
            onExit: (_) => setState(() => _isCancelHovered = false),
            child: GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isCancelHovered 
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _isCancelHovered 
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF64748b).withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}