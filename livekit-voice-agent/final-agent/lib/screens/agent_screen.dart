import 'dart:ui';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:voice_assistant/widgets/settings_modal.dart';
import 'package:voice_assistant/widgets/voicepad.dart';
import '../controllers/app_ctrl.dart' as app_ctrl;

// Advanced AttachedFile model
class AttachedFile {
  final String id;
  final String name;
  final FileType type;
  final String size;
  final Uint8List data;
  final String? prompt;
  final bool isExpanded;
  final String? originalPrompt;

  AttachedFile({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.data,
    this.prompt,
    this.isExpanded = false,
    this.originalPrompt,
  });

  AttachedFile copyWith({
    String? id,
    String? name,
    FileType? type,
    String? size,
    Uint8List? data,
    String? prompt,
    bool? isExpanded,
    String? originalPrompt,
  }) {
    return AttachedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      data: data ?? this.data,
      prompt: prompt ?? this.prompt,
      isExpanded: isExpanded ?? this.isExpanded,
      originalPrompt: originalPrompt ?? this.originalPrompt,
    );
  }
}

// Model for storing chat sessions
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });
}

class ChatMessage {
  final String text;
  final bool isLocal;
  final DateTime timestamp;
  final List<AttachedFile>? attachedFiles;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isLocal,
    required this.timestamp,
    this.attachedFiles,
    this.isTyping = false,
  });
}

enum AppView { welcome, chat }

class LegalChatInterface extends StatefulWidget {
  const LegalChatInterface({super.key});

  @override
  State<LegalChatInterface> createState() => _LegalChatInterfaceState();
}

class _LegalChatInterfaceState extends State<LegalChatInterface> {
  final _scrollController = ScrollController();
  AppView _currentView = AppView.welcome;
  List<ChatSession> _chatHistory = [];
  ChatSession? _currentChatSession;
  bool _shouldShowInitialLoading = true;
  bool _hasAgentSpoken = false;
  bool _isProcessingAI = false;

  // Advanced file attachment state
  List<AttachedFile> attachedFiles = [];
  Map<String, TextEditingController> filePromptControllers = {};
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Add a listener to automatically scroll to the bottom on new messages
    context
        .read<app_ctrl.AppCtrl>()
        .roomContext
        .addListener(_onRoomContextChanged);

    // Add listener for transcriptions to detect when agent speaks
    context
        .read<app_ctrl.AppCtrl>()
        .roomContext
        .addListener(_onTranscriptionChanged);

