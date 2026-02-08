import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/image_generator_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/lotus.dart';

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
  bool _showGlass = true;
  bool _showPatterns = true;
  bool _isSerif = true;
  List<Color> _currentGradient = [
    const Color(0xFFFF9933),
    const Color(0xFFFFCC33),
  ];

  final List<List<Color>> _divineGradients = [
    [const Color(0xFFFF9933), const Color(0xFFFFCC33)], // Royal Saffron
    [const Color(0xFFE6BE8A), const Color(0xFFB8860B)], // Divine Gold
    [const Color(0xFF047BC0), const Color(0xFF00BFFF)], // Krishna Blue
    [const Color(0xFF4A148C), const Color(0xFF9C27B0)], // Royal Wisdom (Purple)
    [const Color(0xFF1B5E20), const Color(0xFF43A047)], // Vaikuntha Green
    [const Color(0xFFB71C1C), const Color(0xFFEF5350)], // Bhakti Red
    [const Color(0xFF0F2027), const Color(0xFF203A43)], // Midnight Meditation
    [Colors.black, Colors.grey.shade900], // Cosmic Void
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
        width: maxSize,
        height: maxSize,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Decorative Patterns (Lotus corners)
            if (_showPatterns) ...[
              Positioned(
                top: -30,
                left: -30,
                child: Opacity(
                  opacity: 0.15,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: const Lotus(size: 150),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: -30,
                child: Opacity(
                  opacity: 0.15,
                  child: Transform.rotate(
                    angle: -0.5,
                    child: const Lotus(size: 150),
                  ),
                ),
              ),
            ],

            // 2. Fundamental Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _showGlass ? 10 : 0,
                      sigmaY: _showGlass ? 10 : 0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _showGlass
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: _showGlass
                            ? Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              )
                            : null,
                      ),
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
                            style: _isSerif
                                ? GoogleFonts.notoSerif(
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
                                  )
                                : GoogleFonts.outfit(
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
                              style: _isSerif
                                  ? GoogleFonts.notoSerif(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontStyle: FontStyle.italic,
                                    )
                                  : GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontStyle: FontStyle.italic,
                                    ),
                            ),
                          ],
                          if (widget.source != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.source!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Gita App Island (Bottom Gravity Center)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icon/icon_square.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // App Name
                      const Text(
                        'Shrimad Bhagavad Gita',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // QR Code (Bottom Right Gravity)
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data:
                      'https://digish.github.io/project/index.html#bhagvadgita',
                  version: QrVersions.auto,
                  size: 40.0, // Slightly smaller QR
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
              'Customize Wisdom',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 1. Text Options Group
          _buildControlGroup('Typography', [
            // Font Selection Toggle
            Row(
              children: [
                const Icon(
                  Icons.font_download_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Style', style: TextStyle(color: Colors.white70)),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Serif'),
                      icon: Icon(Icons.menu_book),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Sans'),
                      icon: Icon(Icons.art_track),
                    ),
                  ],
                  selected: {_isSerif},
                  onSelectionChanged: (val) =>
                      setState(() => _isSerif = val.first),
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.grey[850],
                    selectedBackgroundColor: Colors.orange.withOpacity(0.2),
                    selectedForegroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Font Size Slider
            Row(
              children: [
                const Icon(Icons.format_size, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
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
            if (widget.translation != null &&
                widget.translation!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Show Translation',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  Switch(
                    value: _showTranslation,
                    onChanged: (val) => setState(() => _showTranslation = val),
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ],
          ]),

          // 2. Theme & Effects Group
          _buildControlGroup('Aesthetics', [
            // Glass & Patterns Row
            Row(
              children: [
                _buildAestheticToggle(
                  icon: Icons.blur_on,
                  label: 'Glass',
                  value: _showGlass,
                  onChanged: (val) => setState(() => _showGlass = val),
                ),
                const SizedBox(width: 12),
                _buildAestheticToggle(
                  icon: Icons.eco_outlined,
                  label: 'Patterns',
                  value: _showPatterns,
                  onChanged: (val) => setState(() => _showPatterns = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Gradient Selector
            Text(
              'Color Theme',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
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
                      width: isSelected ? 40 : 32,
                      height: isSelected ? 40 : 32,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ]),

          const SizedBox(height: 24),

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
                  icon: const Icon(Icons.share_rounded),
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

  Widget _buildControlGroup(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAestheticToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: value ? Colors.orange.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: value ? Colors.orange : Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: value ? Colors.orange : Colors.white70,
                  fontSize: 12,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
