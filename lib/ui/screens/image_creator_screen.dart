import 'package:flutter/material.dart';
import '../../services/image_generator_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ImageCreatorScreen extends StatefulWidget {
  final String text;
  final String? translation;
  final String? source;

  const ImageCreatorScreen({
    super.key,
    required this.text,
    this.translation,
    this.source,
  });

  @override
  State<ImageCreatorScreen> createState() => _ImageCreatorScreenState();
}

class _ImageCreatorScreenState extends State<ImageCreatorScreen> {
  // State for controls
  double _fontSize = 24.0;
  bool _showTranslation = true;
  List<Color> _currentGradient = [Colors.deepOrange, Colors.orangeAccent];

  final List<List<Color>> _divineGradients = [
    [Colors.deepOrange, Colors.orangeAccent], // Saffron
    [const Color(0xFF047BC0), Colors.lightBlueAccent], // Krishna Blue
    [const Color(0xFFD81B60), Colors.pinkAccent], // Bhakti Pink
    [const Color(0xFF4A148C), Colors.purpleAccent], // Royal Wisdom
    [const Color(0xFF1B5E20), Colors.greenAccent], // Nature
    [Colors.black, Colors.grey.shade800], // Dark Void
  ];

  // Capture Key
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark studio background
      appBar: AppBar(
        title: const Text('Share the Wisdom'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final bytes = await ImageGeneratorService.captureWidget(
                _globalKey,
              );
              if (bytes != null && context.mounted) {
                await ImageGeneratorService.shareImage(
                  bytes: bytes,
                  text:
                      'Found this wisdom on Shrimad Bhagavad Gita AI app! 🕉️\n\nDownload here: https://digish.github.io/project/index.html#bhagvadgita',
                );
              }
            },
            icon: const Icon(Icons.share, color: Colors.orange),
            label: const Text(
              'Share',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Preview Area (Expanded)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxWidth - 32,
                          maxWidth: constraints.maxWidth - 32,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _currentGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                // Apply formatting to handle <c> and * as newlines
                                widget.text
                                    .replaceAll(
                                      RegExp(r'<c>', caseSensitive: false),
                                      '\n',
                                    )
                                    .replaceAll('*', '\n'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black45,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              if (_showTranslation &&
                                  widget.translation != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  widget.translation!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              if (widget.source != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.source!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 32),
                              // Promo Footer
                              const SizedBox(height: 32),
                              // Promo Footer "Island"
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(
                                    0.3,
                                  ), // Slight contrast
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min, // Hug content
                                  children: [
                                    // QR Code
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: QrImageView(
                                        data:
                                            'https://digish.github.io/project/index.html#bhagvadgita',
                                        version: QrVersions.auto,
                                        size:
                                            42.0, // Sized to match icon+text height roughly
                                        backgroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // App Icon
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.asset(
                                              'assets/icon/icon_square.png',
                                              width: 36,
                                              height: 36,
                                            ),
                                          ),
                                          // Glare Effect
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white.withOpacity(
                                                        0.3,
                                                      ),
                                                      Colors.white.withOpacity(
                                                        0.0,
                                                      ),
                                                      Colors.white.withOpacity(
                                                        0.0,
                                                      ),
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.4,
                                                      1.0,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // App Name & Tagline
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Shrimad Bhagavad Gita',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Search within',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
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
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Controls Area
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle Toggles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Translation'),
                      selected: _showTranslation,
                      onSelected: (val) =>
                          setState(() => _showTranslation = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Font Size Slider
                Row(
                  children: [
                    const Icon(Icons.text_fields, color: Colors.white54),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 14,
                        max: 48,
                        activeColor: Colors.orange,
                        onChanged: (val) => setState(() => _fontSize = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Gradient Selector
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _divineGradients.length,
                    itemBuilder: (context, index) {
                      final gradient = _divineGradients[index];
                      final isSelected = _currentGradient == gradient;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _currentGradient = gradient),
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
