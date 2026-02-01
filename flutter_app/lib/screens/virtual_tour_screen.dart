import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:collection';
import 'dart:convert';
import '../services/tour_assistant_service.dart';

class VirtualTourScreen extends StatefulWidget {
  const VirtualTourScreen({super.key});

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String _errorMessage = "";
  int _retryCount = 0;
  static const int _maxAutoRetries = 2;
  String _selectedScene = '';
  String? _expandedCategory;

  // AI Chat Assistant State
  final TourAssistantService _tourAssistant = TourAssistantService();
  bool _isChatOpen = false;
  final List<Map<String, String>> _chatMessages = [];
  bool _isAiThinking = false;
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<String> _suggestedQuestions = [];
  List<Map<String, dynamic>> _sceneCategories = [];

  // --- JavaScript Scripts (Extracted to avoid Parser Errors) ---
  static const String _antiReloadScript = r"""
    console.log("Anti-reload script injected");
    // Block explicit reloads and location assignment
    window.location.reload = function() { console.warn('Blocked reload attempt'); };
    window.location.replace = function(url) { console.warn('Blocked location.replace: ' + url); };
    // We don't block href assignment here to allow valid interaction,
    // but we rely on shouldOverrideUrlLoading for the main page.
  """;

  static const String _themeInjectionScript = r"""
    (function() {
      console.log('Starting theme injection...');
      
      // Function to apply theme to elements
      function applyTheme(element) {
        var changed = false;
        var color = window.getComputedStyle(element).color;
        var tagName = element.tagName.toLowerCase();
        
        // Check for red color in various formats
        // Note: Using flexible checks to avoid rigid equality issues
        if (color.includes('255, 0, 0') || 
            color == 'red' || 
            element.getAttribute('color') == 'red' ||
            element.getAttribute('color') == '#ff0000' ||
            (element.style && element.style.color && 
             (element.style.color.includes('red') || element.style.color.includes('255, 0, 0')))) {
          
          element.style.setProperty('color', '#7C3AED', 'important');
          element.style.transition = 'all 0.3s ease';
          changed = true;
          
          // Add hover listeners
          element.addEventListener('mouseenter', function() {
            this.style.setProperty('color', '#A78BFA', 'important');
          });
          element.addEventListener('mouseleave', function() {
            this.style.setProperty('color', '#7C3AED', 'important');
          });
          element.addEventListener('touchstart', function() {
            this.style.setProperty('color', '#A78BFA', 'important');
          });
          element.addEventListener('touchend', function() {
            this.style.setProperty('color', '#7C3AED', 'important');
          });
        }
        return changed;
      }
      
      // Function to scan and apply theme to all elements
      function scanAndApply() {
        var count = 0;
        var allElements = document.getElementsByTagName('*');
        
        for (var i = 0; i < allElements.length; i++) {
          if (applyTheme(allElements[i])) {
            count++;
          }
        }
        return count;
      }
      
      // Add global CSS rules
      var style = document.createElement('style');
      style.innerHTML = `
        a, span, div, p, font, label {
          transition: color 0.3s ease !important;
        }
      `;
      document.head.appendChild(style);
      
      // Initial scan after delays
      setTimeout(scanAndApply, 100);
      setTimeout(scanAndApply, 500);
      setTimeout(scanAndApply, 1000);
      setTimeout(scanAndApply, 2000);
      
      // Set up MutationObserver to catch dynamically added elements
      var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          if (mutation.addedNodes && mutation.addedNodes.length > 0) {
            mutation.addedNodes.forEach(function(node) {
              if (node.nodeType === 1) { // Element node
                applyTheme(node);
                // Also check all children
                var children = node.getElementsByTagName('*');
                for (var i = 0; i < children.length; i++) {
                  applyTheme(children[i]);
                }
              }
            });
          }
        });
      });
      
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
      
      console.log('MutationObserver set up');
    })();
  """;

