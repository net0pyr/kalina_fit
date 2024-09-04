import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals; // Импортируем файл с глобальными переменными
import './screens/nutrition_page.dart'; // Импортируем страницу питания
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscure = true;
  bool _isConfirmPasswordObscure = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
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
  }

  Future<void> _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${globals.addr}register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 201) {
      // Декодируем ответ, чтобы получить user_id
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      saveUserIdAndPFC(responseData['user_id'], 0, 0, 0);
      print(globals.userId);
      // Переходим на страницу питания
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NutritionPage()),
      );
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя пользователя уже занято')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при регистрации')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
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
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _isConfirmPasswordObscure,
              decoration: InputDecoration(
                labelText: 'Подтвердите пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordObscure
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: _toggleConfirmPasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
