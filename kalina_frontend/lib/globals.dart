import 'entity/exercise.dart';
import 'entity/dish.dart';
import 'entity/custom_appointment.dart';
import 'entity/eating.dart';

int? userId;

int proteins = 0;
int fats = 0;
int carbs = 0;

List<AvailableExercise> availableExercises = [];
List<Dish> availableDishes = [];
Map<DateTime, List<Eating>> dishes = {};
List<CustomAppointment> customAppointments = [];
Map<String, List<Exercise>> exercisesMap = {};

String addr = 'http://45.67.57.92:30088/';

bool isFetching = false;
int loaded = 0;
