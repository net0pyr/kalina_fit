import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import './trainings/run_training_page.dart';
import './trainings/edit_run_training_page.dart';
import './trainings/gym_training_page.dart';
import '../entity/custom_appointment.dart';
import './nutrition_page.dart';
import './settings_page.dart';
import '../globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// Основной виджет страницы календаря
class CalendarPage extends StatefulWidget {
  @override
  CalendarPageState createState() => CalendarPageState();
}

/// Состояние для страницы календаря
class CalendarPageState extends State<CalendarPage> {
  // Список всех событий (тренировок) в календаре
  List<CustomAppointment> _appointments = globals.customAppointments;
  // Выбранная дата, для которой будут отображаться тренировки
  DateTime _selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  // Переменные для хранения дистанции и времени тренировки (для бега)
  late String distance;
  late String time;

  void _deleteTrainingFromCalendar(String trainingSessionId) {
    setState(() {
      _appointments.removeWhere(
          (appointment) => appointment.trainingSessionId == trainingSessionId);
    });
  }

  Future<void> _addAppointmentToDB(String type, String distance, String time,
      String id, CustomAppointment appointment) async {
    final response = await http.post(
      Uri.parse(globals.addr + 'add_appointment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': DateTime.utc(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedDate.hour,
                _selectedDate.minute,
                _selectedDate.second)
            .toIso8601String(),
        'type': type,
        'time': int.parse(time),
        'distance': double.parse(distance),
        'user_id': globals.userId,
        'id': id,
      }),
    );

    print(response.body.toString());

