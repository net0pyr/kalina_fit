package database

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

// Переменная для хранения соединения с базой данных
var db *sql.DB

// Структура User представляет пользователя с полями для имени пользователя и пароля
type User struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// Структура для представления данных, которые нужно обновить
type UpdatePFCRequest struct {
	UserID   int `json:"user_id"`
	Proteins int `json:"proteins"`
	Carbs    int `json:"carbs"`
	Fats     int `json:"fats"`
}

// Структура для представления доступного блюда
type Dish struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Proteins int    `json:"proteins"`
	Carbs    int    `json:"carbs"`
	Fats     int    `json:"fats"`
}

// Структура для представления доступного упражнения
type Exercise struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type UserID struct {
	Id int `json:"id"`
}

// InitDB инициализирует соединение с базой данных
func InitDB() {
	var err error
	// Строка соединения с базой данных PostgreSQL
	connStr := "user=net0pyr password=fufgfdrf dbname=kalina_db host=postgresql sslmode=disable"
	// Открываем соединение с базой данных
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err) // Если произошла ошибка, завершить программу и вывести ошибку
	}
}

// ChangePFCHandler обрабатывает запросы на изменение PFC (протеины, углеводы, жиры)
func ChangePFCHandler(w http.ResponseWriter, r *http.Request) {
	var updateReq UpdatePFCRequest

	// Декодируем JSON-данные из тела запроса в структуру UpdatePFCRequest
	err := json.NewDecoder(r.Body).Decode(&updateReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Обновляем данные пользователя в базе данных
	_, err = db.Exec("UPDATE users SET proteins = $1, carbs = $2, fats = $3 WHERE id = $4",
		updateReq.Proteins, updateReq.Carbs, updateReq.Fats, updateReq.UserID)

	if err != nil {
		http.Error(w, "Error updating PFC values", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("PFC values updated successfully"))
}

// LoginHandler обрабатывает запросы на авторизацию пользователя
func LoginHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	// Декодируем JSON-данные из тела запроса в структуру User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	fmt.Println(user.Username)

	var storedHash string
	var userID int
	var proteins, carbs, fats int
	// Извлекаем хэш пароля и ID пользователя из базы данных
	err = db.QueryRow("SELECT id, pass, proteins, carbs, fats FROM users WHERE login=$1", user.Username).Scan(&userID, &storedHash, &proteins, &carbs, &fats)
	if err != nil {
		http.Error(w, "Invalid username or password", http.StatusUnauthorized) // Возвращаем ошибку, если пользователь не найден
		return
	}

	// Сравниваем хэшированный пароль из базы данных с паролем, который передал пользователь
	err = bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(user.Password))
	if err != nil {
		http.Error(w, "Invalid username or password", http.StatusUnauthorized) // Возвращаем ошибку, если пароли не совпадают
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"user_id":  userID,
		"proteins": proteins,
		"carbs":    carbs,
		"fats":     fats,
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

func GetListsHandler(w http.ResponseWriter, r *http.Request) {
	// Получаем список доступных блюд
	dishesQuery := "SELECT id, name, proteins, carbs, fats FROM available_dishes"
	dishesRows, err := db.Query(dishesQuery)
	if err != nil {
		http.Error(w, "Failed to retrieve dishes", http.StatusInternalServerError)
		return
	}
	defer dishesRows.Close()

	var availableDishes []Dish
	for dishesRows.Next() {
		var dish Dish
		if err := dishesRows.Scan(&dish.ID, &dish.Name, &dish.Proteins, &dish.Carbs, &dish.Fats); err != nil {
			http.Error(w, "Error scanning dish", http.StatusInternalServerError)
			return
		}
		availableDishes = append(availableDishes, dish)
	}

	// Получаем список доступных упражнений
	exercisesQuery := "SELECT id, name FROM available_exercises"
	exercisesRows, err := db.Query(exercisesQuery)
	if err != nil {
		http.Error(w, "Failed to retrieve exercises", http.StatusInternalServerError)
		return
	}
	defer exercisesRows.Close()

	var availableExercises []Exercise
	for exercisesRows.Next() {
		var exercise Exercise
		if err := exercisesRows.Scan(&exercise.ID, &exercise.Name); err != nil {
			http.Error(w, "Error scanning exercise", http.StatusInternalServerError)
			return
		}
		availableExercises = append(availableExercises, exercise)
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"available_dishes":    availableDishes,
		"available_exercises": availableExercises,
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

// RegisterHandler обрабатывает запросы на регистрацию нового пользователя
func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	// Декодируем JSON-данные из тела запроса в структуру User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	// Хэшируем пароль перед сохранением в базу данных
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Server error, unable to create your account.", http.StatusInternalServerError) // Возвращаем ошибку, если не удалось хэшировать пароль
		return
	}

	// Вставляем нового пользователя в базу данных с хэшированным паролем и получаем его ID
	var userID int
	err = db.QueryRow("INSERT INTO users (login, pass, proteins, carbs, fats) VALUES ($1, $2, 0, 0, 0) RETURNING id", user.Username, string(hashedPassword)).Scan(&userID)
	if err != nil {
		http.Error(w, "Username already exists", http.StatusConflict) // Возвращаем ошибку, если пользователь с таким именем уже существует
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"user_id": userID,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

func AddDishHandler(w http.ResponseWriter, r *http.Request) {
	var dish Dish

	// Декодируем JSON-данные из тела запроса в структуру User
	err := json.NewDecoder(r.Body).Decode(&dish)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	// Вставляем нового пользователя в базу данных с хэшированным паролем и получаем его ID
	var dishID int
	err = db.QueryRow("INSERT INTO available_dishes (proteins, carbs, fats, name) VALUES ($1, $2, $3, $4) RETURNING id", dish.Proteins, dish.Carbs, dish.Fats, dish.Name).Scan(&dishID)
	if err != nil {
		print("Error inserting")
		http.Error(w, "Dish already exists", http.StatusConflict) // Возвращаем ошибку, если пользователь с таким именем уже существует
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"dish_id": dishID,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

func AddExerciseHandler(w http.ResponseWriter, r *http.Request) {
	var exercise Exercise

	// Декодируем JSON-данные из тела запроса в структуру User
	err := json.NewDecoder(r.Body).Decode(&exercise)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	// Вставляем нового пользователя в базу данных с хэшированным паролем и получаем его ID
	var exerciseID int
	err = db.QueryRow("INSERT INTO available_exercises (name) VALUES ($1) RETURNING id", exercise.Name).Scan(&exerciseID)
	if err != nil {
		print("Error inserting")
		http.Error(w, "Exercise already exists", http.StatusConflict) // Возвращаем ошибку, если пользователь с таким именем уже существует
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"exercise_id": exerciseID,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

type CustomAppointment struct {
	Date     time.Time `json:"date"`
	Type     string    `json:"type"`
	Time     int       `json:"time"`
	Distance float32   `json:"distance"`
	Id       string    `json:"id"`
}

func GetAppointmentsHandler(w http.ResponseWriter, r *http.Request) {
	var user_id UserID

	// Декодируем JSON-данные из тела запроса в структуру userID
	err := json.NewDecoder(r.Body).Decode(&user_id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Получаем список тренировок в зале
	gymRows, err := db.Query("SELECT date, id FROM trainings WHERE trainings.user_id = $1", user_id.Id)
	if err != nil {
		http.Error(w, "Failed to retrieve exercises", http.StatusInternalServerError)
		return
	}
	defer gymRows.Close()

	var appointments []CustomAppointment
	for gymRows.Next() {
		var appointment CustomAppointment
		if err := gymRows.Scan(&appointment.Date, &appointment.Id); err != nil {
			http.Error(w, "Error scanning exercise", http.StatusInternalServerError)
			return
		}
		appointment.Type = "Зал"
		appointment.Distance = 0
		appointment.Time = 0
		appointments = append(appointments, appointment)
	}

	// Получаем список тренировок беговых
	runningRows, err := db.Query("SELECT date, time, distance, id FROM runnings WHERE runnings.user_id = $1", user_id.Id)
	if err != nil {
		http.Error(w, "Failed to retrieve exercises", http.StatusInternalServerError)
		return
	}
	defer runningRows.Close()

	for runningRows.Next() {
		var appointment CustomAppointment
		if err := runningRows.Scan(&appointment.Date, &appointment.Time, &appointment.Distance, &appointment.Id); err != nil {
			http.Error(w, "Error scanning exercise", http.StatusInternalServerError)
			return
		}
		appointment.Type = "Бег"
		appointments = append(appointments, appointment)
	}

	// Устанавливаем заголовок Content-Type для ответа в формате JSON
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	// Кодируем список тренировок в JSON и отправляем клиенту

	err = json.NewEncoder(w).Encode(appointments)
	if err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

type CustomAppointmentWWithID struct {
	Date     time.Time `json:"date"`
	Type     string    `json:"type"`
	Time     int       `json:"time"`
	Distance float32   `json:"distance"`
	Id       string    `json:"id"`
	UserID   int       `json:"user_id"`
}

func AddAppointment(w http.ResponseWriter, r *http.Request) {
	var appointment CustomAppointmentWWithID

	// Декодируем JSON-данные из тела запроса в структуру CustomAppointment
	err := json.NewDecoder(r.Body).Decode(&appointment)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	fmt.Println(appointment.Date)
	fmt.Println(appointment.UserID)
	fmt.Println(appointment.Id)

	if appointment.Type == "Зал" {
		_, err = db.Exec("INSERT INTO trainings (user_id, date, id) VALUES ($1, $2, $3)",
			appointment.UserID, appointment.Date, appointment.Id)
		if err != nil {
			fmt.Println("Error inserting training:", err)
			http.Error(w, "Training already exists or there was another error", http.StatusConflict)
			return
		}
	} else {
		_, err = db.Exec("INSERT INTO runnings (user_id, date, id, time, distance) VALUES ($1, $2, $3, $4, $5)",
			appointment.UserID, appointment.Date, appointment.Id, appointment.Time, appointment.Distance)
		if err != nil {
			fmt.Println("Error inserting running:", err)
			http.Error(w, "Running already exists or there was another error", http.StatusConflict)
			return
		}
	}

	w.WriteHeader(http.StatusCreated)
}

type AppointmentID struct {
	Type string `json:"type"`
	Id   string `json:"id"`
}

func DeleteAppointment(w http.ResponseWriter, r *http.Request) {
	var appointmentID AppointmentID

	// Декодируем JSON-данные из тела запроса в структуру CustomAppointment
	err := json.NewDecoder(r.Body).Decode(&appointmentID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if appointmentID.Type == "Зал" {
		_, err = db.Exec("DELETE FROM trainings WHERE id = $1",
			appointmentID.Id)
		if err != nil {
			fmt.Println("Error deleting training:", err)
			http.Error(w, "error", http.StatusConflict)
			return
		}
	} else {
		_, err = db.Exec("DELETE FROM runnings WHERE id = $1",
			appointmentID.Id)
		if err != nil {
			fmt.Println("Error inserting running:", err)
			http.Error(w, "error", http.StatusConflict)
			return
		}
	}

	w.WriteHeader(http.StatusOK)
}

type Eating struct {
	Id     string    `json:"id"`
	Date   time.Time `json:"date"`
	Weight int       `json:"weight"`
	Dish   int       `json:"dish"`
}

func FetchEatings(w http.ResponseWriter, r *http.Request) {
	var user_id UserID

	// Декодируем JSON-данные из тела запроса в структуру UserID
	err := json.NewDecoder(r.Body).Decode(&user_id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Получаем список тренировок беговых
	eatingRows, err := db.Query(`SELECT date, weight, dish, id FROM eating 
	WHERE eating.user_id = $1`, user_id.Id)
	if err != nil {
		http.Error(w, "Failed to retrieve eating", http.StatusInternalServerError)
		return
	}
	defer eatingRows.Close()

	var eatings []Eating
	for eatingRows.Next() {
		var eating Eating
		if err := eatingRows.Scan(&eating.Date, &eating.Weight, &eating.Dish, &eating.Id); err != nil {
			http.Error(w, "Error scanning exercise", http.StatusInternalServerError)
			return
		}
		eatings = append(eatings, eating)
	}

	// Устанавливаем заголовок Content-Type для ответа в формате JSON
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	// Кодируем список тренировок в JSON и отправляем клиенту
	err = json.NewEncoder(w).Encode(eatings)
	if err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}

}

type EatingWWithID struct {
	UserId int       `json:"user_id"`
	Date   time.Time `json:"date"`
	Weight int       `json:"weight"`
	Dish   int       `json:"dish"`
}

func AddEating(w http.ResponseWriter, r *http.Request) {
	var eating EatingWWithID

	// Декодируем JSON-данные из тела запроса в структуру User
	err := json.NewDecoder(r.Body).Decode(&eating)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	var ID int
	err = db.QueryRow(`INSERT INTO eating (date, user_id, weight, dish) 
	VALUES ($1, $2, $3, $4) 
	RETURNING id`,
		eating.Date, eating.UserId, eating.Weight, eating.Dish).Scan(&ID)
	if err != nil {
		http.Error(w, "Eating already exists", http.StatusConflict) // Возвращаем ошибку, если пользователь с таким именем уже существует
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"id": ID,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

type EatingID struct {
	Id int `json:"id"`
}

func DeleteEating(w http.ResponseWriter, r *http.Request) {
	var eatingId EatingID

	// Декодируем JSON-данные из тела запроса в структуру CustomAppointment
	err := json.NewDecoder(r.Body).Decode(&eatingId)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err = db.Exec("DELETE FROM eating WHERE id = $1",
		eatingId.Id)
	if err != nil {
		fmt.Println("Error deleting training:", err)
		http.Error(w, "error", http.StatusConflict)
		return
	}

	w.WriteHeader(http.StatusOK)
}

type ChangeRunningType struct {
	Id       string  `json:"id"`
	Distance float32 `json:"distance"`
	Time     int     `json:"time"`
}

func ChangeRunning(w http.ResponseWriter, r *http.Request) {
	var running ChangeRunningType

	// Декодируем JSON-данные из тела запроса в структуру UpdatePFCRequest
	err := json.NewDecoder(r.Body).Decode(&running)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Обновляем данные пользователя в базе данных
	_, err = db.Exec("UPDATE runnings SET distance = $1, time = $2 WHERE id = $3",
		running.Distance, running.Time, running.Id)

	if err != nil {
		http.Error(w, "Error updating running values", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("running values updated successfully"))
}

type ChangeEatingType struct {
	Id     int `json:"id"`
	Weight int `json:"weight"`
}

func ChangeEating(w http.ResponseWriter, r *http.Request) {
	var eating ChangeEatingType

	// Декодируем JSON-данные из тела запроса в структуру UpdatePFCRequest
	err := json.NewDecoder(r.Body).Decode(&eating)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Обновляем данные пользователя в базе данных
	_, err = db.Exec("UPDATE eating SET weight = $1 WHERE id = $2",
		eating.Weight, eating.Id)

	if err != nil {
		http.Error(w, "Error updating eating values", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("eating values updated successfully"))
}

type Set struct {
	Id     int     `json:"id"`
	Weight float64 `json:"weight"`
	Reps   int     `json:"reps"`
}

type ExerciseWithSets struct {
	Id       int    `json:"id"`
	Training string `json:"training"`
	Exercise string `json:"exercise"`
	Sets     []Set  `json:"sets"`
}

func FetchExercises(w http.ResponseWriter, r *http.Request) {
	var user_id UserID

	// Декодируем JSON-данные из тела запроса в структуру UserID
	err := json.NewDecoder(r.Body).Decode(&user_id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Получаем список тренировок беговых
	eatingRows, err := db.Query(`
		SELECT 
			exercises.id as exercise_id, 
			exercises.training, 
			available_exercises.name as exerise_name, 
			sets.id as sets_id, 
			sets.weight, 
			sets.reps 
		FROM 
			trainings 
		RIGHT JOIN 
			exercises ON exercises.training = trainings.id 
		LEFT JOIN 
			sets ON sets.exercise = exercises.id
		RIGHT JOIN 
			available_exercises ON available_exercises.id = exercises.exercise
		WHERE 
			trainings.user_id = $1`, user_id.Id)
	if err != nil {
		http.Error(w, "Failed to retrieve eating", http.StatusInternalServerError)
		return
	}
	defer eatingRows.Close()

	// Карта для хранения упражнений с сетами
	exercisesMap := make(map[int]*ExerciseWithSets)

	// Обработка результата запроса
	for eatingRows.Next() {
		var (
			exerciseId        int
			training          string
			availableExercise string
			setId             sql.NullInt32   // Изменяем тип для учета NULL значений
			weight            sql.NullFloat64 // Изменяем тип для учета NULL значений
			reps              sql.NullInt32   // Изменяем тип для учета NULL значений
		)

		// Считываем данные из строки
		err := eatingRows.Scan(&exerciseId, &training, &availableExercise, &setId, &weight, &reps)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error scanning exercise data: %v", err), http.StatusInternalServerError)
			return
		}

		// Создаем новый сет только если setId не NULL
		var sets []Set
		if setId.Valid {
			sets = append(sets, Set{
				Id:     int(setId.Int32),
				Weight: float64(weight.Float64),
				Reps:   int(reps.Int32),
			})
		}

		// Если упражнение уже существует в карте, добавляем новый сет к существующему упражнению
		if ex, exists := exercisesMap[exerciseId]; exists {
			ex.Sets = append(ex.Sets, sets...)
		} else {
			// Если упражнения нет в карте, создаем новую запись
			exercisesMap[exerciseId] = &ExerciseWithSets{
				Id:       exerciseId,
				Training: training,
				Exercise: availableExercise,
				Sets:     sets,
			}
		}
	}

	// Преобразуем карту упражнений в слайс
	var exercisesWithSets []ExerciseWithSets
	for _, ex := range exercisesMap {
		exercisesWithSets = append(exercisesWithSets, *ex)
	}

	// Кодируем результат в JSON и отправляем клиенту
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	if err := json.NewEncoder(w).Encode(exercisesWithSets); err != nil {
		http.Error(w, "Failed to encode exercises to JSON", http.StatusInternalServerError)
		return
	}

}

type NewExercise struct {
	Training string `json:"training"`
	Exercise int    `json:"exercise"`
}

func AddExerciseToTraining(w http.ResponseWriter, r *http.Request) {
	var exercise NewExercise

	err := json.NewDecoder(r.Body).Decode(&exercise)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	var ID int
	err = db.QueryRow(`INSERT INTO exercises (training, exercise) 
	VALUES ($1, $2) 
	RETURNING id`,
		exercise.Training, exercise.Exercise).Scan(&ID)
	if err != nil {
		http.Error(w, "exercise adding err", http.StatusConflict) // Возвращаем ошибку, если пользователь с таким именем уже существует
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"id": ID,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

type NewSet struct {
	Exercise int     `json:"exercise"`
	Weight   float64 `json:"weight"`
	Reps     int     `json:"reps"`
}

func AddSetToExercise(w http.ResponseWriter, r *http.Request) {
	var set NewSet

	err := json.NewDecoder(r.Body).Decode(&set)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest) // Возвращаем ошибку, если не удалось декодировать JSON
		return
	}

	fmt.Println(set.Exercise)

	var ID int
	err = db.QueryRow(`INSERT INTO sets (exercise, weight, reps) 
	VALUES ($1, $2, $3) 
	RETURNING id`,
		set.Exercise, set.Weight, set.Reps).Scan(&ID)
	if err != nil {
		http.Error(w, fmt.Sprintf("set adding err: %v", err), http.StatusConflict) // Возвращаем ошибку, если пользователь с таким именем уже существует
		return
	}

	// Формируем ответ с ID пользователя
	response := map[string]interface{}{
		"id": ID,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response) // Отправляем ID пользователя в ответе
}

type UpdateSet struct {
	Id     int     `json:"id"`
	Weight float64 `json:"weight"`
	Reps   int     `json:"reps"`
}

func UpdateSetValues(w http.ResponseWriter, r *http.Request) {
	var set UpdateSet

	// Декодируем JSON-данные из тела запроса в структуру UpdatePFCRequest
	err := json.NewDecoder(r.Body).Decode(&set)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Обновляем данные пользователя в базе данных
	_, err = db.Exec("UPDATE sets SET weight = $1, reps = $2 WHERE id = $3",
		set.Weight, set.Reps, set.Id)

	if err != nil {
		http.Error(w, "Error updating set values", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("set values updated successfully"))
}

type SetID struct {
	Id int `json:"id"`
}

func DeleteSet(w http.ResponseWriter, r *http.Request) {
	var setId SetID

	// Декодируем JSON-данные из тела запроса в структуру CustomAppointment
	err := json.NewDecoder(r.Body).Decode(&setId)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err = db.Exec("DELETE FROM sets WHERE id = $1",
		setId.Id)
	if err != nil {
		fmt.Println("Error deleting set:", err)
		http.Error(w, "error", http.StatusConflict)
		return
	}

	w.WriteHeader(http.StatusOK)
}

type ExerciseID struct {
	Id int `json:"id"`
}

func DeleteExercise(w http.ResponseWriter, r *http.Request) {
	var exerciseId ExerciseID

	// Декодируем JSON-данные из тела запроса в структуру CustomAppointment
	err := json.NewDecoder(r.Body).Decode(&exerciseId)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err = db.Exec("DELETE FROM exercises WHERE id = $1",
		exerciseId.Id)
	if err != nil {
		fmt.Println("Error deleting exercise:", err)
		http.Error(w, "error", http.StatusConflict)
		return
	}

	w.WriteHeader(http.StatusOK)
}
