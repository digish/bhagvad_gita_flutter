class StaticData {
  static const List<String> geetaAdhyay = [
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
    "मोक्षसंन्यासयोगः"
  ];

  static String getQueryTitle(String query) {
    final index = int.tryParse(query);
    if (index != null && index >= 1 && index <= geetaAdhyay.length) {
      final title = geetaAdhyay[index - 1];
      return '$index – $title';
    }
    return '"$query"';
  }

  static String getChapterTitle(int no) {
    return geetaAdhyay[no];
  }
}