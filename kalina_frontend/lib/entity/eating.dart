import './dish.dart';
import '../globals.dart';

class Eating {
  int id;
  final Dish dish;
  int weight;
  final DateTime date;

  Eating({
    required this.id,
    required this.dish,
    required this.weight,
    required this.date,
  });

  static Dish _getDishById(int id) {
    return availableDishes.firstWhere((dish) => dish.id == id);
  }

  factory Eating.fromJson(Map<String, dynamic> json) {
    return Eating(
      id: int.parse(json['id']),
      dish: _getDishById((json['dish'] as num).toInt()),
      weight: (json['weight'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
