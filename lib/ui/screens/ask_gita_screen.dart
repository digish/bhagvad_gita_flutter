import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/ask_gita_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/credit_provider.dart';
import '../../services/ad_service.dart';
import '../widgets/ai_suggestion_chips.dart'; // ✨ Add AI Suggestions
import '../widgets/font_size_control.dart';
import '../../navigation/app_router.dart';
import '../../models/shloka_result.dart';

class AskGitaScreen extends StatefulWidget {
  final String? initialQuery;
  const AskGitaScreen({super.key, this.initialQuery});

  @override
  State<AskGitaScreen> createState() => _AskGitaScreenState();
}

class _AskGitaScreenState extends State<AskGitaScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode(); // ✨ Track input focus
  bool _isInputFocused = false;
  bool _hasSentInitialQuery = false;

  AskGitaProvider? _provider;

  @override
  void initState() {
    super.initState();
    // Auto-scroll logic is kept, but listener management moves to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the provider reference safely
    final newProvider = context.read<AskGitaProvider>();
    if (_provider != newProvider) {
      _provider?.removeListener(_scrollToBottom);
      _provider = newProvider;
      _provider?.addListener(() {
        _scrollToBottom();
      });

      // ✨ Listen to focus changes
      _inputFocusNode.addListener(() {
        setState(() {
          _isInputFocused = _inputFocusNode.hasFocus;
        });
      });

      // Handle initial query if provided
      if (widget.initialQuery != null && !_hasSentInitialQuery) {
        _hasSentInitialQuery = true;

        // Wait for credits to load before processing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _processInitialQuery();
          }
        });
      }
    }
  }

  Future<void> _processInitialQuery() async {
    final credits = context.read<CreditProvider>();

    // If credits are still loading, wait a bit
    if (credits.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && credits.isLoading) {
        // Still loading? Wait again. Simple polling for now as it's quick.
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (mounted && widget.initialQuery != null) {
      _sendMessage(widget.initialQuery!);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final credits = context.read<CreditProvider>();
    final settings = context.read<SettingsProvider>();

    // Safety check: Ensure credits are loaded
    if (credits.isLoading) {
      // Show a transient loading indicator or just return if it's manual
      // For manual send, user likely waited. For auto, _processInitialQuery handles wait.
      return;
    }

    // Skip credit check if user has their own API Key
    final hasCustomKey =
        settings.customAiApiKey != null && settings.customAiApiKey!.isNotEmpty;

    if (!hasCustomKey && !credits.hasCredit()) {
      // If we have an empty controller (initial query case), populate it
      // so user can see what they were trying to ask before they see the dialog
      if (_textController.text.isEmpty) {
        _textController.text = text;
      }
      _showLowBalanceDialog();
      return;
    }

    try {
      if (!hasCustomKey) {
        await credits.consumeCredit();
      }
      if (mounted) {
        context.read<AskGitaProvider>().sendMessage(text);
        // Only clear if the text was in the controller (user typed it or we populated it)
        if (_textController.text.isNotEmpty) {
          _textController.clear();
        }
        settings.markAskAiUsed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_scrollToBottom);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose(); // ✨ Dispose focus node
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to let the list build
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
  }

  Future<void> _handleSend() async {
    await _sendMessage(_textController.text);
  }

  void _showLowBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Running low on Credits?'),
        content: const Text(
          'Gita AI uses advanced technology which requires server resources.\n\n'
          'You have used your free daily credits. Would you like to earn more by performing a small Karma?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wait for Tomorrow'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.play_circle_filled),
            label: Text('Watch Ad (+${CreditProvider.adRewardAmount} Credits)'),
            onPressed: () {
              Navigator.pop(context);
              _showAd();
            },
          ),
        ],
      ),
    );
  }

  void _showAd() {
    AdService.instance.showRewardedAd(
      onRewardEarned: (reward) {
        context.read<CreditProvider>().addCredits(
          CreditProvider.adRewardAmount,
        );

        // Also show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Blessings Received! +${CreditProvider.adRewardAmount} Credits Added.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AskGitaProvider>();
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > MediaQuery.of(context).size.height;
    final showRail = width > 600;
    final double leftPadding = MediaQuery.of(context).padding.left;
    final double railWidth = isLandscape ? 220.0 : 100.0;

    final effectiveLeftPadding = leftPadding > 0
        ? leftPadding
        : (showRail ? railWidth : 0.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ask Gita AI'),
        centerTitle: true,
        backgroundColor:
            theme.appBarTheme.backgroundColor?.withOpacity(0.9) ??
            theme.colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7), // Glassy App Bar
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          // Credit Balance Indicator
          Consumer<CreditProvider>(
            builder: (context, credits, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${credits.balance}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          FontSizeControl(
            currentSize: context.watch<SettingsProvider>().fontSize,
            onSizeChanged: (newSize) =>
                context.read<SettingsProvider>().setFontSize(newSize),
            color: theme.appBarTheme.iconTheme?.color,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => provider.clearChat(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Gutter for Rail (if landscape or wide enough)
          if (effectiveLeftPadding > 0) SizedBox(width: effectiveLeftPadding),

          // Main Content Area
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Chat List
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          kToolbarHeight +
                              MediaQuery.of(context).padding.top +
                              16,
                          16,
                          16,
                        ),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final msg = provider.messages[index];
                          return _ChatBubble(message: msg);
                        },
                      ),
                    ),

                    // ✨ AI Suggestions above Input Area
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: AiSuggestionChips(
                        isVisible:
                            _isInputFocused && _textController.text.isEmpty,
                        onSuggestionSelected: (question) {
                          _textController.text = question;
                          _sendMessage(question);
                          _inputFocusNode.unfocus();
                        },
                      ),
                    ),

                    // Input Area
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    focusNode:
                                        _inputFocusNode, // ✨ Attach focus node
                                    decoration: InputDecoration(
                                      hintText: 'Ask Krishna...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: theme.scaffoldBackgroundColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onSubmitted: (_) => _handleSend(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FloatingActionButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : _handleSend,
                                  mini: true,
                                  elevation: 0,
                                  child: provider.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI-generated response. May contain errors.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 10,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
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
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final theme = Theme.of(context);

    // Smart Parsing for [QUOTE] tag
    String displayText = message.text;
    String? shareableQuote;

    if (!isUser) {
      final quoteRegExp = RegExp(r'\[QUOTE\](.*?)\[/QUOTE\]', dotAll: true);
      final match = quoteRegExp.firstMatch(message.text);
      if (match != null) {
        shareableQuote = match.group(1)?.trim();
        // Remove the quote tag from the displayed text
        displayText = message.text.replaceAll(quoteRegExp, '').trim();
      } else {
        // Fallback: Use the first significant sentence
        final lines = message.text.split('\n');
        for (final line in lines) {
          if (line.trim().length > 20 && !line.startsWith('#')) {
            shareableQuote = line.trim();
            break;
          }
        }
        // Safety cap
        if (shareableQuote != null && shareableQuote.length > 150) {
          shareableQuote = shareableQuote.substring(0, 150) + '...';
        }
      }
    }

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? theme.primaryColor : theme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isUser
                  ? const Radius.circular(16)
                  : const Radius.circular(4),
              bottomRight: isUser
                  ? const Radius.circular(4)
                  : const Radius.circular(16),
            ),
            border: isUser
                ? null
                : Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayText.isNotEmpty)
                MarkdownBody(
                  data: displayText,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                      fontSize: context.watch<SettingsProvider>().fontSize,
                    ),
                    listBullet: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                      fontSize: context.watch<SettingsProvider>().fontSize,
                    ),
                  ),
                ),
              if (message.isStreaming && message.text.isEmpty)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (!isUser &&
                  message.text.isNotEmpty &&
                  !message.isStreaming) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Advice',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Guidance copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.onSurface.withOpacity(
                        0.7,
                      ), // High contrast
                    ),
                    Builder(
                      builder: (iconContext) {
                        return IconButton(
                          icon: const Icon(Icons.share_rounded, size: 18),
                          tooltip: 'Share Advice',
                          onPressed: () {
                            final footer =
                                '\n\n---\nShared from Shrimad Bhagavad Gita app:\nhttps://digish.github.io/project/index.html#bhagvadgita';

                            // Calculate share position origin for iPad
                            final box =
                                iconContext.findRenderObject() as RenderBox?;
                            final sharePositionOrigin = box != null
                                ? box.localToGlobal(Offset.zero) & box.size
                                : null;

                            Share.share(
                              displayText + footer,
                              sharePositionOrigin: sharePositionOrigin,
                            );
                          },
                          visualDensity: VisualDensity.compact,
                          color: theme.colorScheme.onSurface.withOpacity(
                            0.7,
                          ), // High contrast
                        );
                      },
                    ),
                    // Create Image Button (Prominent & Animated)
                    if (!isUser) ...[
                      const SizedBox(width: 8),
                      _AnimatedGradientButton(
                        onPressed: () {
                          if (shareableQuote != null) {
                            context.push(
                              AppRoutes.imageCreator,
                              extra: {
                                'text': shareableQuote,
                                'source': 'Ask Gita AI',
                              },
                            );
                          }
                        },
                        icon: Icons.brush,
                        label: 'Create Art',
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),

        // Show References (Shloka Cards) for AI messages
        if (!isUser &&
            message.references != null &&
            message.references!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relevant Verses:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(
                      0.9,
                    ), // High contrast
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (message.references!.length > 1)
                  TextButton.icon(
                    onPressed: () {
                      final ids = message.references!
                          .map((r) => '${r.chapterNo}.${r.shlokNo}')
                          .join(',');
                      context.push('/shloka-list/ids:$ids');
                    },
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220, // Increased height to prevent truncation
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: message.references!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shloka = message.references![index];
                return SizedBox(
                  width: 300,
                  child: _ChatShlokaCard(shloka: shloka),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChatShlokaCard extends StatelessWidget {
  final ShlokaResult shloka;

  const _ChatShlokaCard({required this.shloka});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use gold/orange for relevant verses to make them special
    final accentColor = isDark ? const Color(0xFFFFD700) : theme.primaryColor;

    // ✨ Format Shloka Text: Replace * and <C> with newlines
    final formattedShloka = shloka.shlok
        .replaceAll(RegExp(r'<[Cc]>'), '\n')
        .replaceAll('*', '\n')
        .replaceAll(
          RegExp(r'॥\s?[०-९\-]+॥'),
          '॥',
        ) // Clean up shloka numbers if any
        .trim();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [Colors.white, theme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(isDark ? 0.4 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push(
              AppRoutes.shlokaDetail.replaceFirst(':id', shloka.id.toString()),
            );
          },
          child: Stack(
            children: [
              // Decorative Background Lotus
              Positioned(
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: isDark ? 0.08 : 0.05,
                  child: Image.asset(
                    'assets/images/lotus_white22.png',
                    width: 120,
                    color: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Chapter ${shloka.chapterNo} • Verse ${shloka.shlokNo}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Text(
                            formattedShloka,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.4, // Slightly tighter to fit 2-3 lines
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoSerif',
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : const Color(0xFF2D2D2D),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 10, // Allow even more lines
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tap to read meaning',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white38 : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: accentColor.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF9800), // Orange
                Color(0xFFFF5722), // Deep Orange
                Color(0xFFE91E63), // Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    // Adding a subtle shine effect using ShaderMask
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: const [
                            Colors.white,
                            Color(0xFFFFE0B2), // Light Orange/Gold tint
                            Colors.white,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment(-1.0 + (_controller.value * 2), 0.0),
                          end: Alignment(0.0 + (_controller.value * 2), 0.0),
                          tileMode: TileMode.clamp,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
