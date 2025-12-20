import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class VoiceAssistantProvider with ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ApiService _apiService = ApiService();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _transcript = '';
  String _response = '';
  String? _error;
  List<Map<String, String>> _conversationHistory = [];
  bool _waitingForFollowUp = false;
  String? _lastAction;

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  String get transcript => _transcript;
  String get response => _response;
  String? get error => _error;
  List<Map<String, String>> get conversationHistory => _conversationHistory;
  bool get waitingForFollowUp => _waitingForFollowUp;
  String? get lastAction => _lastAction;

  Future<bool> init({bool checkPermission = false}) async {
    try {
      // Check permissions if requested
      if (checkPermission) {
        final micPermission = await Permission.microphone.status;
        if (micPermission.isDenied) {
          final result = await Permission.microphone.request();
          if (result.isDenied) {
            _error = 'Microphone permission is required for voice assistant.';
            notifyListeners();
            return false;
          }
        }
        
        if (micPermission.isPermanentlyDenied) {
          _error = 'Microphone permission is permanently denied. Please enable it in app settings.';
          notifyListeners();
          return false;
        }
      }

      // Initialize speech recognition - this will return false if not available
      final available = await _speech.initialize(
        onError: (error) {
          _error = 'Speech recognition error: ${error.errorMsg}';
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
      
      if (!available) {
        _error = 'Speech recognition initialization failed. Please check your device settings.';
        notifyListeners();
        return false;
      }
      
      // Slower speech rate for better clarity (0.0 to 1.0, default is 0.5)
      await _tts.setSpeechRate(0.4); // Much slower for better understanding
      await _tts.setLanguage('en-US');
      // Set pitch slightly lower for clearer speech (0.5 to 2.0, default is 1.0)
      await _tts.setPitch(0.9); // Slightly lower pitch for clearer voice
      // Set volume to max for clarity
      await _tts.setVolume(1.0);
      
      // Set up TTS completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        
        // Auto-start listening if waiting for follow-up
        // Longer delay since slower speech takes more time
        if (_waitingForFollowUp) {
          Future.delayed(const Duration(milliseconds: 800), () {
            startListening(context: _context);
          });
        }
      });
      
      return true;
    } catch (e) {
      _error = 'Voice init failed: $e';
      notifyListeners();
      return false;
    }
  }

  BuildContext? _context;
  
  void setContext(BuildContext? context) {
    _context = context;
  }

  Future<void> startListening({BuildContext? context}) async {
    if (context != null) {
      _context = context;
    }
    if (_isListening || _isProcessing) return;
    _error = null;
    notifyListeners();
    
    // Check and request microphone permission
    final micPermission = await Permission.microphone.status;
    if (!micPermission.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (result.isPermanentlyDenied) {
          _error = 'Microphone permission is permanently denied. Please enable it in app settings.';
        } else {
          _error = 'Microphone permission is required. Please grant permission to use voice assistant.';
        }
        notifyListeners();
        return;
      }
    }
    
    // Initialize speech recognition with permission check
    final available = await init(checkPermission: false); // Already checked above
    if (!available) {
      return;
    }

    _transcript = '';
    _response = '';
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) async {
        _transcript = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          await _speech.stop();
          _isListening = false;
          _isProcessing = true;
          notifyListeners();
          await _sendToAssistant(_transcript, context: _context ?? context);
        }
      },
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> _sendToAssistant(String text, {BuildContext? context}) async {
    if (text.isEmpty) {
      _error = 'No speech detected.';
      _isProcessing = false;
      notifyListeners();
      return;
    }

    try {
      // Add user message to conversation history
      _conversationHistory.add({'role': 'user', 'text': text});
      
      final response = await _apiService.voiceAssistant(
        text,
        context: _conversationHistory.takeLast(6).toList(),
        lastAction: _lastAction,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      _response = data['text']?.toString() ?? 'No response.';
      _lastAction = data['intentAction']?.toString() ?? _lastAction;
      
      // Handle navigation
      if (data['navigation'] != null && context != null) {
        final navigation = data['navigation'] as Map<String, dynamic>?;
        final route = navigation?['route']?.toString();
        if (route != null) {
          // Navigate after a short delay to let TTS start
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              GoRouter.of(context).go(route);
            }
          });
        }
      }
      
      // Check if this is a follow-up question
      _waitingForFollowUp = data['needsClarification'] == true || 
                           _response.toLowerCase().contains('?') ||
                           _response.toLowerCase().contains('which') ||
                           _response.toLowerCase().contains('what') ||
                           _response.toLowerCase().contains('when');
      
      // Add assistant response to conversation history
      _conversationHistory.add({'role': 'assistant', 'text': _response});
      
      _error = null;
      _isSpeaking = true;
      notifyListeners();
      
      // Add pauses for better clarity by inserting commas/periods
      final formattedResponse = _formatTextForSpeech(_response);
      await _tts.speak(formattedResponse);
    } catch (e) {
      _error = 'Assistant error: $e';
      _waitingForFollowUp = false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    final formattedText = _formatTextForSpeech(text);
    await _tts.speak(formattedText);
  }
  
  // Format text to add pauses for better TTS clarity
  String _formatTextForSpeech(String text) {
    if (text.isEmpty) return text;
    
    String formatted = text;
    
    // Ensure spaces after punctuation for natural pauses
    formatted = formatted.replaceAllMapped(
      RegExp(r'([.,:;!?])([^\s.,:;!?])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Add natural pauses before important information (times, dates, doctor names)
    // Add pause before time expressions
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\s)(at\s+)(\d{1,2}:\d{2}|\d{1,2}\s*(?:AM|PM|am|pm))', caseSensitive: false),
      (match) => '${match.group(1)}${match.group(2)}${match.group(3)}',
    );
    
    // Ensure proper spacing around numbers
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d+)([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Add pause before lists (items separated by commas/semicolons)
    formatted = formatted.replaceAllMapped(
      RegExp(r'([^,;])(,|;)([^,;])'),
      (match) => '${match.group(1)}${match.group(2)} ${match.group(3)}',
    );
    
    return formatted.trim();
  }

  void clear() {
    _transcript = '';
    _response = '';
    _error = null;
    _isListening = false;
    _isProcessing = false;
    _isSpeaking = false;
    _waitingForFollowUp = false;
    _conversationHistory.clear();
    _lastAction = null;
    notifyListeners();
  }
  
  void resetFollowUp() {
    _waitingForFollowUp = false;
    notifyListeners();
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (n <= 0) return [];
    if (length <= n) return List<T>.from(this);
    return sublist(length - n);
  }
}


