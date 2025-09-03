import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:livekit_client/livekit_client.dart' as lk;
import '../controllers/app_ctrl.dart' as app_ctrl;

class LegalChatInterface extends StatefulWidget {
  const LegalChatInterface({super.key});

  @override
  State<LegalChatInterface> createState() => _LegalChatInterfaceState();
}

class _LegalChatInterfaceState extends State<LegalChatInterface> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add a listener to automatically scroll to the bottom on new messages
    context.read<app_ctrl.AppCtrl>().roomContext.addListener(_onRoomContextChanged);
  }

  @override
  void dispose() {
    context.read<app_ctrl.AppCtrl>().roomContext.removeListener(_onRoomContextChanged);
    _scrollController.dispose();
    super.dispose();
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
            Container(
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
                        onPressed: () {
                          // Handle new chat - could clear transcriptions
                        },
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
                  
                  // Chat History Button
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
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildChatHistoryItem('Current Session', true),
                        _buildChatHistoryItem('Contract Review Discussion', false),
                        _buildChatHistoryItem('Legal Document Analysis', false),
                        _buildChatHistoryItem('Estate Planning Consultation', false),
                      ],
                    ),
                  ),
                  
                  // Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF64748b),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Color(0xFF64748b),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Chat Area
            Expanded(
              child: Column(
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Legal Assistant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Live conversation active',
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
                            final isConnected = appCtrl.connectionState == app_ctrl.ConnectionState.connected;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    color: isConnected ? const Color(0xFF10B981) : Colors.orange,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isConnected ? 'Connected' : 'Connecting...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isConnected ? const Color(0xFF10B981) : Colors.orange,
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
                            'Voice Mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // REAL Chat Messages - Connected to LiveKit transcriptions
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: GestureDetector(
                        onTap: () => context.read<app_ctrl.AppCtrl>().messageFocusNode.unfocus(),
                        child: components.TranscriptionBuilder(
                          builder: (context, transcriptions) {
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              itemCount: transcriptions.length,
                              itemBuilder: (context, index) {
                                final transcription = transcriptions[index];
                                final participant = transcription.participant;
                                final isLocal = participant is lk.LocalParticipant;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isLocal
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF153f1e),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          isLocal
                                            ? Icons.person
                                            : Icons.assistant_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Message bubble
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isLocal
                                              ? const Color(0xFF3B82F6).withOpacity(0.1)
                                              : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Text(
                                            transcription.segment.text,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // REAL Input Area - Connected to actual message sending
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
                        // Real Text Input connected to AppCtrl
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Consumer<app_ctrl.AppCtrl>(
                                  builder: (context, appCtrl, child) => KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: (event) {
                                      // Check for a KeyDown event to prevent multiple triggers
                                      if (event is KeyDownEvent) {
                                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                                          // Check the global state of the Shift key
                                          if (HardwareKeyboard.instance.isShiftPressed) {
                                            // Handle Shift + Enter for new line
                                            appCtrl.messageCtrl.text += '\n';
                                          } else {
                                            // Handle Enter for sending the message
                                            appCtrl.sendMessage();
                                          }
                                        }
                                      }
                                    },
                                    child: TextField(
                                      controller: appCtrl.messageCtrl,
                                      focusNode: appCtrl.messageFocusNode,
                                      decoration: const InputDecoration(
                                        hintText: 'Type your legal question or speak...',
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
                                    context.read<app_ctrl.AppCtrl>().toggleAgentScreenMode();
                                  },
                                  icon: const Icon(
                                    Icons.mic_outlined,
                                    color: Color(0xFF8B5CF6),
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
                        
                        const SizedBox(height: 16),
                        
                        // Bottom Action Buttons
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                // Disconnect and show the welcome screen
                                context.read<app_ctrl.AppCtrl>().disconnect();
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF64748b),
                                size: 16,
                              ),
                              label: const Text(
                                'End Session',
                                style: TextStyle(
                                  color: Color(0xFF64748b),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle invite features
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text(
                                  'Invite',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle scanner
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.document_scanner, size: 16),
                                label: const Text(
                                  'Scanner',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Toggle back to audio visualizer
                                  context.read<app_ctrl.AppCtrl>().toggleAgentScreenMode();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.graphic_eq, size: 16),
                                label: const Text(
                                  'Change Mode',
                                  style: TextStyle(fontSize: 14),
                                ),
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildChatHistoryItem(String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF153f1e).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(
          color: const Color(0xFF153f1e).withOpacity(0.2),
        ) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? const Color(0xFF153f1e) : const Color(0xFF64748b),
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
    );
  }
}