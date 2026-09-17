import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

// ─────────────────────────────────────────────
//  Data model for a single chat bubble
// ─────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class AcademicAssistantScreen extends StatefulWidget {
  const AcademicAssistantScreen({super.key});

  @override
  State<AcademicAssistantScreen> createState() =>
      _AcademicAssistantScreenState();
}

class _AcademicAssistantScreenState extends State<AcademicAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _showWelcome = true;
  String? _currentChatId;
  
  

  // ── Gemini Configuration ───────────────────────────────────────────────
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
    _chatSession = _model.startChat();
  }

  // ── Quick-action cards (localized at build time) ────────────────────────
  List<_QuickAction> _buildQuickActions() => [
    _QuickAction(
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF00A650),
      title: 'qa_improve_gpa'.tr(),
      subtitle: 'qa_improve_gpa_sub'.tr(),
    ),
    _QuickAction(
      icon: Icons.calculate_rounded,
      iconColor: const Color(0xFF8B5CF6),
      title: 'qa_calc_gpa'.tr(),
      subtitle: 'qa_calc_gpa_sub'.tr(),
    ),
    _QuickAction(
      icon: Icons.lightbulb_outline_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: 'qa_study_tips'.tr(),
      subtitle: 'qa_study_tips_sub'.tr(),
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  //  Send message to Gemini
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _inputController.clear();

    final userMsg = ChatMessage(text: trimmed, isUser: true);
    setState(() {
      _showWelcome = false;
      _isSending = true;
      _messages.add(userMsg);
      // Immediately add a new, empty bot message to the local _messages list
      _messages.add(ChatMessage(text: '', isUser: false));
    });
    
    final botMsgIndex = _messages.length - 1;
    _scrollToBottom();
    
    // uid will come from stored auth token when needed

    try {
      // Chat persistence via REST (TODO: implement when backend has chat endpoints)
      _currentChatId ??= DateTime.now().millisecondsSinceEpoch.toString();

      // Requirement 2: Real-Time Streaming
      final stream = _chatSession.sendMessageStream(Content.text(trimmed));
      
      stream.listen(
        (event) {
          if (event.text != null) {
            setState(() {
              final currentText = _messages[botMsgIndex].text;
              _messages[botMsgIndex] = ChatMessage(
                text: currentText + event.text!,
                isUser: false,
              );
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          // Chat saved locally only
          setState(() => _isSending = false);
        },
        onError: (e) {
           debugPrint('====== GEMINI ERROR ======');
           debugPrint('$e');
          setState(() {
            final currentText = _messages[botMsgIndex].text;
            _messages[botMsgIndex] = ChatMessage(
              text: currentText.isNotEmpty 
                  ? '$currentText\n\n[تعذر الاتصال بـ Gemini. الخطأ: $e]'
                  : 'تعذر الاتصال بـ Gemini. الخطأ:\n$e',
              isUser: false,
            );
            _isSending = false;
          });
        },
      );

    } catch (e) {
      // This catch block handles synchronous errors before listen
       debugPrint('====== GEMINI SYNC ERROR ======');
       debugPrint('$e');
      setState(() {
        _messages[botMsgIndex] = ChatMessage(
          text: 'تعذر الاتصال بـ Gemini. الخطأ:\n$e',
          isUser: false,
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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


  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF001900)
            : const Color(0xFFF4F6FB),
        endDrawer: _buildHistoryDrawer(isDark),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _showWelcome
                    ? _buildWelcomeView(isDark)
                    : _buildChatView(isDark),
              ),
              _buildInputBar(isDark),
              _buildDisclaimer(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001900) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF003B00) : const Color(0xFFE8EAF0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right: Back Button
          const BackButton(),

          // Center: Title
          Expanded(
            child: Text(
              'title_academic_assistant'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF003B00),
              ),
            ),
          ),

          // Left: New Chat & History
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _inputController.clear();
                    _currentChatId = null;
                    _chatSession = _model.startChat();
                    _showWelcome = true;
                  });
                },
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Color(0xFF00A650), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'new_chat'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF00A650),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.history_rounded,
                    color: isDark ? Colors.white : const Color(0xFF003B00),
                  ),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Welcome / Home state ──────────────────────────────────────────────────
  Widget _buildWelcomeView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF003300) : const Color(0xFFEAF0FE),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.school_rounded,
                color: Color(0xFF00A650),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'chat_welcome'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF003B00),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ..._buildQuickActions().map(
            (action) => _buildQuickActionCard(action, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action, bool isDark) {
    return GestureDetector(
      onTap: () => _sendMessage(action.title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF003300) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    action.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF003B00),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat view ─────────────────────────────────────────────────────────────
  Widget _buildChatView(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (tileCtx, index) {
        final msg = _messages[index];
        return _buildBubble(msg, isDark);
      },
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isDark) {
    if (msg.isLoading) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF003300) : Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const _TypingIndicator(),
        ),
      );
    }

    final isUser = msg.isUser;
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF00A650)
              : (isDark ? const Color(0xFF003300) : Colors.white),
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(18),
            topLeft: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 15,
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF003B00)),
            height: 1.55,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF003300) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _isSending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF006B00),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A650),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 4,
              minLines: 1,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'chat_hint'.tr(),
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFADB5BD),
                  fontSize: 15,
                ),
                hintTextDirection: TextDirection.rtl,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF003B00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────
  Widget _buildDisclaimer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Text(
        'يمكن للمساعد الأكاديمي ارتكاب الأخطاء. يرجى التحقق من المعلومات المهمة',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? const Color(0xFF475569) : const Color(0xFFADB5BD),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHistoryDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF003300) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerRight,
              child: Text(
                'chat_history'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF003B00),
                ),
              ),
            ),
            Divider(color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
            Expanded(
              child: Center(
                child: Text(
                  'no_chats'.tr(),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper classes
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

// Animated three-dot typing indicator
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _anims = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: -6,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            transform: Matrix4.translationValues(0, _anims[i].value, 0),
            child: const CircleAvatar(
              radius: 4,
              backgroundColor: Color(0xFF94A3B8),
            ),
          ),
        );
      }),
    );
  }
}


