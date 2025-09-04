import 'dart:ui';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import 'package:voice_assistant/controllers/app_ctrl.dart' as ctrl;
import 'package:voice_assistant/widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Material(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.3, 0.7, 1.0],
              colors: [
                Color(0xFF0a2912),
                Color(0xFF153f1e),
                Color(0xFF1e5e29),
                Color(0xFF0f3318),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle background elements
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.3, 0.2),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF3a964e).withOpacity(0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              SafeArea(
                child: Stack(
                  children: [
                    // Minimal Developer Access Button
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                            child: TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: const Text('Developer mode activated'),
                                    backgroundColor: const Color(0xFF153f1e),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.code_outlined,
                                color: Colors.white60,
                                size: 14,
                              ),
                              label: const Text(
                                'Dev',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Main Content - Ultra Clean
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.88),
                              Colors.white.withOpacity(0.92),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3a964e).withOpacity(0.12),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0a2912).withOpacity(0.25),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: const Color(0xFF153f1e).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(32, 32, 32, 36),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Premium Logo Container
                                  Container(
                                    height: 48,
                                    width: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: const [0.0, 0.15, 0.85, 1.0],
                                        colors: [
                                          const Color(0xFF1e5e29).withOpacity(0.95),
                                          const Color(0xFF153f1e),
                                          const Color(0xFF0f3318),
                                          const Color(0xFF0a2912).withOpacity(0.98),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF3a964e).withOpacity(0.25),
                                        width: 0.5,
                                      ),
                                      boxShadow: [
                                        // Main shadow
                                        BoxShadow(
                                          color: const Color(0xFF0a2912).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                          spreadRadius: -2,
                                        ),
                                        // Inner glow
                                        BoxShadow(
                                          color: const Color(0xFF3a964e).withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                          spreadRadius: -1,
                                        ),
                                        // Top highlight
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.05),
                                          blurRadius: 1,
                                          offset: const Offset(0, -0.5),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [0.0, 0.3, 1.0],
                                          colors: [
                                            Colors.white.withOpacity(0.08),
                                            Colors.white.withOpacity(0.02),
                                            Colors.black.withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Image.asset(
                                              'binfin8_logo.png',
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Text(
                                                    'binfin8',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.8,
                                                      shadows: [
                                                        Shadow(
                                                          color: Color(0xFF0a2912),
                                                          blurRadius: 2,
                                                          offset: Offset(0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Clean Subtitle
                                  const Text(
                                    'AI Legal Assistant',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF64748b),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Lean Description
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFf8fafc).withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF153f1e).withOpacity(0.06),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Text(
                                      'Natural conversations for legal matters. Draft wills, review contracts, and discuss estate planning with AI assistance.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF475569),
                                        height: 1.3,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 28),
                                  
                                  // Sleek Action Button
                                  Builder(
                                    builder: (ctx) {
                                      final isProgressing = [
                                        ctrl.ConnectionState.connecting,
                                        ctrl.ConnectionState.connected,
                                      ].contains(ctx.watch<ctrl.AppCtrl>().connectionState);
                                      
                                      return Container(
                                        width: 240, // Reduced width
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isProgressing 
                                              ? [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400,
                                                ]
                                              : [
                                                  const Color(0xFF0a2912),
                                                  const Color(0xFF153f1e),
                                                  const Color(0xFF1e5e29),
                                                ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isProgressing ? Colors.grey : const Color(0xFF153f1e))
                                                  .withOpacity(0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: isProgressing ? null : () => ctx.read<ctrl.AppCtrl>().connect(),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.08),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isProgressing) ...[
                                                      SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white.withOpacity(0.9),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ] else ...[
                                                      Container(
                                                        padding: const EdgeInsets.all(1.5),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Icon(
                                                          Icons.mic_rounded,
                                                          color: Colors.white,
                                                          size: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    Text(
                                                      isProgressing ? 'Connecting' : 'Start Assistant',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Minimal Footer
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '© 2025 Binfin8 All Rights Reserved',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.3,
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
      );
}