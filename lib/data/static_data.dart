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

class StaticData {
  static const List<String> _geetaAdhyayDev = [
    "अर्जुनविषादयोगः",
    "साङ्ख्ययोगः",
    "कर्मयोगः",
    "ज्ञानकर्मसंन्यासयोगः",
    "कर्मसंन्यासयोगः",
    "आत्मसंयमयोगः",
    "ज्ञानविज्ञानयोगः",
    "अक्षरब्रह्मयोगः",
    "राजविद्याराजगुह्ययोगः",
    "विभूतियोगः",
    "विश्वरूपदर्शनयोगः",
    "भक्तियोगः",
    "क्षेत्रक्षेत्रज्ञविभागयोगः",
    "गुणत्रयविभागयोगः",
    "पुरुषोत्तमयोगः",
    "दैवासुरसम्पद्विभागयोगः",
    "श्रद्धात्रयविभागयोगः",
    "मोक्षसंन्यासयोगः",
  ];

  static const List<String> _geetaAdhyayEn = [
    "Arjuna Vishada Yoga",
    "Sankhya Yoga",
    "Karma Yoga",
    "Jnana Karma Sanyasa Yoga",
    "Karma Sanyasa Yoga",
    "Dhyana Yoga",
    "Jnana Vijnana Yoga",
    "Akshara Brahma Yoga",
    "Raja Vidya Raja Guhya Yoga",
    "Vibhuti Yoga",
    "Vishwaroopa Darshana Yoga",
    "Bhakti Yoga",
    "Kshetra Kshetrajna Vibhaga Yoga",
    "Gunatraya Vibhaga Yoga",
    "Purushottama Yoga",
    "Daivasura Sampad Vibhaga Yoga",
    "Shraddhatraya Vibhaga Yoga",
    "Moksha Sanyasa Yoga",
  ];

  // Note: For other scripts, we might need real transliteration.
  // Ideally this should come from a resourceful library or DB.
  // For now, falling back to Roman or Dev if list missing, or adding basic ones.
  // I will just implement mapping for supported scripts using online transliteration knowledge.

  static const List<String> _geetaAdhyayGu = [
    "અર્જુનવિષાદયોગ",
    "સાંખ્યયોગ",
    "કર્મયોગ",
    "જ્ઞાનકર્મસંન્યાસયોગ",
    "કર્મસંન્યાસયોગ",
    "આત્મસંયમયોગ",
    "જ્ઞાનવિજ્ઞાનયોગ",
    "અક્ષરબ્રહ્મયોગ",
    "રાજવિદ્યારાજગુહ્યયોગ",
    "વિભૂતિયોગ",
    "વિશ્વરૂપદર્શનયોગ",
    "ભક્તિયોગ",
    "ક્ષેત્રક્ષેત્રજ્ઞવિભાગયોગ",
    "ગુણત્રયવિભાગયોગ",
    "પુરુષોત્તમયોગ",
    "દૈવાસુરસમ્પદ્વિભાગયોગ",
    "શ્રદ્ધાત્રયવિભાગયોગ",
    "મોક્ષસંન્યાસયોગ",
  ];

  static const List<String> _geetaAdhyayTe = [
    "అర్జునవిషాదయోగము",
    "సాంఖ్యయోగము",
    "కర్మయోగము",
    "జ్ఞానకర్మసన్న్యాసయోగము",
    "కర్మసన్న్యాసయోగము",
    "ఆత్మసంయమయోగము",
    "జ్ఞానవిజ్ఞానయోగము",
    "అక్షరపరబ్రహ్మయోగము",
    "రాజవిద్యారాజగుహ్యయోగము",
    "విభూతియోగము",
    "విశ్వరూపసందర్శనయోగము",
    "భక్తియోగము",
    "క్షేత్రక్షేత్రజ్ఞవిభాగయోగము",
    "గుణత్రయవిభాగయోగము",
    "పురుషోత్తమప్రాప్తియోగము",
    "దైవాసురసంపద్విభాగయోగము",
    "శ్రద్ధాత్రయవిభాగయోగము",
    "మోక్షసన్న్యాసయోగము",
  ];

