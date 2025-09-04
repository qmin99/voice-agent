import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:voice_assistant/widgets/voicepad.dart';
import '../controllers/app_ctrl.dart' as app_ctrl;

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

  ChatMessage({
    required this.text,
    required this.isLocal,
    required this.timestamp,
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
  bool _hasAgentSpoken = false; // Add this

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
    super.dispose();
  }

  // Add this method to detect agent speech
  void _onTranscriptionChanged() {
    final transcriptions = context.read<app_ctrl.AppCtrl>().roomContext.transcriptions;
    
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
                              const Color(0xFF153f1e),
                              const Color(0xFF1e5e29),
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
                            const Icon(
                              Icons.gavel_rounded,
                              color: Colors.white,
                              size: 40,
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
                  tween: IntTween(begin: 0, end: "Initializing HAAKEEM".length),
                  builder: (context, value, child) {
                    return Text(
                      "Initializing HAAKEEM".substring(0, value),
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
      _hasAgentSpoken = false; // Reset this
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

    // Save current chat if it has messages (you'll need to implement this based on your transcription data)
    // _saveCurrentChatSession();

    setState(() {
      _currentView = AppView.welcome;
      _currentChatSession = null;
      _hasAgentSpoken = false; // Reset this
      _shouldShowInitialLoading = true; // Reset this
    });
  }

  void _loadChatSession(ChatSession session) {
    setState(() {
      _currentView = AppView.chat;
      _currentChatSession = session;
    });
    // Here you might want to restore the chat context or just show historical messages
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
            child: GestureDetector(
              onTap: () {
                // Handle settings
              },
              child: Container(
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
                      Icons.settings_outlined,
                      color: Color(0xFF64748b),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Color(0xFF64748b),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF153f1e).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Color(0xFF153f1e),
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Welcome Title
            const Text(
              'Welcome to HAAKEEM',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1e293b),
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Your AI-powered legal assistant',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748b),
              ),
            ),

            const SizedBox(height: 48),

            // Start Voice Mode Button
            ElevatedButton.icon(
              onPressed: _startNewChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF153f1e),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.mic_rounded, size: 20),
              label: const Text(
                'Start Voice Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Features
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const Column(
                children: [
                  _FeatureItem(
                    icon: Icons.security,
                    title: 'Secure & Confidential',
                    description: 'Your conversations are encrypted and private',
                  ),
                  SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.speed,
                    title: 'Instant Legal Guidance',
                    description:
                        'Get immediate answers to your legal questions',
                  ),
                  SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.verified_user,
                    title: 'Expert Knowledge',
                    description: 'Powered by comprehensive legal databases',
                  ),
                ],
              ),
            ),
          ],
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                onTap: () =>
                    context.read<app_ctrl.AppCtrl>().messageFocusNode.unfocus(),
                child: _currentChatSession != null &&
                        _currentChatSession!.messages.isNotEmpty
                    ? _buildHistoricalMessages()
                    : _buildLiveTranscription(),
              ),
            ),
          ),

          // Input Area
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
                // Text Input with Dark Green Send Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
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
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(4),
                        child: IconButton(
                          onPressed: () {
                            // Handle voice input toggle
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
                      Consumer<app_ctrl.AppCtrl>(
                        builder: (context, appCtrl, child) => Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: appCtrl.isSendButtonEnabled
                                ? const Color(0xFF153f1e)
                                : const Color(0xFF94A3B8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: appCtrl.isSendButtonEnabled
                                ? () => appCtrl.sendMessage()
                                : null,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
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
      
      // UPDATED: Loading overlay - hide when agent speaks
      Consumer<app_ctrl.AppCtrl>(
        builder: (context, appCtrl, child) {
          // Show loading only if agent hasn't spoken yet
          bool showLoading = _shouldShowInitialLoading && !_hasAgentSpoken &&
                            (appCtrl.connectionState == app_ctrl.ConnectionState.connecting ||
                             appCtrl.connectionState == app_ctrl.ConnectionState.connected);
          
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
        return _buildMessageBubble(message.text, message.isLocal);
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

  Widget _buildMessageBubble(String text, bool isLocal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isLocal ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // For assistant messages: avatar first, then message
          if (!isLocal) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF153f1e),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.assistant_rounded,
                color: Colors.white,
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
                      ? const Color(0xFF153f1e).withOpacity(0.1)
                      : const Color(0xFF153f1e).withOpacity(0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isLocal ? 12 : 4),
                    bottomRight: Radius.circular(isLocal ? 4 : 12),
                  ),
                  border: Border.all(
                    color: isLocal
                        ? const Color(0xFF153f1e).withOpacity(0.2)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isLocal
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message content with copy button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: SelectableText(
                            text,
                            textAlign:
                                isLocal ? TextAlign.right : TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              color: isLocal
                                  ? const Color(0xFF153f1e)
                                  : const Color(0xFF374151),
                              height: 1.4,
                              fontWeight:
                                  isLocal ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
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
                                    ? const Color(0xFF153f1e).withOpacity(0.7)
                                    : const Color(0xFF64748b),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // For user messages: message first, then avatar
          if (isLocal) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF153f1e),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
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
}

// NEW: Floating loading dots widget
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
    
    _controllers = List.generate(3, (index) => 
      AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      )
    );
    
    _scaleAnimations = _controllers.map((controller) => 
      Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      )
    ).toList();

    _floatAnimations = _controllers.map((controller) => 
      Tween(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      )
    ).toList();

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
            animation: Listenable.merge([_scaleAnimations[index], _floatAnimations[index]]),
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
                        color: const Color(0xFF153f1e).withOpacity(_scaleAnimations[index].value),
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