import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_assistant_provider.dart';
import '../utils/theme.dart';

class VoiceAssistantWidget extends StatefulWidget {
  const VoiceAssistantWidget({super.key});

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening(VoiceAssistantProvider provider) {
    if (provider.isListening) {
      provider.stopListening();
      provider.resetFollowUp();
    } else {
      provider.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantProvider>(
      builder: (context, provider, child) {
        final isActive = provider.isListening || provider.isProcessing || provider.isSpeaking;
        
        // Stop animation when not listening
        if (provider.isListening) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
          _animationController.reset();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Status and mic button row
                    Row(
                      children: [
                        // Status indicator
                        Expanded(
                          child: _buildStatusIndicator(provider),
                        ),
                        const SizedBox(width: 16),
                        
                        // Mic button
                        GestureDetector(
                          onTap: () => _toggleListening(provider),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: provider.isListening
                                      ? Colors.redAccent
                                      : provider.isProcessing
                                          ? Colors.orange
                                          : provider.isSpeaking
                                              ? Colors.blue
                                              : AppTheme.primaryGreen,
                                  boxShadow: provider.isListening
                                      ? [
                                          BoxShadow(
                                            color: Colors.redAccent.withOpacity(0.4),
                                            blurRadius: 20 * _pulseAnimation.value,
                                            spreadRadius: 5 * _pulseAnimation.value,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Transform.scale(
                                  scale: provider.isListening ? _scaleAnimation.value : 1.0,
                                  child: Icon(
                                    provider.isListening
                                        ? Icons.hearing
                                        : provider.isProcessing
                                            ? Icons.hourglass_empty
                                            : provider.isSpeaking
                                                ? Icons.volume_up
                                                : Icons.mic,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Conversation area
                    if (provider.conversationHistory.isNotEmpty || provider.transcript.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current transcript
                              if (provider.transcript.isNotEmpty)
                                _buildMessageBubble(
                                  provider.transcript,
                                  isUser: true,
                                  isPartial: provider.isListening,
                                ),
                              
                              // Conversation history
                              ...provider.conversationHistory.map((msg) {
                                return _buildMessageBubble(
                                  msg['text'] ?? '',
                                  isUser: msg['role'] == 'user',
                                );
                              }),
                              
                              // Current response
                              if (provider.response.isNotEmpty && !provider.isListening)
                                _buildMessageBubble(
                                  provider.response,
                                  isUser: false,
                                ),
                              
                              // Processing indicator
                              if (provider.isProcessing)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Processing...',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // Error
                              if (provider.error != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          provider.error!,
                                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Instructions
                    if (!isActive && provider.conversationHistory.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap the mic to start',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(VoiceAssistantProvider provider) {
    String statusText;
    Color statusColor;

    if (provider.isListening) {
      statusText = 'Listening...';
      statusColor = Colors.redAccent;
    } else if (provider.isProcessing) {
      statusText = 'Processing...';
      statusColor = Colors.orange;
    } else if (provider.isSpeaking) {
      statusText = 'Speaking...';
      statusColor = Colors.blue;
    } else if (provider.waitingForFollowUp) {
      statusText = 'Waiting for your response...';
      statusColor = Colors.blueAccent;
    } else {
      statusText = 'Ready';
      statusColor = Colors.green;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: provider.isListening
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(String text, {required bool isUser, bool isPartial = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Icon(Icons.smart_toy, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryGreen.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser
                      ? AppTheme.primaryGreen.withOpacity(0.5)
                      : Colors.blue.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 4),
            const Icon(Icons.person, color: Colors.greenAccent, size: 16),
          ],
        ],
      ),
    );
  }
}

