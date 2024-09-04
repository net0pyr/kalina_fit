import 'package:flutter/material.dart';

/// Страница для ввода данных о тренировке по бегу
class RunTrainingPage extends StatefulWidget {
  const RunTrainingPage({super.key});

  @override
  _RunTrainingPageState createState() => _RunTrainingPageState();
}

class _RunTrainingPageState extends State<RunTrainingPage> {
  // Контроллеры для управления вводом текста в полях расстояния и времени
  final _distanceController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void dispose() {
    // Освобождаем ресурсы, используемые контроллерами, при уничтожении виджета
    _distanceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировка: Бег'), // Заголовок страницы
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Добавляем отступы вокруг содержимого
        child: Column(
          children: <Widget>[
            // Поле для ввода расстояния в километрах
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number, // Клавиатура с цифрами
              decoration: const InputDecoration(
                labelText: 'Расстояние (км)', // Подсказка для пользователя
              ),
            ),
            // Поле для ввода времени в минутах
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number, // Клавиатура с цифрами
              decoration: const InputDecoration(
                labelText: 'Время (минуты)', // Подсказка для пользователя
              ),
            ),
            const SizedBox(height: 20), // Отступ между полями и кнопками
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Распределение кнопок по горизонтали
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Сохраняем значения полей или устанавливаем их по умолчанию, если они пусты
                    final distance = _distanceController.text.isEmpty
                        ? '0'
                        : _distanceController.text;
                    final time = _timeController.text.isEmpty
                        ? '0'
                        : _timeController.text;

                    // Возвращаем введенные данные обратно на предыдущую страницу
                    Navigator.pop(
                      context,
                      {
                        'distance': distance,
                        'time': time,
                      },
                    );
                  },
                  child: const Text('Сохранить'), // Текст на кнопке
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Закрываем страницу без сохранения
                  }, // Текст на кнопке
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Красный цвет для кнопки "Отмена"
                  ),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
