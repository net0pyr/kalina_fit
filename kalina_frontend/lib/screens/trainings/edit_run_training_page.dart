import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../globals.dart' as globals;

/// Страница для редактирования данных о тренировке по бегу
class EditRunTrainingPage extends StatefulWidget {
  final String distance; // Расстояние, переданное с предыдущей страницы
  final String time; // Время, переданное с предыдущей страницы
  final String trainingSessionId; // Добавляем идентификатор тренировки

  const EditRunTrainingPage(
      {super.key, required this.distance,
      required this.time,
      required this.trainingSessionId});

  @override
  _EditRunTrainingPageState createState() => _EditRunTrainingPageState();
}

class _EditRunTrainingPageState extends State<EditRunTrainingPage> {
  late TextEditingController
      _distanceController; // Контроллер для поля ввода расстояния
  late TextEditingController
      _timeController; // Контроллер для поля ввода времени

  @override
  void initState() {
    super.initState();
    // Инициализация контроллеров с начальными значениями из переданных данных
    _distanceController = TextEditingController(text: widget.distance);
    _timeController = TextEditingController(text: widget.time);
  }

  @override
  void dispose() {
    // Освобождаем ресурсы, используемые контроллерами, при уничтожении виджета
    _distanceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _deleteAppointmentFromDB(String id) async {
    final response = await http.post(
      Uri.parse('${globals.addr}delete_appointment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': "Бег",
        'id': id,
      }),
    );

    print(response.body.toString());

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Произошла ошибка при удалении пробежки')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать тренировку: Бег'), // Заголовок страницы
        actions: [
          // Кнопка для удаления текущей тренировки
          IconButton(
            icon: const Icon(Icons.delete), // Иконка удаления
            onPressed: () {
              // Показываем диалог подтверждения
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Удалить тренировку'), // Заголовок диалога
                    content: const Text(
                        'Вы уверены, что хотите удалить эту тренировку?'), // Основное сообщение диалога
                    actions: [
                      // Кнопка для отмены удаления
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // Закрываем диалог без удаления
                        },
                        child: const Text('Отмена'),
                      ),
                      // Кнопка для подтверждения удаления
                      ElevatedButton(
                        onPressed: () {
                          _deleteAppointmentFromDB(widget.trainingSessionId);
                          setState(() {});
                          Navigator.of(context).pop(); // Закрываем диалог
                          // Возвращаемся на предыдущую страницу с действием 'delete'
                          Navigator.pop(context, {'action': 'delete'});
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red),
                        child: const Text('Удалить'), // Красный цвет для кнопки удаления
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16.0), // Отступы вокруг содержимого страницы
        child: Column(
          children: <Widget>[
            // Поле для редактирования расстояния в километрах
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number, // Клавиатура с цифрами
              decoration: const InputDecoration(
                labelText: 'Расстояние (км)', // Подсказка для пользователя
              ),
            ),
            // Поле для редактирования времени в минутах
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number, // Клавиатура с цифрами
              decoration: const InputDecoration(
                labelText: 'Время (минуты)', // Подсказка для пользователя
              ),
            ),
            const SizedBox(height: 20), // Отступ между полями и кнопкой
            ElevatedButton(
              onPressed: () {
                // Возвращаем отредактированные данные обратно на предыдущую страницу
                Navigator.pop(
                  context,
                  {
                    'action':
                        'edit', // Указываем, что это действие редактирования
                    'distance': _distanceController
                        .text, // Отредактированное расстояние
                    'time': _timeController.text, // Отредактированное время
                  },
                );
              },
              child: const Text('Сохранить изменения'), // Текст на кнопке
            ),
          ],
        ),
      ),
    );
  }
}