  static const String _hideKrpanoLogsScript = r"""
    (function() {
      try {
        var krpano = document.getElementById('krpanoSWFObject');
        if (krpano && krpano.call) {
          // Hide krpano's error/log layer
          krpano.call("showlog(false);");
          console.log('Krpano error logs hidden');
        }
        
        // Aggressive CSS to hide log text (but not SVG/image controls)
        var style = document.createElement('style');
        style.innerHTML = `
          /* Hide text divs with text-shadow (logs use this) */
          #krpanoSWFObject > div[style*="text-shadow"] {
            display: none !important;
            visibility: hidden !important;
          }
          
          /* Hide divs with monospace font (typical for logs) */
          #krpanoSWFObject > div[style*="monospace"] {
            display: none !important;
          }
        `;
        document.head.appendChild(style);
      } catch(e) {
        console.log('Error hiding krpano logs:', e);
      }
    })();
  """;

  static const String _nuclearAntiReloadScript = r"""
    (function() {
      try {
        console.log('=== INITIALIZING ANTI-RELOAD SYSTEM ===');
        
        // Function to disable all krpano reload mechanisms
        function disableKrpanoReloads() {
          var krpano = document.getElementById('krpanoSWFObject');
          if (krpano && krpano.call) {
            krpano.call('set(events.onidletimer, null);');
            krpano.call('set(events.onidle, null);');
            krpano.call('set(events.onstartup, null);');
            krpano.call('set(events.onloadcomplete, null);');
            krpano.call('set(idletime, 0);');
            krpano.call('set(control.idletime, 0);');
            krpano.call('set(autorotate.enabled, false);');
            krpano.call('set(autorotate.waittime, 0);');
          }
        }
        
        // Disable immediately
        disableKrpanoReloads();
        setInterval(disableKrpanoReloads, 1000);
        
        // Block usage of window.location
        var blocked = 0;
        try {
            Object.defineProperty(window, 'location', {
              get: function() { return { href: '', reload: function(){}, replace: function(){}, assign: function(){} }; },
              set: function(v) { console.log('BLOCKED location set'); },
              configurable: false
            });
        } catch(e) {}
        
      } catch(e) {
        console.log('Error in anti-reload system:', e);
      }
    })();
  """;

