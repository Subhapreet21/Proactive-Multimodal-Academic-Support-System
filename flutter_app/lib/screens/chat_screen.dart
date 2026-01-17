import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import '../models/message_model.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  File? _selectedImage;
  bool _isListening = false;
  List<Map<String, String>> _suggestions = [];
  String? _conversationId;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSuggestions();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get latest conversation
      final conversations =
          await _apiService.get(AppConstants.chatConversationsEndpoint);
      if (conversations != null && (conversations as List).isNotEmpty) {
        _conversationId = conversations[0]['id'];

        // 2. Load messages for this conversation
        final history = await _apiService
            .get('${AppConstants.chatHistoryEndpoint}/$_conversationId');
        if (history != null) {
          setState(() {
            _messages = (history as List).map((m) {
              return MessageModel.fromJson(m);
            }).toList();
          });
        }
      } else {
        _loadInitialMessage();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      _loadInitialMessage();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _resetChat() {
    setState(() {
      _messages = [];
      _conversationId = null;
      _loadInitialMessage();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => print('Speech error: $error'),
      );
      setState(() {});
    } catch (e) {
      print('Speech init error: $e');
    }
  }

  void _loadInitialMessage() {
    _messages.add(MessageModel(
      id: '1',
      role: 'assistant',
      content:
          'Hello! I am your Campus Assistant. Ask me anything about your schedule, exams, or notices.',
    ));
  }

  void _loadSuggestions() {
    _suggestions = [
      {'label': "What's my next class?", 'icon': '📅'},
      {'label': 'Pending Assignments', 'icon': '📝'},
      {'label': 'Exam Schedule', 'icon': '📌'},
      {'label': 'Library Hours', 'icon': '📚'},
    ];
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedImage == null) || _isLoading) return;

    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      imageUrl: _selectedImage?.path,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
      _selectedImage = null; // Clear image after sending
    });

    _scrollToBottom();

    try {
      Map<String, dynamic> response;

      if (userMessage.imageUrl != null) {
        response = await _apiService.postMultipart(
          AppConstants.chatImageEndpoint,
          {'prompt': text.isNotEmpty ? text : 'Describe this image'},
          File(userMessage.imageUrl!),
        );
      } else {
        final history = _messages
            .where((m) => m.role != 'error') // Exclude error messages
            .map((m) => {
                  'role': m.role == 'assistant' ? 'model' : 'user',
                  'content': m.content,
                })
            .toList();

        response = await _apiService.post(
          AppConstants.chatTextEndpoint,
          {
            'message': text,
            'conversationId': _conversationId ?? 'default',
            'history': history,
          },
        );
      }

      if (response['conversationId'] != null) {
        _conversationId = response['conversationId'];
      }

      final assistantMessage = MessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response['response'] ??
            response['message'] ??
            'Sorry, I could not understand that.',
      );

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });
    } catch (e) {
      final errorMessage = MessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          print('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
      );

      if (mounted) {
        setState(() => _speechEnabled = available);
      }

      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Mic permission denied. Please enable it in Settings.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Column(
        children: [
          // Clear Chat Button Logic
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _resetChat,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: Colors.white70),
                  label: const Text('Reset Chat',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Suggested Queries (Horizontal Scroll)
          if (_messages.length <= 1)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        _messageController.text = suggestion['label']!;
                        _sendMessage();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(suggestion['icon']!,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(
                              suggestion['label']!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
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

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A)
                  .withOpacity(0.8), // Semi-transparent bottom
              border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text("Image selected",
                                style: TextStyle(color: Colors.white70))),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () =>
                              setState(() => _selectedImage = null),
                        )
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.image_outlined),
                        onPressed: _pickImage,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask anything...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isListening
                            ? AppTheme.errorColor.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05), // Active state
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded),
                        onPressed: _toggleListening,
                        color:
                            _isListening ? AppTheme.errorColor : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ]),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: _sendMessage,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color:
              isUser ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(20),
            bottomLeft:
                isUser ? const Radius.circular(20) : const Radius.circular(4),
          ),
          border:
              isUser ? null : Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(message.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Text Content with Markdown Support
            MarkdownBody(
              data: message.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                    color:
                        isUser ? Colors.white : Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.4),
                strong: TextStyle(
                    color: isUser ? Colors.white : Colors.white,
                    fontWeight: FontWeight.bold),
                code: TextStyle(
                  backgroundColor: isUser ? Colors.black26 : Colors.black54,
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                codeblockDecoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                listBullet:
                    TextStyle(color: isUser ? Colors.white : Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking...',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
