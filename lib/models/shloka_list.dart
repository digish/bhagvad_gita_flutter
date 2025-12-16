class ShlokaList {
  final int id;
  final String name;

  ShlokaList({required this.id, required this.name});

  factory ShlokaList.fromMap(Map<String, dynamic> map) {
    return ShlokaList(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
