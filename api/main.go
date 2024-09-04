package main

import (
	. "kalina_api/database" // Подключаем пакет с обработчиками запрос
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
	InitDB()                                                                              // Инициализируем соединение с базой данных
	router := mux.NewRouter()                                                             // Создаем новый маршрутизатор
	router.HandleFunc("/login", LoginHandler).Methods("POST")                             // Добавляем маршрут для авторизации
	router.HandleFunc("/register", RegisterHandler).Methods("POST")                       // Добавляем маршрут для регистрации
	router.HandleFunc("/change_pfc", ChangePFCHandler).Methods("POST")                    //изменяем бжу пользователя
	router.HandleFunc("/get_lists", GetListsHandler).Methods("POST")                      //изменяем бжу пользователя
	router.HandleFunc("/add_dish", AddDishHandler).Methods("POST")                        //изменяем бжу пользователя
	router.HandleFunc("/add_exercise", AddExerciseHandler).Methods("POST")                //изменяем бжу пользователя
	router.HandleFunc("/appointments", GetAppointmentsHandler).Methods("POST")            //изменяем бжу пользователя
	router.HandleFunc("/add_appointment", AddAppointment).Methods("POST")                 //изменяем бжу пользователя
	router.HandleFunc("/delete_appointment", DeleteAppointment).Methods("POST")           //изменяем бжу пользователя
	router.HandleFunc("/fetch_eatings", FetchEatings).Methods("POST")                     //изменяем бжу пользователя
	router.HandleFunc("/add_eating", AddEating).Methods("POST")                           //изменяем бжу пользователя
	router.HandleFunc("/delete_eating", DeleteEating).Methods("POST")                     //изменяем бжу пользователя
	router.HandleFunc("/change_running", ChangeRunning).Methods("POST")                   //изменяем бжу пользователя
	router.HandleFunc("/change_eating", ChangeEating).Methods("POST")                     //изменяем бжу пользователя
	router.HandleFunc("/fetch_exercises", FetchExercises).Methods("POST")                 //изменяем бжу пользователя
	router.HandleFunc("/add_exercise_to_training", AddExerciseToTraining).Methods("POST") //изменяем бжу пользователя
	router.HandleFunc("/add_set", AddSetToExercise).Methods("POST")                       //изменяем бжу пользователя
	router.HandleFunc("/update_set", UpdateSetValues).Methods("POST")                     //изменяем бжу пользователя
	router.HandleFunc("/delete_set", DeleteSet).Methods("POST")                           //изменяем бжу пользователя
	router.HandleFunc("/delete_exercise", DeleteExercise).Methods("POST")                 //изменяем бжу пользователя

	log.Fatal(http.ListenAndServe(":8080", router)) // Запускаем HTTP-сервер на порту 8080 и обрабатываем запросы
}
