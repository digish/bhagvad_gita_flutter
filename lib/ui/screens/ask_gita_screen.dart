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
import '../widgets/shloka_result_card.dart';
import '../widgets/font_size_control.dart';
import '../../navigation/app_router.dart';

class AskGitaScreen extends StatefulWidget {
  final String? initialQuery;
  const AskGitaScreen({super.key, this.initialQuery});

  @override
  State<AskGitaScreen> createState() => _AskGitaScreenState();
}

class _AskGitaScreenState extends State<AskGitaScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
      _provider?.addListener(_scrollToBottom);

      // Handle initial query if provided
      if (widget.initialQuery != null && !_hasSentInitialQuery) {
        _hasSentInitialQuery = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _provider?.sendMessage(widget.initialQuery!);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_scrollToBottom);
    _controller.dispose();
    _scrollController.dispose();
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
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    final credits = context.read<CreditProvider>();
    final settings = context.read<SettingsProvider>();

    // Skip credit check if user has their own API Key
    final hasCustomKey =
        settings.customAiApiKey != null && settings.customAiApiKey!.isNotEmpty;

    if (!hasCustomKey && !credits.hasCredit()) {
      _showLowBalanceDialog();
      return;
    }

    try {
      if (!hasCustomKey) {
        await credits.consumeCredit();
      }
      if (mounted) {
        context.read<AskGitaProvider>().sendMessage(text);
        _controller.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
            label: const Text('Watch Ad (+5 Credits)'),
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
        context.read<CreditProvider>().addCredits(5);

        // Also show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blessings Received! +5 Credits Added.'),
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
    // Use AppColors/AppTheme if available, else fallback

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Gita AI'),
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
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final msg = provider.messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask Krishna...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: provider.isLoading ? null : _handleSend,
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
                      color: theme.primaryColor.withOpacity(0.7),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      tooltip: 'Share Advice',
                      onPressed: () {
                        final footer =
                            '\n\n---\nShared from Shrimad Bhagavad Gita app:\nhttps://digish.github.io/project/index.html#bhagvadgita';
                        Share.share(displayText + footer);
                      },
                      visualDensity: VisualDensity.compact,
                      color: theme.primaryColor.withOpacity(0.7),
                    ),
                    // Create Image Button (Only for AI responses)
                    if (!isUser)
                      IconButton(
                        icon: const Icon(Icons.image_outlined, size: 18),
                        tooltip: 'Share as Quote',
                        onPressed: () {
                          if (shareableQuote != null) {
                            context.push(
                              AppRoutes.imageCreator,
                              extra: {
                                'text': shareableQuote, // Use the smart quote
                                'source': 'Ask Gita AI', // Dynamic source
                              },
                            );
                          }
                        },
                        visualDensity: VisualDensity.compact,
                        color: theme.primaryColor.withOpacity(0.7),
                      ),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relevant Verses:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
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
                    label: const Text('View All in List'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 205, // Increased height for safe display
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: message.references!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (context, index) {
                final shloka = message.references![index];
                return SizedBox(
                  width: 280, // Slightly wider for card content
                  child: ShlokaResultCard(
                    shloka: shloka,
                    searchQuery: '', // No highlight needed here
                    isCompact: true,
                  ),
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
