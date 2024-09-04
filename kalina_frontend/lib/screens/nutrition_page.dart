import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import './calendar_page.dart';
import './settings_page.dart';
import './eating/add_meal_page.dart';
import '../entity/dish.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entity/custom_appointment.dart';
import '../entity/eating.dart';
import '../entity/exercise.dart';
import '../entity/sets.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  _NutritionPageState createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  // Пример дневных норм
  final double dailyProteins = globals.proteins.toDouble();
  final double dailyFats = globals.fats.toDouble();
  final double dailyCarbs = globals.carbs.toDouble();
  final double dailyCalories =
      (globals.proteins.toDouble() + globals.carbs.toDouble()) * 4 +
          globals.fats.toDouble() * 9;

  @override
  void initState() {
    super.initState();
    if (!globals.isFetching) {
      _fetchInitialData();
      globals.isFetching = true;
    }
  }

  Future<void> _fetchAppointments() async {
    final response = await http.post(
      Uri.parse('${globals.addr}appointments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': globals.userId,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 200) {
      if (jsonDecode(response.body) != null) {
        List<dynamic> apointmentsJson = jsonDecode(response.body);

        globals.customAppointments = apointmentsJson
            .map((json) =>
                CustomAppointment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      setState(() {
        globals.loaded++;
      });
    }
  }

  Future<void> _fetchInitialData() async {
    final response = await http.post(
      Uri.parse('${globals.addr}get_lists'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    print(response.body.toString());

    if (response.statusCode == 200) {
      // Декодируем ответ, чтобы получить user_id
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['available_dishes'] != null ||
          responseData['available_exercises'] != null) {
        // Преобразуем JSON в объекты
        List<dynamic> dishesJson =
            responseData['available_dishes'] as List<dynamic>;
        globals.availableDishes = dishesJson
            .map((json) => Dish.fromJson(json as Map<String, dynamic>))
            .toList();
        // Преобразуем JSON в список строк (имена упражнений)
        List<dynamic> exercisesJson =
            responseData['available_exercises'] as List<dynamic>;
        globals.availableExercises = exercisesJson
            .map((json) =>
                AvailableExercise.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      setState(() {
        globals.loaded++;
      });
      _fetchAppointments();
      _fetchEating();
      _fetchExercises();
    }
  }

  Future<void> _fetchExercises() async {
    final response = await http.post(
      Uri.parse('${globals.addr}fetch_exercises'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': globals.userId,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);

      // Проверяем, что данные не пустые
      for (var exerciseData in responseData) {
        // Получаем идентификатор тренировки
        String trainingId = exerciseData['training'];
        Exercise exercise;
        if (exerciseData['sets'] != null) {
          // Создаем объект упражнения
          exercise = Exercise(
            id: exerciseData['id'],
            name: exerciseData[
                'exercise'], // Предполагается, что сервер возвращает название упражнения
            sets: (exerciseData['sets'] as List<dynamic>)
                .map((set) => SetExercise(
                      id: set['id'],
                      weight: set['weight'].toDouble(),
                      reps: set['reps'],
                    ))
                .toList(),
          );
        } else {
          // Создаем объект упражнения без наборов
          exercise = Exercise(
            id: exerciseData['id'],
            name: exerciseData['exercise'],
            sets: [],
          );
        }

        // Добавляем упражнение в карту по идентификатору тренировки
        if (globals.exercisesMap.containsKey(trainingId)) {
          globals.exercisesMap[trainingId]!.add(exercise);
        } else {
          globals.exercisesMap[trainingId] = [exercise];
        }
      }
      setState(() {
        globals.loaded++;
      });
    } else {
      print('Failed to load exercises');
    }
  }

  Future<void> _fetchEating() async {
    final response = await http.post(
      Uri.parse('${globals.addr}fetch_eatings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': globals.userId,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 200) {
      if (jsonDecode(response.body) != null) {
        final List<dynamic> responseData = jsonDecode(response.body);
        List<Eating> eatings = responseData
            .map((json) => Eating.fromJson(json as Map<String, dynamic>))
            .toList();
        for (Eating eating in eatings) {
          DateTime date =
              DateTime(eating.date.year, eating.date.month, eating.date.day);
          if (globals.dishes[date] == null) {
            globals.dishes[date] = [];
          }
          globals.dishes[date]?.add(eating);
        }
      }
      setState(() {
        globals.loaded++;
      });
    }
  }

  // Метод для выбора даты с помощью календаря
  Future<void> _selectDate(BuildContext context) async {
    DateTime newDate = selectedDate;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите дату'),
          content: SizedBox(
            height: 300, // Ограничиваем высоту контейнера с календарем
            width: 300, // Ограничиваем ширину контейнера с календарем
            child: SfDateRangePicker(
              initialSelectedDate: selectedDate,
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                setState(() {
                  newDate = args.value;
                });
              },
              selectionMode: DateRangePickerSelectionMode.single,
              backgroundColor: Colors.white, // Устанавливаем белый цвет фона
              monthViewSettings: const DateRangePickerMonthViewSettings(
                firstDayOfWeek: 1, // Неделя начинается с понедельника
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем диалог без сохранения
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Устанавливаем выбранную дату
                  selectedDate = newDate;
                });
                Navigator.pop(context); // Закрываем диалог с сохранением
              },
              child: const Text('Ок'),
            ),
          ],
        );
      },
    );
  }

  // Метод для расчета потребленных БЖУ и калорий
  Map<String, double> _calculateConsumedMacros() {
    double totalProteins = 0.0;
    double totalFats = 0.0;
    double totalCarbs = 0.0;
    double totalCalories = 0.0;

    if (globals.dishes[selectedDate] != null &&
        globals.dishes[selectedDate]!.isNotEmpty) {
      for (var dishEntry in globals.dishes[selectedDate]!) {
        Dish dish = dishEntry.dish;
        int weight = dishEntry.weight;

        totalProteins += dish.proteins * weight / 100;
        totalFats += dish.fats * weight / 100;
        totalCarbs += dish.carbs * weight / 100;
      }

      totalCalories = (totalProteins + totalCarbs) * 4 + totalFats * 9;
    }

    return {
      'Белки': totalProteins,
      'Жиры': totalFats,
      'Углеводы': totalCarbs,
      'Калории': totalCalories,
    };
  }

  Future<void> _changeEating(int id, int weight, int index) async {
    final response = await http.post(
      Uri.parse('${globals.addr}change_eating'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'weight': weight}),
    );
    print(id);
    print(response.body.toString());

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Произошла ошибка при изменении пробежки')),
      );
    } else {
      setState(() {
        globals.dishes[selectedDate]![index].weight = weight;
      });
    }
  }

  // Метод для редактирования или удаления блюда
  Future<void> _showEditOrDeleteDialog(
      BuildContext context, Dish dish, int weight, int index) async {
    int updatedWeight = weight;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Редактировать блюдо'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dish.name),
              TextField(
                decoration: const InputDecoration(labelText: 'Вес (в граммах)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  updatedWeight = int.tryParse(value) ?? weight;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Удалить'),
              onPressed: () {
                _deleteEatingFromDB(
                    globals.dishes[selectedDate]![index].id, index);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Сохранить'),
              onPressed: () {
                _changeEating(globals.dishes[selectedDate]![index].id,
                    updatedWeight, index);
                // setState(() {
                //   globals.dishes[selectedDate]![index].weight = updatedWeight;
                // });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEatingFromDB(int id, int index) async {
    final response = await http.post(
      Uri.parse('${globals.addr}delete_eating'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
      }),
    );

    print(response.body.toString());

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Произошла ошибка при удалении пробежки')),
      );
    } else {
      setState(() {
        globals.dishes[selectedDate]!.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final consumedMacros = _calculateConsumedMacros();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Питание'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context), // Открытие календаря
          ),
        ],
      ),
      body: globals.loaded != 4
          ? Center(
              child:
                  CircularProgressIndicator()) // Показываем индикатор загрузки
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о потребленных БЖУ и калориях
                  Text(
                    'Дата: ${selectedDate.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Полоска калорий
                  _buildProgressBar('Калории', consumedMacros['Калории']!,
                      dailyCalories, Colors.red),
                  const SizedBox(height: 8),

                  // Полоска белков
                  _buildProgressBar('Белки', consumedMacros['Белки']!,
                      dailyProteins, Colors.blue),
                  const SizedBox(height: 8),

                  // Полоска жиров
                  _buildProgressBar(
                      'Жиры', consumedMacros['Жиры']!, dailyFats, Colors.green),
                  const SizedBox(height: 8),

                  // Полоска углеводов
                  _buildProgressBar('Углеводы', consumedMacros['Углеводы']!,
                      dailyCarbs, Colors.orange),
                  const SizedBox(height: 24),
                  // Список блюд
                  Expanded(
                    child: ListView.builder(
                      itemCount: globals.dishes[selectedDate]?.length ?? 0,
                      itemBuilder: (context, index) {
                        Dish dish = globals.dishes[selectedDate]![index].dish;
                        int weight =
                            globals.dishes[selectedDate]![index].weight;
                        return ListTile(
                          title: Text(dish.name),
                          subtitle: Text(
                              'Белки: ${(dish.proteins * weight / 100).toStringAsFixed(0)}, Жиры: ${(dish.fats * weight / 100).toStringAsFixed(0)}, Углеводы: ${(dish.carbs * weight / 100).toStringAsFixed(0)}, Калории: ${((dish.proteins * weight * 4 + dish.carbs * weight * 4 + dish.fats * weight * 9) / 100).toStringAsFixed(0)} ккал'),
                          onTap: () {
                            _showEditOrDeleteDialog(
                                context, dish, weight, index);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddMealPage(selectedDate: selectedDate)),
          ).then((result) {
            setState(() {});
          });
        }, // Обработка нажатия на кнопку
        tooltip: 'Добавить блюдо', // Подсказка при наведении на кнопку
        child: const Icon(Icons.add), // Иконка кнопки
      ),
      // Панель навигации
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Индекс текущей страницы (еда)
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    CalendarPage(),
                transitionDuration: Duration.zero, // Убирает анимацию перехода
                reverseTransitionDuration:
                    Duration.zero, // Убирает анимацию возврата
              ),
            );
          } else if (index == 1) {
            // Остаемся на текущей странице
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    const SettingsPage(),
                transitionDuration: Duration.zero, // Убирает анимацию перехода
                reverseTransitionDuration:
                    Duration.zero, // Убирает анимацию возврата
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Тренировки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Еда',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      String label, double consumed, double daily, Color color) {
    final progress = (consumed / daily)
        .clamp(0.0, 1.0); // Ограничиваем значение в пределах 0.0 - 1.0
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${consumed.toInt()} / ${daily.toInt()}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: color,
          minHeight: 20,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}
