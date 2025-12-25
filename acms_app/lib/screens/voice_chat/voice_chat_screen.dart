import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'package:acms_app/providers/agent_provider.dart';

import 'dart:math' as math;

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Initialize the agent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    final agent = context.read<AgentProvider>();

    if (agent.isListening) {
      agent.stopListening();
    } else if (agent.isSpeaking) {
      agent.stopSpeaking();
    } else {
      agent.startListening();
    }
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _showTextInput = false);

    final agent = context.read<AgentProvider>();
    await agent.processTextInput(text);
  }

  String _getStatusText(AgentState state) {
    switch (state) {
      case AgentState.idle:
        return 'Ready';
      case AgentState.listening:
        return 'Listening';
      case AgentState.processing:
        return 'Thinking...';
      case AgentState.speaking:
        return 'Speaking';
      case AgentState.error:
        return 'Error';
    }
  }

  Color _getStatusColor(AgentState state) {
    switch (state) {
      case AgentState.idle:
        return Colors.grey;
      case AgentState.listening:
        return AppColors.success;
      case AgentState.processing:
        return AppColors.primary;
      case AgentState.speaking:
        return Colors.blue;
      case AgentState.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subtextColor = isDark ? Colors.grey[400] : AppColors.textSub;

    return Consumer<AgentProvider>(
      builder: (context, agent, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                // Subtle background gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.3),
                        radius: 1.2,
                        colors: [
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.08 : 0.05,
                          ),
                          backgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),

                Column(
                  children: [
                    // Header
                    _buildHeader(
                      isDark,
                      surfaceColor,
                      textColor,
                      subtextColor,
                      agent.state,
                    ),

                    const Spacer(flex: 2),

                    // Voice Orb
                    Center(child: _buildVoiceOrb(isDark, agent.state)),

                    const Spacer(flex: 1),

                    // Response Card
                    _buildResponseCard(
                      isDark,
                      surfaceColor,
                      textColor,
                      subtextColor,
                      agent,
                    ),

                    const Spacer(flex: 2),

                    // Controls
                    if (_showTextInput)
                      _buildTextInput(isDark, surfaceColor, textColor)
                    else
                      _buildControls(
                        isDark,
                        surfaceColor,
                        textColor,
                        agent.state,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color? subtextColor,
    AgentState state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 18,
              ),
            ),
          ),
          // Title with status
          Column(
            children: [
              Text(
                'Vextra AI',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(state),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusText(state),
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Clear history button
          IconButton(
            onPressed: () {
              context.read<AgentProvider>().clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation cleared'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.refresh_rounded, color: textColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color? subtextColor,
    AgentProvider agent,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: _buildCardContent(isDark, textColor, subtextColor, agent),
      ),
    );
  }

  Widget _buildCardContent(
    bool isDark,
    Color textColor,
    Color? subtextColor,
    AgentProvider agent,
  ) {
    // Show error state
    if (agent.error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 28),
          const SizedBox(height: 8),
          Text(
            agent.error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Show listening with transcript
    if (agent.isListening) {
      if (agent.transcript.isNotEmpty) {
        return Text(
          agent.transcript,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        );
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildListeningWave(isDark),
          const SizedBox(height: 12),
          Text(
            "I'm listening...",
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Show processing
    if (agent.isProcessing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Processing...",
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (agent.transcript.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${agent.transcript}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }

    // Show speaking/response
    if (agent.isSpeaking || agent.lastResponse.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (agent.isSpeaking)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Speaking',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            agent.lastResponse,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    // Idle state - show prompt
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mic_rounded, color: subtextColor, size: 28),
        const SizedBox(height: 8),
        Text(
          "Tap the mic and say something like:",
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"Create a post about technology"',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildListeningWave(bool isDark) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final offset = index * 0.15;
            final value = math.sin(
              (_waveController.value + offset) * math.pi * 2,
            );
            final height = 8 + (value * 12).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.6 + value * 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVoiceOrb(bool isDark, AgentState state) {
    final isActive =
        state == AgentState.listening || state == AgentState.processing;

    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseValue = _pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring pulse (only when active)
              if (isActive)
                Container(
                  width: 200 + (pulseValue * 20),
                  height: 200 + (pulseValue * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.2 * (1 - pulseValue),
                      ),
                      width: 2,
                    ),
                  ),
                ),

              // Second ring
              if (isActive)
                Container(
                  width: 170 + (pulseValue * 15),
                  height: 170 + (pulseValue * 15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: 0.3 * (1 - pulseValue * 0.5),
                      ),
                      width: 1.5,
                    ),
                  ),
                ),

              // Outer glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isActive ? 0.25 + (pulseValue * 0.15) : 0.15,
                      ),
                      blurRadius: isActive ? 40 + (pulseValue * 20) : 30,
                      spreadRadius: isActive ? 10 + (pulseValue * 10) : 5,
                    ),
                  ],
                ),
              ),

              // Main orb
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      AppColors.primaryDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),

              // Inner highlight
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Center icon
              Icon(_getOrbIcon(state), color: Colors.white, size: 40),
            ],
          );
        },
      ),
    );
  }

  IconData _getOrbIcon(AgentState state) {
    switch (state) {
      case AgentState.listening:
        return Icons.graphic_eq_rounded;
      case AgentState.processing:
        return Icons.psychology_rounded;
      case AgentState.speaking:
        return Icons.volume_up_rounded;
      case AgentState.error:
        return Icons.error_outline_rounded;
      case AgentState.idle:
        return Icons.mic_rounded;
    }
  }

  Widget _buildTextInput(bool isDark, Color surfaceColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _showTextInput = false),
            icon: Icon(Icons.close, color: textColor),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _submitText(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _submitText,
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    bool isDark,
    Color surfaceColor,
    Color textColor,
    AgentState state,
  ) {
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient fade
        Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundColor.withValues(alpha: 0), backgroundColor],
            ),
          ),
        ),
        // Main controls
        Container(
          width: double.infinity,
          color: backgroundColor,
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Keyboard Input
              _buildControlButton(
                icon: Icons.keyboard_rounded,
                label: 'Type',
                onTap: () => setState(() => _showTextInput = true),
                isDark: isDark,
              ),

              // Main Mic Toggle
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child:
                        Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: state == AgentState.listening
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: state == AgentState.listening
                                        ? AppColors.primary.withValues(
                                            alpha: 0.4,
                                          )
                                        : Colors.black.withValues(alpha: 0.1),
                                    blurRadius: state == AgentState.listening
                                        ? 24
                                        : 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: state == AgentState.listening
                                        ? 2
                                        : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                state == AgentState.listening
                                    ? Icons.stop_rounded
                                    : (state == AgentState.speaking
                                          ? Icons.stop_rounded
                                          : Icons.mic_rounded),
                                color:
                                    state == AgentState.listening ||
                                        state == AgentState.speaking
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 32,
                              ),
                            )
                            .animate(
                              target: state == AgentState.listening ? 1 : 0,
                            )
                            .scale(
                              end: const Offset(0.95, 0.95),
                              duration: 100.ms,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getButtonLabel(state),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Help/Examples
              _buildControlButton(
                icon: Icons.help_outline_rounded,
                label: 'Help',
                onTap: () => _showHelp(context),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getButtonLabel(AgentState state) {
    switch (state) {
      case AgentState.listening:
        return 'Tap to stop';
      case AgentState.speaking:
        return 'Tap to stop';
      case AgentState.processing:
        return 'Processing...';
      default:
        return 'Tap to speak';
    }
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Try saying...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 16),
            _buildHelpItem('"Create a post about AI trends"'),
            _buildHelpItem('"Go to my profile"'),
            _buildHelpItem('"Switch to dark mode"'),
            _buildHelpItem('"Show my notifications"'),
            _buildHelpItem('"Search for users"'),
            _buildHelpItem('"Save this as a draft"'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : AppColors.textSub,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