  // Scene categories with sub-scenes
  // Scene categories with sub-scenes
  // Moved from JS to Dart to ensure availability even if WebView fails (Robustness Fix)
  static final List<Map<String, dynamic>> _fallbackSceneCategories = [
    {
      'category': 'CAMPUS VIEW',
      'scenes': [
        {'id': 'pano220', 'name': '01. University Block'},
        {'id': 'pano221', 'name': '02. Campus View - 1'},
        {'id': 'pano222', 'name': '03. Campus View - 2'},
        {'id': 'pano495', 'name': '04. Aerial View'}
      ]
    },
    {
      'category': 'VC CHAMBER',
      'scenes': [
        {'id': 'pano228', 'name': '01. VC Chamber'},
        {'id': 'pano229', 'name': '02. Board Room'}
      ]
    },
    {
      'category': 'ADMISSION WING',
      'scenes': [
        {'id': 'pano232', 'name': '01. Admission Wing'},
        {'id': 'pano579', 'name': '02. Administration Wing'}
      ]
    },
    {
      'category': 'DEPT. OF CSE',
      'scenes': [
        {'id': 'pano236', 'name': '01. Class Room'},
        {'id': 'pano237', 'name': '02. Computer Science Lab'},
        {'id': 'pano581', 'name': '03. BEEE Lab'},
        {'id': 'pano239', 'name': '04. Engineering Workshop'},
        {'id': 'pano240', 'name': '05. Graphics Lab'},
        {'id': 'pano241', 'name': '06. Physics Lab'},
        {'id': 'pano242', 'name': '07. Classroom & Labs'}
      ]
    },
    {
      'category': 'DEPT. OF AGRICULTURE',
      'scenes': [
        {'id': 'pano250', 'name': '01. Agriculture Department Block'},
        {'id': 'pano251', 'name': '02. Agriculture Department Classroom & Lab'},
        {'id': 'pano252', 'name': '03. Horticulture Lab'},
        {'id': 'pano590', 'name': '04. Genetics & Plant Breeding Lab'},
        {'id': 'pano254', 'name': '05. Furrow System of Irrigation'},
        {'id': 'pano597', 'name': '06. Cultivation of Plants Under Shade Net'},
        {
          'id': 'pano256',
          'name': '07. Demonstration & Construction of Poly House'
        }
      ]
    },
    {
      'category': 'DEPT. OF MGMT & SCIENCES',
      'scenes': [
        {'id': 'pano657', 'name': '01. School of Mgmt. & Science Block'},
        {'id': 'pano658', 'name': '02. Class Room'},
        {'id': 'pano659', 'name': '03. Forensic Lab'},
        {'id': 'pano660', 'name': '04. Physics Lab'}
      ]
    },
    {
      'category': 'FACILITIES',
      'scenes': [
        {'id': 'pano665', 'name': '01. Library'},
        {'id': 'pano666', 'name': '02. Cafeteria'},
        {'id': 'pano667', 'name': '03. Girls Hostel Block'},
        {'id': 'pano668', 'name': '04. Girls Hostel Mess'},
        {'id': 'pano669', 'name': '05. Girls Hostel Room'},
        {'id': 'pano670', 'name': '06. Boys Hostel Block'},
        {'id': 'pano671', 'name': '07. Boys Hostel Mess'},
        {'id': 'pano672', 'name': '08. Boys Hostel Room'},
        {'id': 'pano673', 'name': '09. Indoor Stadium'},
        {'id': 'pano674', 'name': '10. Indoor Games'},
        {'id': 'pano675', 'name': '11. Auditorium'},
        {'id': 'pano676', 'name': '12. GYM'},
        {'id': 'pano677', 'name': '13. Basket Ball Court'},
        {'id': 'pano678', 'name': '14. Cricket Ground'},
        {'id': 'pano679', 'name': '15. Volley Ball Court'},
        {'id': 'pano680', 'name': '16. Transport'}
      ]
    }
  ];

  // The hosted 360 tour URL with params:
  // - idletime=10000: Disable "onidle" event (which triggers reload) for ~3 hours
  // - autorotate.enabled=true: Ensure auto-rotate is ON
  // - autorotate.waittime=5: Restart rotation after 5 seconds of inactivity
  static const String _tourUrl = String.fromEnvironment('TOUR_URL',
      defaultValue:
          "http://zeal360.co.in/360/mallareddyuniversity2/MallaReddyUniversity.html?idletime=10000&autorotate.enabled=true&autorotate.waittime=5");

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize with fallback data immediately so explorer works even if WebView fails
    _sceneCategories = List.from(_fallbackSceneCategories);
    if (_sceneCategories.isNotEmpty &&
        _sceneCategories[0]['scenes'].isNotEmpty) {
      _selectedScene = _sceneCategories[0]['scenes'][0]['id'];
    }

