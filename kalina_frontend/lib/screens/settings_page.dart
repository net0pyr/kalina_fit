import 'package:flutter/material.dart';
import './nutrition_page.dart';
import './calendar_page.dart';
import '../login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _proteinsController.text = globals.proteins.toString();
    _fatsController.text = globals.fats.toString();
    _carbsController.text = globals.carbs.toString();
  }

  void _saveSettings() {
    // Обновляем глобальные переменные
    setState(() {
      globals.proteins = int.tryParse(_proteinsController.text) ?? 0;
      globals.fats = int.tryParse(_fatsController.text) ?? 0;
      globals.carbs = int.tryParse(_carbsController.text) ?? 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены')),
    );
  }

  void _logout() {
    clearUserId();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const LoginPage()), // Перенаправляем на страницу входа
    );
  }

  // Сохранение данных
  Future<void> saveUserPFC() async {
    globals.proteins = globals.proteins;
    globals.fats = globals.fats;
    globals.carbs = globals.carbs;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('proteins', globals.proteins);
    await prefs.setInt('fats', globals.fats);
    await prefs.setInt('carbs', globals.carbs);
  }

  Future<void> clearUserId() async {
    globals.userId = null; // Очищаем user_id в глобальной
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  Future<void> _changePFC() async {
    final response = await http.post(
      Uri.parse('${globals.addr}change_pfc'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': globals.userId,
        'proteins': globals.proteins,
        'carbs': globals.carbs,
        'fats': globals.fats,
      }),
    );

    // Проверка результата запроса
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
      saveUserPFC();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при изменении')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите значения для белков, жиров и углеводов:',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _proteinsController,
              decoration: const InputDecoration(labelText: 'Белки (г)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fatsController,
              decoration: const InputDecoration(labelText: 'Жиры (г)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _carbsController,
              decoration: const InputDecoration(labelText: 'Углеводы (г)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _saveSettings(); // сохраняем изменения
                _changePFC(); // изменяем в бд
              }, // Сохраняем изменения
              child: const Text('Сохранить изменения'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logout, // Обработчик выхода
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),

      // Панель навигации
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Индекс текущей страницы (настройки)
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
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    const NutritionPage(),
                transitionDuration: Duration.zero, // Убирает анимацию перехода
                reverseTransitionDuration:
                    Duration.zero, // Убирает анимацию возврата
              ),
            );
          } else if (index == 2) {
            // Остаемся на текущей странице
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
}