  static const List<String> _geetaAdhyayBn = [
    "অর্জুনবিষাদযোগ",
    "সাংখ্যযোগ",
    "কর্মযোগ",
    "জ্ঞানকর্মসন্ন্যাসযোগ",
    "কর্মসন্ন্যাসযোগ",
    "আত্মসংযমযোগ",
    "জ্ঞানবিজ্ঞানযোগ",
    "অক্ষরব্রহ্মযোগ",
    "রাজবিদ্যারাজগুহ্যযোগ",
    "বিভূতিযোগ",
    "বিশ্বরূপদর্শনযোগ",
    "ভক্তিযোগ",
    "ক্ষেত্রক্ষেত্রজ্ঞবিভাগযোগ",
    "গুণত্রয়বিভাগযোগ",
    "পুরুষোত্তমযোগ",
    "দৈবাসুরসম্পদবিভাগযোগ",
    "শ্রদ্ধাত্রয়বিভাগযোগ",
    "মোক্ষসন্ন্যাসযোগ",
  ];

  static const List<String> _geetaAdhyayTa = [
    "அர்ஜுன விஷாத யோகம்",
    "சாங்கிய யோகம்",
    "கர்ம யோகம்",
    "ஞான கர்ம சன்னியாச யோகம்",
    "கர்ம சன்னியாச யோகம்",
    "ஆத்ம சம்யம யோகம்",
    "ஞான விஞ்ஞான யோகம்",
    "அக்ஷர பிரம்ம யோகம்",
    "ராஜ வித்யா ராஜ குஹ்ய யோகம்",
    "விபூதி யோகம்",
    "விஸ்வரூப தர்சன யோகம்",
    "பக்தி யோகம்",
    "க்ஷேத்ர க்ஷேத்ரக்ஞ விபாக யோகம்",
    "குணத்ரய விபாக யோகம்",
    "புருஷோத்தம யோகம்",
    "தைவாசுர சம்பத் விபாக யோகம்",
    "ஸ்ரத்தாத்ரய விபாக யோகம்",
    "மோக்ஷ சன்னியாச யோகம்",
  ];

  static const List<String> _geetaAdhyayKn = [
    "ಅರ್ಜುನ ವಿಷಾದ ಯೋಗ",
    "ಸಾಂಖ್ಯ ಯೋಗ",
    "ಕರ್ಮ ಯೋಗ",
    "ಜ್ಞಾನ ಕರ್ಮ ಸಂನ್ಯಾಸ ಯೋಗ",
    "ಕರ್ಮ ಸಂನ್ಯಾಸ ಯೋಗ",
    "ಆತ್ಮ ಸಂಯಮ ಯೋಗ",
    "ಜ್ಞಾನ ವಿಜ್ಞಾನ ಯೋಗ",
    "ಅಕ್ಷರ ಬ್ರಹ್ಮ ಯೋಗ",
    "ರಾಜ ವಿದ್ಯಾ ರಾಜ ಗುಹ್ಯ ಯೋಗ",
    "ವಿಭೂತಿ ಯೋಗ",
    "ವಿಶ್ವರೂಪ ದರ್ಶನ ಯೋಗ",
    "ಭಕ್ತಿ ಯೋಗ",
    "ಕ್ಷೇತ್ರ ಕ್ಷೇತ್ರಜ್ಞ ವಿಭಾಗ ಯೋಗ",
    "ಗುಣತ್ರಯ ವಿಭಾಗ ಯೋಗ",
    "ಪುರುಷೋತ್ತಮ ಯೋಗ",
    "ದೈವಾಸುರ ಸಂಪದ್ವಿಭಾಗ ಯೋಗ",
    "ಶ್ರದ್ಧಾತ್ರಯ ವಿಭಾಗ ಯೋಗ",
    "ಮೋಕ್ಷ ಸಂನ್ಯಾಸ ಯೋಗ",
  ];

  // Placeholder for others to fallback to one of these or Roman/Dev if too complex to generate accurately without error.
  // Implementing known accurate ones.

  static const Map<String, List<String>> _localizedChapters = {
    'dev': _geetaAdhyayDev,
    'hi': _geetaAdhyayDev,
    'mr': _geetaAdhyayDev,
    'en': _geetaAdhyayEn,
    'ro': _geetaAdhyayEn,
    'gu': _geetaAdhyayGu,
    'te': _geetaAdhyayTe,
    'bn': _geetaAdhyayBn,
    'ta': _geetaAdhyayTa,
    'kn': _geetaAdhyayKn,
  };