    // Auto-update suggestions for initial scene
    if (_selectedScene.isNotEmpty) {
      _updateSuggestionsForScene(_selectedScene);
    }
  }

  void _updateSuggestionsForScene(String sceneId) {
    // This could also fetch from backend, but for now using scene names
    // If backend fails, we have defaults
    setState(() {
      _suggestedQuestions = const [
        'What is this place?',
        'What facilities are available here?',
        'What are the timings?',
        'How can I reach this location?'
      ];
    });
  }

  void _loadScenesFromKrpano() async {
    // We already have scenes loaded locally, so we just check for errors
    // or sync if needed. But for robustness, we prioritize local data.
    // The previous JS injection is only needed if we want to dynamically verify scenes.

    // We can just verify connectivity here
    try {
      final result = await _webViewController?.evaluateJavascript(
          source: "document.title");
      if (result != null) {
        // WebView is alive
        setState(() {
          _isLoading = false;
          _retryCount = 0;
          _errorMessage = "";
        });
      }
    } catch (e) {
      debugPrint("WebView check failed: $e");
    }
  }

  void _loadScene(String sceneId) {
    setState(() => _selectedScene = sceneId);
    _webViewController?.evaluateJavascript(source: """
      try {
        var krpano = document.getElementById('krpanoSWFObject');
        if (krpano && krpano.call) {
          krpano.call('loadscene($sceneId, null, MERGE, BLEND(1));');
          console.log('Loading scene: $sceneId');
        }
      } catch(e) {
        console.log('Error loading scene:', e);
      }
    """);
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_tourUrl)),
    );
  }

  void _handleError(String description) {
    if (!mounted) return;

    // Auto-retry up to max retries
    if (_retryCount < _maxAutoRetries) {
      _retryCount++;
      debugPrint("Auto-retry attempt $_retryCount due to: $description");
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _retry();
      });
    } else {
      // Show friendly error after max retries
      setState(() {
        _isLoading = false;
        // Don't show technical error details to user, just availability status
        _errorMessage = "The virtual tour is currently unavailable.\n\n"
            "But don't worry! I'm still here to help.";
      });
    }
  }

  // AI Chat Methods
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _selectedScene.isEmpty) return;

    // Validate message length (max 500 characters)
    final trimmedMessage = message.trim();
    if (trimmedMessage.length > 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Question too long. Please keep it under 500 characters.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Add user message
    setState(() {
      _chatMessages.add({'role': 'user', 'content': trimmedMessage});
      _isAiThinking = true;
    });

    // Clear input
    _chatInputController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // Limit conversation history to last 10 messages for API efficiency
      final limitedHistory = _chatMessages.length > 10
          ? _chatMessages.sublist(_chatMessages.length - 10)
          : _chatMessages;

      // Call backend API
      final response = await _tourAssistant.askQuestion(
        sceneId: _selectedScene,
        question: trimmedMessage,
        conversationHistory: limitedHistory,
      );

      // Add AI response
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'assistant',
            'content':
                response['answer'] ?? 'Sorry, I couldn\'t get a response.',
          });
          _isAiThinking = false;

          // Update suggested questions if provided
          if (response['sceneContext'] != null &&
              response['sceneContext']['suggestedQuestions'] != null) {
            _suggestedQuestions = List<String>.from(
                response['sceneContext']['suggestedQuestions']);
          }
        });

        // Scroll to bottom again after response
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          // Add friendly error message to chat
          _chatMessages.add({
            'role': 'assistant',
            'content':
                'Sorry, I encountered an error. Please check your connection and try again.',
          });
        });

        // Show snackbar with actionable guidance
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to reach the assistant. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Reset chat conversation
  void _resetChat() {
    setState(() {
      _chatMessages.clear();
      _suggestedQuestions = [
        'What is this place?',
        'What facilities are available here?',
        'What are the timings?',
        'How can I reach this location?',
      ];
    });
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.black,
      // Removed AppBar to prevent overlap with tour navigation
      body: Stack(
        children: [
          // 1. The WebView (Main Content)
          SafeArea(
            child: InAppWebView(
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(
                    source: _antiReloadScript,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
              ]),
              initialUrlRequest: URLRequest(url: WebUri(_tourUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                // userAgent removed to use default mobile UA
                // userAgent: "Mozilla/5.0 ...",
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                hardwareAcceleration: true,
                mediaPlaybackRequiresUserGesture: false,
                cacheEnabled: true,
                clearCache: false,
                // Allow zooming
                supportZoom: true,
                // Hybrid composition for better stability on Android
                useHybridComposition: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                debugPrint("Loading: $url");
              },
              onLoadStop: (controller, url) async {
                if (mounted) {
                  _retryCount = 0;
                  setState(() => _isLoading = false);

                  // Inject comprehensive styling with MutationObserver
                  await controller.evaluateJavascript(
                      source: _themeInjectionScript);

                  // Hide krpano error logs that overlay on screen
                  await controller.evaluateJavascript(
                      source: _hideKrpanoLogsScript);

                  // NUCLEAR-LEVEL anti-reload prevention
                  await controller.evaluateJavascript(
                      source: _nuclearAntiReloadScript);

                  // Load actual scenes from krpano
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    _loadScenesFromKrpano();
                  });
                }
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint("WebView Console: ${consoleMessage.message}");
              },
              onReceivedError: (controller, request, error) {
                debugPrint("WebView Error: ${error.description}");
                _handleError(error.description);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;

                // Allow other links (if any) but BLOCK re-loading the tour page itself
                // form any idle timer or scripts.
                if (uri.toString().contains("MallaReddyUniversity.html")) {
                  debugPrint("Blocking auto-reload navigation to: $uri");
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),

          // 2. Custom Navigation Overlay (matching app theme)
          if (!_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E1B4B), // Dark navy (matching app)
                      const Color(0xFF1E1B4B).withOpacity(0.95),
                      const Color(0xFF1E1B4B).withOpacity(0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.vrpano_rounded,
                                color: Color(0xFF6366F1),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Explore campus locations by category',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category navigation with expandable dropdowns
                      if (_sceneCategories.isNotEmpty) ...[
                        // CategoryButtons (horizontal scrollable)
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _sceneCategories.length,
                            itemBuilder: (context, index) {
                              final category = _sceneCategories[index];
                              final categoryName =
                                  category['category'] as String;
                              final isExpanded =
                                  _expandedCategory == categoryName;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedCategory =
                                          isExpanded ? null : categoryName;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpanded
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFF6366F1)
                                              .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isExpanded
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF6366F1)
                                                .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: TextStyle(
                                            color: isExpanded
                                                ? Colors.white
                                                : const Color(0xFF818CF8),
                                            fontSize: 12,
                                            fontWeight: isExpanded
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: isExpanded
                                              ? Colors.white
                                              : const Color(0xFF818CF8),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Expanded scene list (shows when category is tapped)
                        if (_expandedCategory != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(top: 12),
                            child: Builder(
                              builder: (context) {
                                final expandedCat = _sceneCategories.firstWhere(
                                  (c) => c['category'] == _expandedCategory,
                                  orElse: () => <String, Object>{
                                    'category': '',
                                    'scenes': <Map<String, String>>[]
                                  },
                                );
                                final scenes =
                                    (expandedCat['scenes'] ?? []) as List;

                                // Calculate dynamic height: show up to 4 items
                                // Each item is ~50px (48px height + padding)
                                final itemHeight = 50.0;
                                final itemsToShow =
                                    scenes.length > 4 ? 4 : scenes.length;
                                final dynamicHeight = itemsToShow * itemHeight +
                                    16.0; // +16 for padding

                                return Container(
                                  height: dynamicHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    border: Border.all(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: scenes.length,
                                    separatorBuilder: (_, __) => Divider(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.2),
                                      height: 1,
                                    ),
                                    itemBuilder: (context, index) {
                                      final scene = scenes[index] as Map;
                                      final sceneId = scene['id'] as String;
                                      final sceneName = scene['name'] as String;
                                      final isSelected =
                                          _selectedScene == sceneId;

                                      return InkWell(
                                        onTap: () {
                                          _loadScene(sceneId);
                                          setState(
                                              () => _expandedCategory = null);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              if (isSelected)
                                                Container(
                                                  width: 4,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF6366F1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                              if (isSelected)
                                                const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  sceneName,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF6366F1)
                                                        : Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Color(0xFF6366F1),
                                                  size: 18,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _retryCount > 0
                          ? "Connecting... (Attempt ${_retryCount + 1})"
                          : "Loading Virtual Campus...",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // 4. Error View (Robust Fallback)
          if (_errorMessage.isNotEmpty)
            Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_off_rounded,
                            color: Colors.white54, size: 48),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Tour Connection Issue",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style:
                            const TextStyle(color: Colors.white70, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Primary Action: Use AI
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isChatOpen = true;
                              // Ensure we have prompts ready
                              if (_suggestedQuestions.isEmpty) {
                                _suggestedQuestions = const [
                                  'What is this place?',
                                  'What facilities are available here?',
                                  'What are the timings?',
                                  'How can I reach this location?'
                                ];
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.emoji_objects),
                          label: const Text("Ask AI Assistant Instead",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Secondary Action: Retry
                      TextButton.icon(
                        onPressed: () {
                          _retryCount = 0;
                          _retry();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white54),
                        label: const Text("Try Reconnecting",
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // AI Chat Overlay
          if (_isChatOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isChatOpen = false),
                child: Container(
                  color: Colors.black54,
                  child: GestureDetector(
                    onTap:
                        () {}, // Prevent taps from closing when clicking inside
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: MediaQuery.of(context).size.height * 0.50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withOpacity(0.75),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Chat Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF5B21B6)
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI Tour Guide',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Ask anything about this location',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _resetChat(),
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    tooltip: 'Reset Chat',
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _isChatOpen = false),
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    tooltip: 'Close Chat',
                                  ),
                                ],
                              ),
                            ),

                            // Messages List
                            Expanded(
                              child: _chatMessages.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 64,
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Ask me about this location!',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            // Suggested Questions
                                            if (_suggestedQuestions
                                                .isNotEmpty) ...[
                                              const Text(
                                                'Try asking:',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                alignment: WrapAlignment.center,
                                                children: _suggestedQuestions
                                                    .map((q) {
                                                  return GestureDetector(
                                                    onTap: () =>
                                                        _sendMessage(q),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF6366F1)
                                                            .withOpacity(0.3),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xFF6366F1),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        q,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _chatScrollController,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _chatMessages.length,
                                      itemBuilder: (context, index) {
                                        final message = _chatMessages[index];
                                        final isUser =
                                            message['role'] == 'user';
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            mainAxisAlignment: isUser
                                                ? MainAxisAlignment.end
                                                : MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (!isUser)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 8),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF6366F1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isUser
                                                        ? const Color(
                                                            0xFF6366F1)
                                                        : const Color(
                                                            0xFF2A2A2A),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Text(
                                                    message['content']!,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // AI Thinking Indicator
                            if (_isAiThinking)
                              Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'AI is thinking...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Input Field
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A).withOpacity(0.8),
                                border: Border(
                                  top: BorderSide(color: Color(0xFF3A3A3A)),
                                ),
                              ),
                              child: SafeArea(
                                top: false,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _chatInputController,
                                        enabled: !_isAiThinking,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: _selectedScene.isEmpty
                                              ? 'Select a scene first...'
                                              : 'Ask about this location...',
                                          hintStyle: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF1E1E1E)
                                              .withOpacity(0.6),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                        onSubmitted: (value) {
                                          if (value.trim().isNotEmpty) {
                                            _sendMessage(value);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF5B21B6)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: IconButton(
                                        onPressed: _isAiThinking ||
                                                _selectedScene.isEmpty
                                            ? null
                                            : () {
                                                final text =
                                                    _chatInputController.text
                                                        .trim();
                                                if (text.isNotEmpty) {
                                                  _sendMessage(text);
                                                }
                                              },
                                        icon: const Icon(Icons.send,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Floating Chat Button (hide when chat is open)
          if (!_isChatOpen)
            Positioned(
              bottom: 80,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isChatOpen = true;
                    // Initialize default suggestions if none exist
                    if (_suggestedQuestions.isEmpty) {
                      _suggestedQuestions = [
                        'What is this place?',
                        'What facilities are available here?',
                        'What are the timings?',
                        'How can I reach this location?',
                      ];
                    }
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_objects,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
