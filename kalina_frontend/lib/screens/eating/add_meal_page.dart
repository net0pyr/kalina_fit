import 'package:flutter/material.dart';
import '../../entity/eating.dart';
import '../../entity/dish.dart';
import '../../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AddMealPage extends StatefulWidget {
  final DateTime selectedDate;

  const AddMealPage({super.key, required this.selectedDate});

  @override
  _AddMealPageState createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  List<Dish> filteredDishes = [];
  Dish? selectedDish;
  int weight = 100;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredDishes = globals.availableDishes;
    searchController.addListener(_filterDishes);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterDishes() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredDishes = globals.availableDishes
          .where((dish) => dish.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addDishToDishes() {
    if (selectedDish != null) {
      _addEating(widget.selectedDate, weight, selectedDish!);
      Navigator.pop(
        context,
      );
      // Navigator.pop(context);
    }
  }

  Future<void> _addEating(DateTime date, int weight, Dish dish) async {
    DateTime dateEating = DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );

    Eating eating = Eating(date: dateEating, weight: weight, dish: dish, id: 0);
    if (globals.dishes[date] == null) globals.dishes[date] = [];
    globals.dishes[date]?.add(eating);
    int index = globals.dishes[date]!.indexOf(eating);

    final response = await http.post(
      Uri.parse('${globals.addr}add_eating'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': globals.userId,
        'date': dateEating.toIso8601String(),
        'weight': weight,
        'dish': dish.id,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 201) {
      // Декодируем ответ, чтобы получить id
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      //setState(() {
      // if (globals.dishes[date] == null) globals.dishes[date] = [];
      // globals.dishes[date]?.add(Eating(
      //     date: dateEating,
      //     weight: weight,
      //     dish: dish,
      //     id: responseData['id']));
      globals.dishes[date]?[index].id = responseData['id'];
      //});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при добавлении блюда')),
      );
    }
  }

  Future<void> _addToDB(int proteins, int fats, int carbs, String name) async {
    final response = await http.post(
      Uri.parse('${globals.addr}add_dish'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'name': name,
        'id': 0,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 201) {
      // Декодируем ответ, чтобы получить user_id
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Сохраняем user в глобальную переменную
      globals.availableDishes.add(
        Dish(
          name: name,
          proteins: proteins.toDouble(),
          fats: fats.toDouble(),
          carbs: carbs.toDouble(),
          id: responseData['dish_id'],
        ),
      );
      filteredDishes = globals.availableDishes;
      _filterDishes();
      //print(globals.userId); // Выводим user_id на экран
      // Переходим на страницу питания
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при добавлении блюда')),
      );
    }
  }

  void _showAddDishDialog() {
    String name = '';
    double proteins = 0.0;
    double fats = 0.0;
    double carbs = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить новое блюдо'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration:
                      const InputDecoration(labelText: 'Название блюда'),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Белки (г)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    proteins = double.tryParse(value) ?? 0.0;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Жиры (г)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    fats = double.tryParse(value) ?? 0.0;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Углеводы (г)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    carbs = double.tryParse(value) ?? 0.0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    _addToDB(
                        proteins.toInt(), fats.toInt(), carbs.toInt(), name);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить прием пищи'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск блюда',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDishes.length,
                itemBuilder: (context, index) {
                  Dish dish = filteredDishes[index];
                  return ListTile(
                    title: Text(dish.name),
                    subtitle: Text(
                      'Белки: ${dish.proteins}, Жиры: ${dish.fats}, Углеводы: ${dish.carbs}',
                    ),
                    onTap: () {
                      setState(() {
                        selectedDish = dish;
                      });
                    },
                    selected: selectedDish == dish,
                    selectedTileColor: Colors.grey[300],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Вес (в граммах)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  weight = int.tryParse(value) ?? 100;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _addDishToDishes,
                  child: const Text('Добавить'),
                ),
                ElevatedButton(
                  onPressed: _showAddDishDialog,
                  child: const Text('Добавить новое блюдо'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
