import 'package:flutter/material.dart';

class SneakyEmblem extends StatelessWidget {
  final String? speaker;

  const SneakyEmblem({super.key, required this.speaker});

  String? getEmblemAsset(String? speaker) {
    switch (speaker?.toLowerCase()) {
      case 'श्री भगवान':
        return 'assets/emblems/krishna.png';
      case 'अर्जुन':
        return 'assets/emblems/arjun.png';
      case 'संजय':
        return 'assets/emblems/sanjay.png';
      case 'धृतराष्ट्र':
        return 'assets/emblems/dhrutrashtra.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emblemPath = getEmblemAsset(speaker);
    if (emblemPath == null) return const SizedBox.shrink();

    return Positioned(
      top: -50, // Sneaks out above the card
      left: 0,
      right: 10, // Center horizontally
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color.fromARGB(0, 255, 224, 130), width: 1),
            boxShadow: [
              /*
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),*/
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              emblemPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}