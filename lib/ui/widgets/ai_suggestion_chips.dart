/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/

import 'package:flutter/material.dart';
import '../../data/ai_questions.dart';

class AiSuggestionChips extends StatefulWidget {
  final Function(String) onSuggestionSelected;
  final bool isVisible;
  final Axis direction;

  const AiSuggestionChips({
    super.key,
    required this.onSuggestionSelected,
    required this.isVisible,
    this.direction = Axis.horizontal,
  });

  @override
  State<AiSuggestionChips> createState() => _AiSuggestionChipsState();
}

class _AiSuggestionChipsState extends State<AiSuggestionChips> {
  late List<String> _suggestions;

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    setState(() {
      _suggestions = AiQuestionBank.getRandomSuggestions(count: 4);
    });
  }

  // Refresh when becoming visible
  @override
  void didUpdateWidget(covariant AiSuggestionChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _refreshSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.direction == Axis.vertical) {
      return _buildVerticalLayout(isDark);
    }
    return _buildHorizontalLayout(isDark);
  }

  Widget _buildVerticalLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0, top: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: isDark ? Colors.amberAccent : Colors.amber.shade800,
              ),
              const SizedBox(width: 8),
              Text(
                "ASK KRISHNA...",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _suggestions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final question = _suggestions[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onSuggestionSelected(question),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.03),
                              ]
                            : [Colors.white, Colors.white.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.deepOrange.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.amber
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final question = _suggestions[index];
          return ActionChip(
            label: Text(
              question,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            avatar: const Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.amber,
            ),
            onPressed: () => widget.onSuggestionSelected(question),
          );
        },
      ),
    );
  }
}
