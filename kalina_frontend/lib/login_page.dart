import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals; // Импортируем файл с глобальными переменными

import 'register_page.dart';
import './screens/nutrition_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;

  @override
  void initState() {
    super.initState(); // Получение данных при открытии страницы
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  // Сохранение данных
  Future<void> saveUserIdAndPFC(
      int userId, int proteins, int fats, int carbs) async {
    globals.userId = userId;
    globals.proteins = proteins;
    globals.fats = fats;
    globals.carbs = carbs;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setInt('proteins', proteins);
    await prefs.setInt('fats', fats);
    await prefs.setInt('carbs', carbs);
    print(prefs.getInt('userId'));
  }

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите логин и пароль')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${globals.addr}login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    print(response.body.toString());

    if (response.statusCode == 200) {
      // Декодируем ответ, чтобы получить user_id
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Сохраняем user в глобальную переменную
      saveUserIdAndPFC(responseData['user_id'], responseData['proteins'],
          responseData['fats'], responseData['carbs']);
      print(globals.userId); // Выводим user_id на экран
      // Переходим на страницу питания
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NutritionPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неправильное имя пользователя или/и пароль')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход в аккаунт'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Имя пользователя',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Войти'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Нет аккаунта? Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