  // Speaker Localization
  // Keys are lowercase partial matches or standardization of DB values.
  static const Map<String, Map<String, String>> _localizedSpeakers = {
    'dhritarashtra': {
      'dev': 'धृतराष्ट्र उवाच',
      'en': 'Dhritarashtra Uvaca',
      'gu': 'ધૃતરાષ્ટ્ર ઉવાચ',
      'te': 'ధృతరాష్ట్ర ఉవాచ',
      'bn': 'ধৃতরাষ্ট্র উবাচ',
      'ta': 'திருதராஷ்டிரன் உவாச', // Approx
      'kn': 'ಧೃತರಾಷ್ಟ್ರ ಉವಾಚ',
    },
    'sanjaya': {
      'dev': 'सञ्जय उवाच',
      'en': 'Sanjaya Uvaca',
      'gu': 'સંજય ઉવાચ',
      'te': 'సంజయ ఉవాచ',
      'bn': 'সঞ্জয় উবাচ',
      'ta': 'சஞ்சயன் உவாச',
      'kn': 'ಸಂಜಯ ಉವಾಚ',
    },
    'arjuna': {
      'dev': 'अर्जुन उवाच',
      'en': 'Arjuna Uvaca',
      'gu': 'અર્જુન ઉવાચ',
      'te': 'అర్జున ఉవాచ',
      'bn': 'অর্জুন উবাচ',
      'ta': 'அர்ஜுனன் உவாச',
      'kn': 'ಅರ್ಜುನ ಉವಾಚ',
    },
    'bhagavan': {
      'dev': 'श्रीभगवानुवाच',
      'en': 'Sri Bhagavan Uvaca',
      'gu': 'શ્રીભગવાનુવાચ',
      'te': 'శ్రీభగవానువాచ',
      'bn': 'শ্রীভগবানুবাচ',
      'ta': 'ஸ்ரீ பகவான் உவாச',
      'kn': 'ಶ್ರೀಭಗವಾನುವಾಚ',
    },
  };

  static String localizeSpeaker(String? speaker, String script) {
    if (speaker == null || speaker.isEmpty) return "";
    final lower = speaker.toLowerCase();

    String? key;
    if (lower.contains('dhritarashtra'))
      key = 'dhritarashtra';
    else if (lower.contains('sanjaya'))
      key = 'sanjaya';
    else if (lower.contains('arjun'))
      key = 'arjuna';
    else if (lower.contains('bhagavan') ||
        lower.contains('bhagwan') ||
        lower.contains('krishna'))
      key = 'bhagavan';

    if (key != null && _localizedSpeakers.containsKey(key)) {
      final map = _localizedSpeakers[key]!;
      // Fallback logic
      if (map.containsKey(script)) return map[script]!;
      if (script == 'hi' || script == 'mr') return map['dev']!;
      if (script == 'ro') return map['en']!;
    }

    return speaker; // Fallback to original if not found
  }

  static List<String> get geetaAdhyay => _geetaAdhyayDev; // Legacy getter

  static String getChapterName(int no, String script) {
    if (no < 1 || no > 18) return "";
    int index = no - 1;

    if (_localizedChapters.containsKey(script)) {
      final list = _localizedChapters[script]!;
      if (index < list.length) return list[index];
    }

    // Fallback logic
    if (script == 'kn') {
      // Kannada fallback logic or list if added later
      // For now fallback to Dev (often users can read) or Roman?
      // User requested "In respective Lipi".
      // If I don't have it, I should likely use Roman or Dev.
      // Let's stick to Dev as primary fallback for Indian langs or Roman for others.
    }

    return _geetaAdhyayDev[index];
  }

  static String getChapterLabel(String script) {
    if (script == 'en' || script == 'ro') return 'Chapter';
    if (script == 'gu') return 'અધ્યાય';
    return 'अध्याय';
  }

  static String localizeNumber(int number, String script) {
    if (script == 'en' || script == 'ro') return number.toString();

    final String numStr = number.toString();
    // 0x966 is Devanagari digit 0
    int offset = 0;
    if (script == 'dev' || script == 'hi' || script == 'mr')
      offset = 0x0966;
    else if (script == 'gu')
      offset = 0x0AE6;
    else if (script == 'te')
      offset = 0x0C66;
    else if (script == 'kn')
      offset = 0x0CE6;
    else if (script == 'ta')
      return number.toString(); // Tamil numerals obscure
    else if (script == 'bn')
      offset = 0x09E6;
    else
      return number.toString(); // Fallback

    final sb = StringBuffer();
    for (int i = 0; i < numStr.length; i++) {
      int digit = int.parse(numStr[i]);
      sb.writeCharCode(offset + digit);
    }
    return sb.toString();
  }

  static String getQueryTitle(String query) {
    final index = int.tryParse(query);
    if (index != null && index >= 1 && index <= geetaAdhyay.length) {
      final title = geetaAdhyay[index - 1];
      return '$index – $title';
    }
    return '"$query"';
  }

  static String getChapterTitle(int no) {
    return geetaAdhyay[no >= 1 ? no - 1 : 0];
  }
}