    _initializeChatHistory();
  }

  @override
  void dispose() {
    context
        .read<app_ctrl.AppCtrl>()
        .roomContext
        .removeListener(_onRoomContextChanged);
    context
        .read<app_ctrl.AppCtrl>()
        .roomContext
        .removeListener(_onTranscriptionChanged);
    _scrollController.dispose();

    // Dispose file prompt controllers
    for (var controller in filePromptControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Add this method to detect agent speech
  void _onTranscriptionChanged() {
    final transcriptions =
        context.read<app_ctrl.AppCtrl>().roomContext.transcriptions;

    // Check if any transcription is from a remote participant (the agent)
    for (final transcription in transcriptions) {
      if (transcription.participant is! lk.LocalParticipant &&
          transcription.segment.text.trim().isNotEmpty) {
        if (!_hasAgentSpoken && _shouldShowInitialLoading) {
          setState(() {
            _hasAgentSpoken = true;
            _shouldShowInitialLoading = false;
          });
        }
        break;
      }
    }
  }

  void _initializeChatHistory() {
    // Initialize with sample chat history
    _chatHistory = [
      ChatSession(
        id: '1',
        title: 'Voice mode activated! I\'ll...',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        messages: [
          ChatMessage(
              text: 'Hello, can you help me with a contract review?',
              isLocal: true,
              timestamp: DateTime.now().subtract(const Duration(days: 1))),
          ChatMessage(
              text:
                  'Of course! I\'d be happy to help you with contract review. Please share the contract details and let me know what specific areas you\'d like me to focus on.',
              isLocal: false,
              timestamp: DateTime.now().subtract(const Duration(days: 1))),
        ],
      ),
      ChatSession(
        id: '2',
        title: 'Contract Review Discussion',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        messages: [
          ChatMessage(
              text: 'I need help understanding liability clauses.',
              isLocal: true,
              timestamp: DateTime.now().subtract(const Duration(days: 2))),
          ChatMessage(
              text:
                  'Liability clauses are crucial provisions that determine who bears responsibility for damages or losses. Let me explain the key types...',
              isLocal: false,
              timestamp: DateTime.now().subtract(const Duration(days: 2))),
        ],
      ),
      ChatSession(
        id: '3',
        title: 'Legal Document Analysis',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        messages: [],
      ),
      ChatSession(
        id: '4',
        title: 'Estate Planning Consultation',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        messages: [],
      ),
    ];
  }

  void _onRoomContextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // AI response loading icon for chat bubbles (from first file)
  Widget _buildLoadingIcon() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0, end: 1),
      onEnd: () {
        if (mounted && _isProcessingAI) {
          _safeSetState(() {});
        }
      },
      builder: (context, double value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: value * 2 * math.pi,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      const Color(0xFF153F1E).withOpacity(0.1),
                      const Color(0xFF153F1E).withOpacity(0.8),
                      const Color(0xFF153F1E),
                      const Color(0xFF153F1E).withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.4 + (math.sin(value * 4 * math.pi) * 0.2),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF153F1E),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // AI response typing indicator for chat bubbles (from first file)
  Widget _buildTypingIndicator() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0, end: 1),
      onEnd: () {
        if (mounted && _isProcessingAI) {
          _safeSetState(() {});
        }
      },
      builder: (context, double value, child) {
        List<Widget> dots = [];
        for (int i = 0; i < 3; i++) {
          double delay = i * 0.2;
          double animationValue = (value + delay) % 1.0;
          double yOffset = math.sin(animationValue * 2 * math.pi) * 3;
          double opacity = 0.3 +
              (math.sin(animationValue * 2 * math.pi + math.pi / 2) + 1) * 0.35;

          dots.add(
            Transform.translate(
              offset: Offset(0, yOffset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF153F1E).withOpacity(opacity),
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Processing your request',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748b),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: dots,
            ),
          ],
        );
      },
    );
  }

  // ORIGINAL loading screen overlay - NOT CHANGED
  Widget _buildVoiceAgentLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated HAAKEEM Logo
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 2000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color.fromARGB(114, 23, 81, 39),
                              const Color.fromARGB(110, 118, 132, 120),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF153f1e).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing ring
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, pulseValue, child) {
                                return Container(
                                  width: 80 + (20 * pulseValue),
                                  height: 80 + (20 * pulseValue),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        20 + (10 * pulseValue)),
                                    border: Border.all(
                                      color: const Color(0xFF153f1e)
                                          .withOpacity(
                                              0.3 - (0.3 * pulseValue)),
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                              onEnd: () {
                                // This will restart the animation
                              },
                            ),
                            // Icon
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Lottie.asset(
                                'robot_lottie.json',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                repeat: true,
                                animate: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Loading title with typing effect
                TweenAnimationBuilder<int>(
                  duration: const Duration(milliseconds: 1200),
                  tween: IntTween(begin: 0, end: "Initializing Hakeem".length),
                  builder: (context, value, child) {
                    return Text(
                      "Initializing Haakeem".substring(0, value),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1e293b),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Animated dots loading indicator
                Consumer<app_ctrl.AppCtrl>(
                  builder: (context, appCtrl, child) {
                    String statusText;
                    switch (appCtrl.connectionState) {
                      case app_ctrl.ConnectionState.connecting:
                        statusText = "Connecting to voice assistant";
                        break;
                      case app_ctrl.ConnectionState.connected:
                        statusText = "Preparing voice interface";
                        break;
                      default:
                        statusText = "Starting up";
                    }

                    return Column(
                      children: [
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748b),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // UPDATED: Floating loading dots
                        _FloatingLoadingDots(),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Progress indicator
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Consumer<app_ctrl.AppCtrl>(
                    builder: (context, appCtrl, child) {
                      double progress = 0.3; // Default progress
                      if (appCtrl.connectionState ==
                          app_ctrl.ConnectionState.connecting) {
                        progress = 0.7;
                      } else if (appCtrl.connectionState ==
                          app_ctrl.ConnectionState.connected) {
                        progress = 1.0;
                      }

                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: progress),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Container(
                            width: 200 * value,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF153f1e),
                                  Color(0xFF1e5e29),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startNewChat() {
    setState(() {
      _currentView = AppView.chat;
      _shouldShowInitialLoading = true;
      _hasAgentSpoken = false;
      _currentChatSession = null;
    });

    context.read<app_ctrl.AppCtrl>().connect();

    // Keep the fallback timer
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_hasAgentSpoken) {
        setState(() {
          _shouldShowInitialLoading = false;
        });
      }
    });
  }

  void _endCurrentChat() {
    // Disconnect from current session
    context.read<app_ctrl.AppCtrl>().disconnect();

    setState(() {
      _currentView = AppView.welcome;
      _currentChatSession = null;
      _hasAgentSpoken = false;
      _shouldShowInitialLoading = true;
    });
  }

  void _loadChatSession(ChatSession session) {
    setState(() {
      _currentView = AppView.chat;
      _currentChatSession = session;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
        ),
        child: Row(
          children: [
            // Left Sidebar
            _buildSidebar(),

            // Main Area - Either Welcome Screen or Chat Interface
            Expanded(
              child: _currentView == AppView.welcome
                  ? _buildWelcomeScreen()
                  : _buildChatInterface(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF153f1e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Legal Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
          ),

          // New Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startNewChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF153f1e),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'New chat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Documents Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: Color(0xFF64748b),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Documents',
                    style: TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chat History Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Color(0xFF64748b),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chat History List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chatSession = _chatHistory[index];
                final isActive = _currentChatSession?.id == chatSession.id &&
                    _currentView == AppView.chat;
                return _buildChatHistoryItem(
                  chatSession.title,
                  isActive,
                  () => _loadChatSession(chatSession),
                );
              },
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            height: 1,
            width: double.infinity,
            color: const Color(0xFFE2E8F0),
          ),

          // Hidden Voice Pad
          const HiddenVoicePad(),

          // Settings Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isHovering = false;
                return MouseRegion(
                  onEnter: (_) => setState(() => isHovering = true),
                  onExit: (_) => setState(() => isHovering = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      showSettingsModal(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? const Color(0xFF153f1e).withOpacity(0.08)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHovering
                              ? const Color(0xFF153f1e).withOpacity(0.3)
                              : const Color(0xFFE2E8F0),
                          width: isHovering ? 1.5 : 1,
                        ),
                        boxShadow: isHovering
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF153f1e).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            color: isHovering
                                ? const Color(0xFF153f1e)
                                : const Color(0xFF64748b),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Settings',
                            style: TextStyle(
                              color: isHovering
                                  ? const Color(0xFF153f1e)
                                  : const Color(0xFF64748b),
                              fontSize: 14,
                              fontWeight: isHovering
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI Icon with Modern Styling
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF153f1e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color(0xFF153f1e).withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF153f1e),
                  size: 40,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'AI Legal Assistant Ready',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: const Text(
                  '✨ Your intelligent legal companion awaits',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF64748b),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Mode Selection Container
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // Voice Mode Button - Primary
                    Container(
                      width: double.infinity,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF153f1e),
                            Color(0xFF1e5e29),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF153f1e).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _startNewChat,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Voice Mode',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Speak naturally with your AI assistant',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFFB8E6C1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Chat Mode Button - Secondary
                    Container(
                      width: double.infinity,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentView = AppView.chat;
                              _currentChatSession = null;
                            });
                            // Navigate to chat without connecting voice
                            context.read<app_ctrl.AppCtrl>().navigateToAgent();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF153f1e)
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Color(0xFF153f1e),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Chat Mode',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Type your questions and get instant answers',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: const Color(0xFF9CA3AF),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Features Section - Modern Card Layout
              Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ModernFeatureCard(
                            icon: Icons.security,
                            title: 'Secure & Confidential',
                            description: 'End-to-end encrypted conversations',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _ModernFeatureCard(
                            icon: Icons.speed,
                            title: 'Instant Guidance',
                            description: 'Get immediate legal insights',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ModernFeatureCard(
                            icon: Icons.verified_user,
                            title: 'Expert Knowledge',
                            description: 'Powered by legal databases',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _ModernFeatureCard(
                            icon: Icons.language,
                            title: 'Multi-Modal',
                            description: 'Voice and text interactions',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Stack(
      children: [
        Column(
          children: [
            // Chat Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentChatSession?.title ?? 'HAAKEEM Assistant',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Attorney agent active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Connection Status
                  Consumer<app_ctrl.AppCtrl>(
                    builder: (context, appCtrl, child) {
                      final isConnected = appCtrl.connectionState ==
                          app_ctrl.ConnectionState.connected;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: isConnected
                                  ? const Color(0xFF10B981)
                                  : Colors.orange,
                              size: 8,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isConnected ? 'Connected' : 'Connecting...',
                              style: TextStyle(
                                fontSize: 12,
                                color: isConnected
                                    ? const Color(0xFF10B981)
                                    : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Beginner Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // End Chat Button
                  TextButton.icon(
                    onPressed: _endCurrentChat,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    label: const Text(
                      'End Chat',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => context
                      .read<app_ctrl.AppCtrl>()
                      .messageFocusNode
                      .unfocus(),
                  child: _currentChatSession != null &&
                          _currentChatSession!.messages.isNotEmpty
                      ? _buildHistoricalMessages()
                      : _buildLiveTranscription(),
                ),
              ),
            ),

            // Input Area with Advanced Attachments
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Attachment Preview
                  _buildAttachmentPreview(),

                  // Text Input with Attach, Mic, and Send buttons
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Attach File Button
                        Container(
                          margin: const EdgeInsets.all(4),
                          child: Material(
                            color: Colors.transparent,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                onTap: _isUploading ? null : _scanDocuments,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Color(0xFF64748b),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.attach_file_rounded,
                                          color: Color(0xFF64748b),
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Text Input
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40),
                            child: Consumer<app_ctrl.AppCtrl>(
                              builder: (context, appCtrl, child) => TextField(
                                controller: appCtrl.messageCtrl,
                                focusNode: appCtrl.messageFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Hello. How are you?',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.send,
                                onTapOutside: (event) {
                                  appCtrl.messageFocusNode.unfocus();
                                },
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty ||
                                      attachedFiles.isNotEmpty) {
                                    _sendMessage(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        // Voice Input Button
                        Container(
                          margin: const EdgeInsets.all(4),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: IconButton(
                              onPressed: () {
                                context
                                    .read<app_ctrl.AppCtrl>()
                                    .toggleAgentScreenMode();
                              },
                              icon: const Icon(
                                Icons.mic_outlined,
                                color: Color(0xFF64748b),
                              ),
                            ),
                          ),
                        ),

                        // Send Button
                        Consumer<app_ctrl.AppCtrl>(
                          builder: (context, appCtrl, child) => MouseRegion(
                            cursor: (appCtrl.isSendButtonEnabled ||
                                    attachedFiles.isNotEmpty)
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.forbidden,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: (appCtrl.isSendButtonEnabled ||
                                        attachedFiles.isNotEmpty)
                                    ? const Color(0xFF153f1e)
                                    : const Color(0xFF94A3B8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: (appCtrl.isSendButtonEnabled ||
                                        attachedFiles.isNotEmpty)
                                    ? () =>
                                        _sendMessage(appCtrl.messageCtrl.text)
                                    : null,
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Loading overlay
        Consumer<app_ctrl.AppCtrl>(
          builder: (context, appCtrl, child) {
            bool showLoading = _shouldShowInitialLoading &&
                !_hasAgentSpoken &&
                (appCtrl.connectionState ==
                        app_ctrl.ConnectionState.connecting ||
                    appCtrl.connectionState ==
                        app_ctrl.ConnectionState.connected);

            if (showLoading) {
              return _buildVoiceAgentLoadingOverlay();
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildHistoricalMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: _currentChatSession!.messages.length,
      itemBuilder: (context, index) {
        final message = _currentChatSession!.messages[index];
        return _buildMessageBubble(message.text, message.isLocal,
            attachedFiles: message.attachedFiles, isTyping: message.isTyping);
      },
    );
  }

  Widget _buildLiveTranscription() {
    return components.TranscriptionBuilder(
      builder: (context, transcriptions) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          itemCount: transcriptions.length,
          itemBuilder: (context, index) {
            final transcription = transcriptions[index];
            final participant = transcription.participant;
            final isLocal = participant is lk.LocalParticipant;
            return _buildMessageBubble(transcription.segment.text, isLocal);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isLocal,
      {List<AttachedFile>? attachedFiles, bool isTyping = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isLocal ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // For assistant messages: avatar first, then message - UPDATED ICONS AND COLORS
          if (!isLocal) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF153F1E)
                    .withOpacity(0.1), // Light green background
                borderRadius: BorderRadius.circular(16),
              ),
              child: isTyping
                  ? _buildLoadingIcon()
                  : const Icon(
                      Icons.smart_toy_outlined, // Updated to match first file
                      color: Color(0xFF153F1E), // Dark green icon
                      size: 18,
                    ),
            ),
            const SizedBox(width: 12),
          ],

          // Message bubble - sized to content
          Flexible(
            child: IntrinsicWidth(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  minWidth: 100,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLocal
                      ? const Color(0xFF153f1e)
                      : const Color(0xFF153f1e).withOpacity(0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isLocal ? 12 : 4),
                    bottomRight: Radius.circular(isLocal ? 4 : 12),
                  ),
                  border: Border.all(
                    color: isLocal
                        ? const Color(0xFF1e5e29)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isLocal
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Attachments preview (if any)
                    if (attachedFiles != null && attachedFiles.isNotEmpty) ...[
                      ...attachedFiles.map((file) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLocal
                                  ? const Color(0xFF153f1e).withOpacity(0.05)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getFileIcon(file.name),
                                  size: 16,
                                  color: const Color(0xFF64748b),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    file.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748b),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],

                    // Message content with copy button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: isTyping
                              ? _buildTypingIndicator()
                              : SelectableText(
                                  text,
                                  textAlign: isLocal
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isLocal
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                    height: 1.4,
                                    fontWeight: isLocal
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                ),
                        ),
                        if (!isTyping) ...[
                          const SizedBox(width: 8),
                          // Copy button with hover effect
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: isLocal
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF64748b),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // For user messages: message first, then avatar - UPDATED ICONS AND COLORS
          if (isLocal) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF153F1E)
                    .withOpacity(0.1), // Light green background
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_outline, // Updated to match first file
                color: Color(0xFF153F1E), // Dark green icon
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatHistoryItem(
      String title, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF153f1e).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: const Color(0xFF153f1e).withOpacity(0.2),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive
                          ? const Color(0xFF153f1e)
                          : const Color(0xFF64748b),
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isActive)
                  const Icon(
                    Icons.more_horiz,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Advanced File Attachment Methods
  Future<void> _scanDocuments() async {
    try {
      _safeSetState(() => _isUploading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.bytes != null) {
            String extension = file.extension?.toLowerCase() ?? '';
            String fileId = DateTime.now().millisecondsSinceEpoch.toString() +
                '_${file.name}';

            AttachedFile attachedFile = AttachedFile(
              id: fileId,
              name: file.name,
              type: _getFileTypeFromExtension(extension),
              size: _formatFileSize(file.size),
              data: file.bytes!,
            );

            _safeSetState(() {
              attachedFiles.add(attachedFile);
              filePromptControllers[fileId] = TextEditingController();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading documents: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      _safeSetState(() => _isUploading = false);
    }
  }

  // EXACT REPLICA: Attachment Preview - Matching Image Style Exactly
  Widget _buildAttachmentPreview() {
    if (attachedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with paperclip icon and hamburger menu - EXACT MATCH
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file,
                    size: 16, color: Color(0xFF64748b)),
                const SizedBox(width: 8),
                Text(
                  '${attachedFiles.length} file(s) attached',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748b),
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      // Show options menu
                    },
                    child: const Icon(
                      Icons.menu,
                      size: 16,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: attachedFiles.length,
            itemBuilder: (context, index) =>
                _buildAttachedFileItem(attachedFiles[index]),
          ),
        ],
      ),
    );
  }

  // EXACT REPLICA: File Item - Matching Image Style Exactly
  Widget _buildAttachedFileItem(AttachedFile file) {
    final controller = filePromptControllers[file.id]!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header row - EXACT MATCH to image
          Row(
            children: [
              // File icon - exact blue color from image
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.image,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 12),

              // File info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          file.size,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Green "Instructions" label - EXACT MATCH
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons - EXACT MATCH to image
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Eye icon (preview)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        // Preview file
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),

                  // Expand/collapse icon
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _togglePromptEdit(file),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          file.isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),

                  // Close icon
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _removeAttachedFile(file),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Show instructions below file when not expanded but has prompt - NEW ADDITION
          if (!file.isExpanded &&
              file.prompt != null &&
              file.prompt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.prompt!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expandable instructions section - EXACT MATCH to image
          if (file.isExpanded) ...[
            const SizedBox(height: 16),

            // "Instructions for this file:" label with icon - EXACT MATCH
            const Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(width: 6),
                Text(
                  'Instructions for this file:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Text input - EXACT MATCH to image styling
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                  hintText: 'Add specific instructions for this file...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel and Done buttons - EXACT MATCH to image
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button - exact styling from image
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _cancelPromptEdit(file),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Done button - exact styling from image
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _savePromptEdit(file),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _togglePromptEdit(AttachedFile file) {
    _safeSetState(() {
      int index = attachedFiles.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        if (!file.isExpanded) {
          // Start editing
          filePromptControllers[file.id]!.text = file.prompt ?? '';
          attachedFiles[index] = file.copyWith(
            isExpanded: true,
            originalPrompt: file.prompt,
          );
        } else {
          // Cancel editing
          attachedFiles[index] = file.copyWith(
            isExpanded: false,
            originalPrompt: null,
          );
        }
      }
    });
  }

  void _savePromptEdit(AttachedFile file) {
    _safeSetState(() {
      int index = attachedFiles.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        String newPrompt = filePromptControllers[file.id]!.text.trim();
        attachedFiles[index] = file.copyWith(
          prompt: newPrompt.isEmpty ? null : newPrompt,
          isExpanded: false,
          originalPrompt: null,
        );
      }
    });
  }

  void _cancelPromptEdit(AttachedFile file) {
    _safeSetState(() {
      int index = attachedFiles.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        filePromptControllers[file.id]!.text = file.originalPrompt ?? '';
        attachedFiles[index] = file.copyWith(
          prompt: file.originalPrompt,
          isExpanded: false,
          originalPrompt: null,
        );
      }
    });
  }

  void _removeAttachedFile(AttachedFile file) {
    _safeSetState(() {
      attachedFiles.removeWhere((f) => f.id == file.id);
      filePromptControllers[file.id]?.dispose();
      filePromptControllers.remove(file.id);
    });
  }

  void _clearAttachments() {
    for (var controller in filePromptControllers.values) {
      controller.dispose();
    }
    _safeSetState(() {
      attachedFiles.clear();
      filePromptControllers.clear();
    });
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty && attachedFiles.isEmpty) return;

    String fullMessage = userMessage;

    if (attachedFiles.isNotEmpty) {
      fullMessage += '\n\n[Attachments]:';
      for (var file in attachedFiles) {
        fullMessage += '\n📄 ${file.name}';
        if (file.prompt != null && file.prompt!.isNotEmpty) {
          fullMessage += ' - Instructions: ${file.prompt}';
        }
      }
    }

    final filesToSend = List<AttachedFile>.from(attachedFiles);

    _clearAttachments();
    context.read<app_ctrl.AppCtrl>().messageCtrl.clear();

    // Add message to transcription/history
    final appCtrl = context.read<app_ctrl.AppCtrl>();
    appCtrl.messageCtrl.text = fullMessage;
    appCtrl.sendMessage();
  }

  // Utility methods
  FileType _getFileTypeFromExtension(String extension) {
    switch (extension) {
      case 'pdf':
      case 'doc':
      case 'docx':
        return FileType.custom;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return FileType.image;
      case 'txt':
        return FileType.custom;
      default:
        return FileType.custom;
    }
  }

  IconData _getFileIcon(String fileName) {
    String extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ORIGINAL Floating loading dots widget - FOR LOADING SCREEN ONLY
class _FloatingLoadingDots extends StatefulWidget {
  @override
  State<_FloatingLoadingDots> createState() => _FloatingLoadingDotsState();
}

class _FloatingLoadingDotsState extends State<_FloatingLoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _floatAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
        3,
        (index) => AnimationController(
              duration: Duration(milliseconds: 800 + (index * 100)),
              vsync: this,
            ));

    _scaleAnimations = _controllers
        .map((controller) => Tween(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut)))
        .toList();

    _floatAnimations = _controllers
        .map((controller) => Tween(begin: 0.0, end: -8.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut)))
        .toList();

    _startAnimations();
  }

  void _startAnimations() async {
    while (mounted) {
      for (int i = 0; i < _controllers.length; i++) {
        if (mounted) {
          _controllers[i].forward();
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
      await Future.delayed(const Duration(milliseconds: 300));

      for (int i = 0; i < _controllers.length; i++) {
        if (mounted) {
          _controllers[i].reverse();
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: Listenable.merge(
                [_scaleAnimations[index], _floatAnimations[index]]),
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.translate(
                  offset: Offset(0, _floatAnimations[index].value),
                  child: Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF153f1e)
                            .withOpacity(_scaleAnimations[index].value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF153f1e).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF153f1e),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748b),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ModernFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF153f1e).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF153f1e),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