    if (response.statusCode != 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка при добавлении тренировки')),
      );
    } else {
      setState(() {
        _appointments.add(appointment);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок страницы
        title: Text('Тренировки'),
      ),
      body: Column(
        children: [
          // Основной виджет календаря
          SfCalendar(
            view: CalendarView.month, // Отображение календаря в виде месяца
            firstDayOfWeek: 1, // Неделя начинается с понедельника
            dataSource: TrainingDataSource(
                _appointments), // Источник данных для календаря
            onTap: (CalendarTapDetails details) {
              // Обработка клика по дате в календаре
              if (details.date != null) {
                setState(() {
                  _selectedDate = details.date!; // Обновляем выбранную дату
                });
              }
            },
          ),
          const SizedBox(
              height: 15), // Отступ между календарем и списком тренировок
          Expanded(
            child:
                _buildAppointmentList(), // Список тренировок для выбранной даты
          ),
        ],
      ),
      // Плавающая кнопка для добавления новой тренировки
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointment, // Обработка нажатия на кнопку
        tooltip: 'Добавить тренировку', // Подсказка при наведении на кнопку
        child: Icon(Icons.add), // Иконка кнопки
      ),
      // Панель навигации
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Индекс текущей страницы (тренировки)
        onTap: (index) {
          if (index == 0) {
            // остаемся на страницу тренировок
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    NutritionPage(),
                transitionDuration: Duration.zero, // Убирает анимацию перехода
                reverseTransitionDuration:
                    Duration.zero, // Убирает анимацию возврата
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    SettingsPage(),
                transitionDuration: Duration.zero, // Убирает анимацию перехода
                reverseTransitionDuration:
                    Duration.zero, // Убирает анимацию возврата
              ),
            );
          }
        },
        items: [
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

  /// Создает виджет со списком тренировок для выбранной даты
  Widget _buildAppointmentList() {
    // Фильтруем список событий, чтобы отобразить только те, которые совпадают с выбранной датой
    final selectedAppointments = _appointments.where((appointment) {
      return appointment.startTime.year == _selectedDate.year &&
          appointment.startTime.month == _selectedDate.month &&
          appointment.startTime.day == _selectedDate.day;
    }).toList();

    // Если нет тренировок на выбранную дату, отображаем сообщение
    if (selectedAppointments.isEmpty) {
      return Center(child: Text('Нет тренировок в выбранную дату'));
    }

    // Если тренировки есть, отображаем их в виде списка
    return ListView.builder(
      itemCount: selectedAppointments.length, // Количество тренировок
      itemBuilder: (context, index) {
        final appointment = selectedAppointments[index];
        return ListTile(
          title: Text(appointment
              .subject), // Тип тренировки (например, "Бег" или "Зал")
          subtitle: Text(appointment.notes ??
              ''), // Дополнительные заметки (например, дистанция и время для бега)
          onTap: () => _onAppointmentSelected(
              appointment), // Обработка нажатия на тренировку в списке
        );
      },
    );
  }

  /// Обрабатывает добавление новой тренировки
  void _addAppointment() async {
    String? selectedType;

    // Открывает диалоговое окно для выбора типа тренировки (Бег или Зал)
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Выберите вид тренировки'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Радио-кнопка для выбора "Бег"
                  RadioListTile<String>(
                    title: Text('Бег'),
                    value: 'Бег',
                    groupValue: selectedType,
                    onChanged: (String? value) async {
                      setState(() {
                        selectedType =
                            value; // Устанавливаем выбранный тип тренировки
                      });
                    },
                  ),
                  // Радио-кнопка для выбора "Зал"
                  RadioListTile<String>(
                    title: Text('Зал'),
                    value: 'Зал',
                    groupValue: selectedType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedType =
                            value; // Устанавливаем выбранный тип тренировки
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                // Кнопка для закрытия диалога без сохранения изменений
                TextButton(
                  child: Text('Отмена'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Закрываем диалоговое окно
                  },
                ),
                // Кнопка для сохранения выбранного типа тренировки и закрытия диалога
                TextButton(
                  child: Text('Добавить'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        selectedType); // Возвращаем выбранный тип тренировки
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // Если пользователь выбрал тип тренировки и нажал "Добавить"
    if (result != null) {
      if (selectedType == 'Бег') {
        // Открываем страницу для добавления данных о беге
        final runData = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RunTrainingPage(),
          ),
        );
        if (runData != null) {
          // Если данные о беге были введены, сохраняем их
          distance = runData['distance'];
          time = runData['time'];
          _createAppointment(
              result); // Создаем событие с учетом введенных данных
        } else {
          _createAppointment(
              result); // Создаем событие без дополнительных данных
        }
      } else if (selectedType == 'Зал') {
        distance = "0";
        time = "0";
        // Создаем событие для тренировки в зале
        String id = _createAppointment(result);
        globals.exercisesMap[id] = []; // Создаем пустой словарь для упражнений
        // Открываем страницу для добавления данных о тренировке в зале
        final gymData = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GymTrainingPage(
              trainingSessionId: id,
              onTrainingDeleted: _deleteTrainingFromCalendar,
            ),
          ),
        );
      }
    }
  }

  /// Создает и добавляет событие в календарь
  String _createAppointment(String type, {String? description}) {
    final DateTime startTime =
        _selectedDate; // Начало события совпадает с выбранной датой
    final DateTime endTime =
        _selectedDate; // Конец события также совпадает с выбранной датой
    description ??= type == 'Бег'
        ? '${distance} км; ${time} мин' // По умолчанию добавляем описание для бега
        : ''; // По умолчанию добавляем описание для зала

    // Создаем объект события (тренировки)
    final CustomAppointment appointment = CustomAppointment(
      startTime: startTime, // Время начала события
      endTime: endTime, // Время окончания события
      subject: type, // Тип тренировки (например, "Бег" или "Зал")
      color: type.startsWith('Бег')
          ? Color.fromARGB(255, 0, 255, 255)
          : Color.fromARGB(255, 255, 102,
              0), // Цвет события в зависимости от типа тренировки
      notes:
          description, // Дополнительные заметки (например, дистанция и время для бега)
    );
    _addAppointmentToDB(type, distance, time, appointment.trainingSessionId,
        appointment); // Добавляем событие в БД
    return appointment
        .trainingSessionId; // Возвращаем идентификатор созданного события
  }

  bool changeRunning = false;

  Future<void> _changeRunning(String id, int time, double distance) async {
    final response = await http.post(
      Uri.parse(globals.addr + 'change_running'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'time': time,
        'distance': distance,
      }),
    );
    print(id + "\n");
    print(response.body.toString());

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка при изменении пробежки')),
      );
    } else {
      changeRunning = true;
    }
  }

  /// Обрабатывает выбор события из списка
  void _onAppointmentSelected(CustomAppointment appointment) async {
    if (appointment.subject.startsWith('Бег')) {
      // Если событие связано с бегом, разбираем данные из описания
      final details = appointment.notes?.split(' ');
      if (details != null) {
        final distance = details[0];
        final time = details[2];

        // Открываем страницу для редактирования данных о беге
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditRunTrainingPage(
              distance: distance,
              time: time,
              trainingSessionId: appointment.trainingSessionId,
            ),
          ),
        );

        if (result != null && result['action'] == 'edit') {
          _changeRunning(appointment.trainingSessionId,
              int.parse(result['time']), double.parse(result['distance']));
          // Если тренировка была отредактирована, обновляем данные
          Timer(Duration(milliseconds: 100), () {
            if (changeRunning) {
              setState(() {
                appointment.notes =
                    '${result['distance']} км; ${result['time']} мин';
              });
            }
          });
        } else if (result != null && result['action'] == 'delete') {
          // Если тренировка была удалена, удаляем событие
          setState(() {
            _appointments.remove(appointment);
          });
        }
      }
    } else if (appointment.subject.startsWith('Зал')) {
      // Если событие связано с залом, открываем страницу для редактирования данных
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GymTrainingPage(
            trainingSessionId: appointment.trainingSessionId,
            onTrainingDeleted: _deleteTrainingFromCalendar,
          ),
        ),
      );
    }
  }
}

/// Класс-источник данных для календаря
class TrainingDataSource extends CalendarDataSource {
  TrainingDataSource(List<CustomAppointment> source) {
    appointments = source; // Передаем список событий в календарь
  }
}
