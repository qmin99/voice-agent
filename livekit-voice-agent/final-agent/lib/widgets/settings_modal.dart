import 'package:flutter/material.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  // Settings state variables
  String _aiResponseMode = 'contextual'; // 'contextual' or 'fresh'
  String _voiceMode = 'english'; // 'english' or 'arabic'
  String _agentMode = 'attorney'; // 'attorney' or 'click_to_talk'
  String _micSensitivity = 'High';
  String _volume = 'Medium';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 380,
          height: 600, // Fixed height to match image
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                        Icons.settings,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        Text(
                          'Configure preferences',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748b),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Voice Mode Section
                      Row(
                        children: [
                          const Icon(
                            Icons.record_voice_over,
                            color: Color(0xFF153f1e),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Voice Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Language Toggle
                      Row(
                        children: [
                          Expanded(
                            child: _buildHoverableLanguageButton(
                              text: 'English',
                              isSelected: _voiceMode == 'english',
                              onTap: () => setState(() => _voiceMode = 'english'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHoverableLanguageButton(
                              text: 'العربية',
                              isSelected: _voiceMode == 'arabic',
                              onTap: () => setState(() => _voiceMode = 'arabic'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Agent Mode Options
                      _buildRadioOption(
                        title: 'Attorney Agent',
                        subtitle: 'Continuous legal guidance',
                        value: 'attorney',
                        groupValue: _agentMode,
                        onChanged: (value) => setState(() => _agentMode = value!),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildRadioOption(
                        title: 'Click to Talk Agent',
                        subtitle: 'Long-form consultation mode',
                        value: 'click_to_talk',
                        groupValue: _agentMode,
                        onChanged: (value) => setState(() => _agentMode = value!),
                      ),

                      const SizedBox(height: 24),

                      // AI Response Section
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology,
                            color: Color(0xFF153f1e),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Response',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRadioOption(
                        title: 'Contextual AI',
                        subtitle: 'Remembers conversation history',
                        value: 'contextual',
                        groupValue: _aiResponseMode,
                        onChanged: (value) => setState(() => _aiResponseMode = value!),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildRadioOption(
                        title: 'Fresh Start AI',
                        subtitle: 'Independent responses',
                        value: 'fresh',
                        groupValue: _aiResponseMode,
                        onChanged: (value) => setState(() => _aiResponseMode = value!),
                      ),

                      const SizedBox(height: 24),

                      // Audio Section (only show when in first settings view)
                      if (_agentMode == 'attorney') ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.volume_up,
                              color: Color(0xFF153f1e),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Audio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildSettingRow('Mic Sensitivity', _micSensitivity),
                        const SizedBox(height: 12),
                        _buildSettingRow('Volume', _volume),
                        const SizedBox(height: 12),
                        _buildSettingRow('Language', _language),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // Save Button - Fixed at bottom with hover
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: _buildHoverableSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovering = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF153f1e) 
                      : isHovering 
                          ? const Color(0xFF153f1e).withOpacity(0.4)
                          : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected 
                    ? const Color(0xFF153f1e).withOpacity(0.05) 
                    : isHovering 
                        ? const Color(0xFF153f1e).withOpacity(0.02)
                        : Colors.transparent,
                boxShadow: isHovering && !isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF153f1e).withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF153f1e) 
                            : isHovering 
                                ? const Color(0xFF153f1e).withOpacity(0.6)
                                : const Color(0xFF94A3B8),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF153f1e),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? const Color(0xFF153f1e) 
                                : isHovering 
                                    ? const Color(0xFF153f1e)
                                    : const Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected 
                                ? const Color(0xFF153f1e).withOpacity(0.8) 
                                : isHovering 
                                    ? const Color(0xFF153f1e).withOpacity(0.7)
                                    : const Color(0xFF64748b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748b),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF153f1e),
          ),
        ),
      ],
    );
  }

  Widget _buildHoverableLanguageButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovering = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF153f1e) 
                    : isHovering 
                        ? const Color(0xFF153f1e).withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF153f1e)
                      : isHovering 
                          ? const Color(0xFF153f1e).withOpacity(0.4)
                          : const Color(0xFFE2E8F0),
                  width: isSelected || isHovering ? 1.5 : 1,
                ),
                boxShadow: isHovering && !isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF153f1e).withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isHovering ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? Colors.white 
                        : isHovering 
                            ? const Color(0xFF153f1e)
                            : const Color(0xFF64748b),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoverableSaveButton() {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovering = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // Save settings logic here
              Navigator.of(context).pop();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isHovering 
                    ? const Color(0xFF0d3017) // Darker green on hover
                    : const Color(0xFF153f1e),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isHovering
                    ? [
                        BoxShadow(
                          color: const Color(0xFF153f1e).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..scale(isHovering ? 1.05 : 1.0),
                    child: const Icon(
                      Icons.save, 
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isHovering ? FontWeight.w700 : FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Function to show the settings modal
void showSettingsModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return const SettingsModal();
    },
  );
}