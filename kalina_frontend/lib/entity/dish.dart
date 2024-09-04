class Dish {
  final int id;
  final String name;
  final double proteins;
  final double fats;
  final double carbs;

  Dish({
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.name,
    required this.id,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as int,
      name: json['name'] as String,
      proteins: (json['proteins'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }
}
