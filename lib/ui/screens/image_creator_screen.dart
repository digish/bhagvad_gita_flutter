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
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          if (isLandscape) {
            // Landscape Layout (Row)
            return SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Preview Area (Left - Expanded)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildPreviewCard(constraints),
                      ),
                    ),
                  ),

                  // 2. Controls Area (Right - Fixed Width)
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border(
                        left: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: _buildControls(isLandscape: true)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Portrait Layout (Column)
            return Column(
              children: [
                // 1. Preview Area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPreviewCard(constraints),
                    ),
                  ),
                ),
                // 2. Controls Area
                Container(
                  color: Colors.grey[900],
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: SafeArea(top: false, child: _buildControls()),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPreviewCard(BoxConstraints constraints) {
    // Calculate max size for square-ish card
    final isLandscape = constraints.maxWidth > constraints.maxHeight;
    final maxSize = isLandscape
        ? constraints.maxHeight - 48
        : constraints.maxWidth - 32;

    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        constraints: BoxConstraints(minHeight: maxSize, maxWidth: maxSize),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _currentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets
            .zero, // Remove padding from container to allow full stack
        child: Stack(
          children: [
            // Main Content Centered
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                    if (_showTranslation && widget.translation != null) ...[
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
                    const SizedBox(height: 40), // Spacer for branding
                    // Promo Footer "Island" (Just Branding)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Icon
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/icon/icon_square.png',
                                width: 24, // Smaller icon
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // App Name & Tagline
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shrimad Bhagavad Gita',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Search within',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // QR Code at Bottom Left
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data:
                      'https://digish.github.io/project/index.html#bhagvadgita',
                  version: QrVersions.auto,
                  size: 48.0,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls({bool isLandscape = false}) {
    // Shared controls widget
    return SingleChildScrollView(
      padding: isLandscape ? const EdgeInsets.all(24) : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLandscape) ...[
            Text(
              'Customize',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Font Size & Toggle Row
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
              if (widget.translation != null &&
                  widget.translation!.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      setState(() => _showTranslation = !_showTranslation),
                  style: IconButton.styleFrom(
                    backgroundColor: _showTranslation
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.transparent,
                    foregroundColor: _showTranslation
                        ? Colors.orange
                        : Colors.white54,
                    side: _showTranslation
                        ? const BorderSide(color: Colors.orange, width: 1)
                        : null,
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  tooltip: 'Show Meaning',
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Gradient Selector
          Text(
            'Theme',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _divineGradients.length,
              itemBuilder: (context, index) {
                final gradient = _divineGradients[index];
                final isSelected = _currentGradient == gradient;
                return GestureDetector(
                  onTap: () => setState(() => _currentGradient = gradient),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    margin: const EdgeInsets.only(right: 12, top: 5, bottom: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gradient.first.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Share Button
          SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (btnContext) {
                return FilledButton.icon(
                  onPressed: () async {
                    final box = btnContext.findRenderObject() as RenderBox?;
                    final sharePositionOrigin = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;

                    final bytes = await ImageGeneratorService.captureWidget(
                      _globalKey,
                    );
                    if (bytes != null && context.mounted) {
                      await ImageGeneratorService.shareImage(
                        bytes: bytes,
                        text:
                            'Found this wisdom on Shrimad Bhagavad Gita AI app! 🕉️\n\nDownload here: https://digish.github.io/project/index.html#bhagvadgita',
                        sharePositionOrigin: sharePositionOrigin,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Colors.orange.withOpacity(0.4),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text(
                    'Share Wisdom',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
