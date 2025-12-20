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
  final ScrollController _scrollController = ScrollController();
  String? _lastTranscript;
  String? _lastResponse;
  int _lastHistoryLength = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

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
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    // Scroll to bottom after a short delay to ensure content is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleListening(VoiceAssistantProvider provider, BuildContext context) {
    if (provider.isListening) {
      provider.stopListening();
      provider.resetFollowUp();
    } else {
      provider.setContext(context);
      provider.startListening(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantProvider>(
      builder: (context, provider, child) {
        // Control animation based on listening state
        if (provider.isListening && !_animationController.isAnimating) {
          _animationController.repeat(reverse: true);
        } else if (!provider.isListening && _animationController.isAnimating) {
          _animationController.stop();
          _animationController.reset();
        }

        final hasContent = provider.conversationHistory.isNotEmpty || 
                          provider.transcript.isNotEmpty || 
                          provider.response.isNotEmpty;
        
        // Auto-scroll when new content appears
        final transcriptChanged = provider.transcript != _lastTranscript;
        final responseChanged = provider.response != _lastResponse;
        final historyChanged = provider.conversationHistory.length != _lastHistoryLength;
        
        if (transcriptChanged || responseChanged || historyChanged) {
          _lastTranscript = provider.transcript;
          _lastResponse = provider.response;
          _lastHistoryLength = provider.conversationHistory.length;
          _scrollToBottom();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with status and mic button
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusIndicator(provider),
                        ),
                        const SizedBox(width: 16),
                        _buildMicButton(provider, context),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Conversation area
                    if (hasContent || provider.isProcessing)
                      _buildConversationArea(provider)
                    else
                      _buildWelcomeMessage(),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: provider.isListening
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton(VoiceAssistantProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () => _toggleListening(provider, context),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: provider.isListening
                    ? [Colors.redAccent, Colors.red.shade700]
                    : provider.isProcessing
                        ? [Colors.orange, Colors.orange.shade700]
                        : provider.isSpeaking
                            ? [Colors.blue, Colors.blue.shade700]
                            : [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
              ),
              boxShadow: provider.isListening
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 25 * _pulseAnimation.value,
                        spreadRadius: 8 * _pulseAnimation.value,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
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
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationArea(VoiceAssistantProvider provider) {
    // Build all messages in correct chronological order
    final List<Widget> messageWidgets = [];
    
    // Add error message first if present
    if (provider.error != null) {
      messageWidgets.add(_buildErrorMessage(provider.error!));
    }
    
    // Add all conversation history messages
    for (final msg in provider.conversationHistory) {
      final text = msg['text'] ?? '';
      if (text.isNotEmpty) {
        messageWidgets.add(_buildMessageBubble(
          text,
          isUser: msg['role'] == 'user',
        ));
      }
    }
    
    // Add current transcript if it exists and is different from last user message
    if (provider.transcript.isNotEmpty) {
      final lastUserMsg = provider.conversationHistory
          .where((msg) => msg['role'] == 'user')
          .lastOrNull;
      final lastUserText = lastUserMsg?['text'] ?? '';
      
      // Show transcript if it's different or if there's no history yet
      if (provider.transcript != lastUserText || provider.conversationHistory.isEmpty) {
        messageWidgets.add(_buildMessageBubble(
          provider.transcript,
          isUser: true,
          isPartial: provider.isListening,
        ));
      }
    }
    
    // Add current response if it exists and is different from last assistant message
    if (provider.response.isNotEmpty) {
      final lastAssistantMsg = provider.conversationHistory
          .where((msg) => msg['role'] == 'assistant')
          .lastOrNull;
      final lastAssistantText = lastAssistantMsg?['text'] ?? '';
      
      // Show response if it's different or if there's no history yet
      if (provider.response != lastAssistantText || provider.conversationHistory.isEmpty) {
        messageWidgets.add(_buildMessageBubble(
          provider.response,
          isUser: false,
        ));
      }
    }
    
    // Add processing indicator at the end
    if (provider.isProcessing) {
      messageWidgets.add(_buildProcessingIndicator());
    }
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _scrollController,
        reverse: false, // Changed to false so we can scroll to bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: messageWidgets,
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.mic_none,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the mic to start',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try: "Show my appointments" or "Go to reports"',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing your request...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, {required bool isUser, bool isPartial = false}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.blueAccent, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUser
                      ? [
                          AppTheme.primaryGreen.withOpacity(0.25),
                          AppTheme.primaryGreenDark.withOpacity(0.2),
                        ]
                      : [
                          Colors.blue.withOpacity(0.2),
                          Colors.blueAccent.withOpacity(0.15),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.primaryGreen.withOpacity(0.4)
                      : Colors.blue.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.greenAccent, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
