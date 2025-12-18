import '../models/shloka_list.dart';

class PredefinedListsData {
  static const List<Map<String, dynamic>> _data = [
    {
      'id': -11,
      'name': 'Assurance of Divine Care',
      'shlokas': [
        '9.22',
        '9.31',
        '4.8',
        '9.18',
        '9.32',
        '2.12',
        '12.7',
        '18.66',
        '2.47',
        '2.48',
      ],
    },
    {
      'id': -2,
      'name': 'For Students',
      'shlokas': ['2.7', '2.40', '2.47', '2.48', '6.34', '6.35', '3.35'],
    },
    {
      'id': -3,
      'name': 'For Motivation',
      'shlokas': ['6.5', '2.40', '2.47', '2.48', '6.35', '18.73'],
    },
    {
      'id': -4,
      'name': 'For Excelling at Work',
      'shlokas': [
        '6.5',
        '3.5',
        '2.47',
        '2.48',
        '2.40',
        '2.50',
        '6.35',
        '4.24',
        '18.73',
      ],
    },
    {
      'id': -5,
      'name': 'When in Grief',
      'shlokas': [
        '2.40',
        '9.31',
        '9.22',
        '12.7',
        '2.12',
        '2.11',
        '2.48',
        '18.66',
      ],
    },
  ];

  static List<ShlokaList> get lists {
    return _data
        .map((d) => ShlokaList(id: d['id'] as int, name: d['name'] as String))
        .toList();
  }

  static List<String> getShlokasForList(int id) {
    final list = _data.firstWhere((d) => d['id'] == id, orElse: () => {});
    if (list.isNotEmpty) {
      return (list['shlokas'] as List<dynamic>).cast<String>();
    }
    return [];
  }
}
