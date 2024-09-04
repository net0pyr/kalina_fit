import 'package:flutter/material.dart';
import '../../entity/exercise.dart';
import '../../globals.dart'
    as globals; // Импортируем файл с глобальной переменной exercisesList
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Страница для выбора упражнения из списка или добавления нового упражнения
class ExerciseSelectionPage extends StatefulWidget {
  final void Function(String)
      onExerciseSelected; // Коллбэк, вызываемый при выборе упражнения

  const ExerciseSelectionPage({super.key, 
    required this.onExerciseSelected,
  });

  @override
  _ExerciseSelectionPageState createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  // Контроллеры для ввода текста в полях
  final TextEditingController _exerciseController =
      TextEditingController(); // Для ввода нового упражнения
  final TextEditingController _searchController =
      TextEditingController(); // Для поиска по списку упражнений

  // Список упражнений, отфильтрованный по поисковому запросу
  late List<AvailableExercise> _filteredExercises;

  @override
  void dispose() {
    _exerciseController.dispose(); // Освобождаем ресурсы контроллера
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Инициализируем отфильтрованный список всеми доступными упражнениями
    _filteredExercises = List.from(globals.availableExercises);
  }

  /// Метод для фильтрации упражнений на основе поискового запроса
  void _filterExercises(String query) {
    setState(() {
      _filteredExercises = globals.availableExercises
          .where((exercise) =>
              exercise.name.toLowerCase().contains(query.toLowerCase()))
          .toList(); // Фильтруем список упражнений
    });
  }

  Future<void> _addToDB(String name) async {
    final response = await http.post(
      Uri.parse('${globals.addr}add_exercise'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'id': 0,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 201) {
      // Декодируем ответ, чтобы получить user_id
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Сохраняем user в глобальную переменную
      globals.availableExercises
          .add(AvailableExercise(name: name, id: responseData['exercise_id']));
      _filteredExercises.add(AvailableExercise(
          name: name,
          id: responseData['exercise_id'])); // Добавляем новое упражнение в ф
      _filterExercises(
          _searchController.text); // Обновляем фильтрованный список
      //print(globals.userId); // Выводим user_id на экран
      // Переходим на страницу питания
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при добавлении блюда')),
      );
    }
  }

  /// Метод для открытия диалогового окна добавления нового упражнения
  void _addExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить новое упражнение'),
          content: TextField(
            controller: _exerciseController,
            decoration: const InputDecoration(
              labelText: 'Название упражнения',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _exerciseController.clear();
                Navigator.pop(
                    context); // Закрываем диалоговое окно без добавления
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _addToDB(_exerciseController
                      .text); // Добавляем новое упражнение в БД
                });
                _exerciseController.clear();
                Navigator.pop(
                    context); // Закрываем диалоговое окно после добавления
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
        title: const Text('Выбор упражнения'),
      ),
      body: Column(
        children: [
          // Поле для поиска упражнения
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged:
                  _filterExercises, // Обновляем список упражнений при каждом изменении текста
              decoration: const InputDecoration(
                labelText: 'Поиск упражнений',
                prefixIcon: Icon(Icons.search), // Иконка поиска в поле ввода
              ),
            ),
          ),
          // Список упражнений, отфильтрованный по поисковому запросу
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredExercises[index].name),
                  onTap: () {
                    // Вызываем коллбэк с выбранным упражнением и закрываем страницу
                    widget.onExerciseSelected(_filteredExercises[index].name);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Кнопка для добавления нового упражнения
      floatingActionButton: FloatingActionButton(
        onPressed:
            _addExerciseDialog,
        child: const Icon(Icons.add), // Открываем диалог добавления нового упражнения
      ),
    );
  }
}
