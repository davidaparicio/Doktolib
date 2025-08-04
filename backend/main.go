package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

type Doctor struct {
	ID           string  `json:"id"`
	Name         string  `json:"name"`
	Specialty    string  `json:"specialty"`
	Location     string  `json:"location"`
	Rating       float64 `json:"rating"`
	PricePerHour int     `json:"price_per_hour"`
	Avatar       string  `json:"avatar"`
	Experience   int     `json:"experience_years"`
	Languages    string  `json:"languages"`
}

type Appointment struct {
	ID        string    `json:"id"`
	DoctorID  string    `json:"doctor_id"`
	PatientName string  `json:"patient_name"`
	PatientEmail string `json:"patient_email"`
	DateTime  time.Time `json:"date_time"`
	Duration  int       `json:"duration_minutes"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

type CreateAppointmentRequest struct {
	DoctorID     string `json:"doctor_id" binding:"required"`
	PatientName  string `json:"patient_name" binding:"required"`
	PatientEmail string `json:"patient_email" binding:"required"`
	DateTime     string `json:"date_time" binding:"required"`
	Duration     int    `json:"duration_minutes" binding:"required"`
}

var db *sql.DB

func initDB() {
	var err error
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		databaseURL = "postgres://doktolib:password123@localhost:5432/doktolib?sslmode=disable"
	}

	db, err = sql.Open("postgres", databaseURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("Successfully connected to database")
}

func getDoctors(c *gin.Context) {
	specialty := c.Query("specialty")
	location := c.Query("location")

	query := `
		SELECT id, name, specialty, location, rating, price_per_hour, avatar, experience_years, languages 
		FROM doctors 
		WHERE 1=1
	`
	args := []interface{}{}
	argCount := 0

	if specialty != "" {
		argCount++
		query += fmt.Sprintf(" AND LOWER(specialty) LIKE LOWER($%d)", argCount)
		args = append(args, "%"+specialty+"%")
	}

	if location != "" {
		argCount++
		query += fmt.Sprintf(" AND LOWER(location) LIKE LOWER($%d)", argCount)
		args = append(args, "%"+location+"%")
	}

	query += " ORDER BY rating DESC, name ASC"

	rows, err := db.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch doctors"})
		return
	}
	defer rows.Close()

	var doctors []Doctor
	for rows.Next() {
		var doctor Doctor
		err := rows.Scan(
			&doctor.ID, &doctor.Name, &doctor.Specialty, &doctor.Location,
			&doctor.Rating, &doctor.PricePerHour, &doctor.Avatar,
			&doctor.Experience, &doctor.Languages,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan doctor"})
			return
		}
		doctors = append(doctors, doctor)
	}

	c.JSON(http.StatusOK, doctors)
}

func getDoctorByID(c *gin.Context) {
	id := c.Param("id")

	query := `
		SELECT id, name, specialty, location, rating, price_per_hour, avatar, experience_years, languages 
		FROM doctors 
		WHERE id = $1
	`

	var doctor Doctor
	err := db.QueryRow(query, id).Scan(
		&doctor.ID, &doctor.Name, &doctor.Specialty, &doctor.Location,
		&doctor.Rating, &doctor.PricePerHour, &doctor.Avatar,
		&doctor.Experience, &doctor.Languages,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Doctor not found"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch doctor"})
		return
	}

	c.JSON(http.StatusOK, doctor)
}

func createAppointment(c *gin.Context) {
	var req CreateAppointmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	appointmentTime, err := time.Parse("2006-01-02T15:04:05Z", req.DateTime)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format"})
		return
	}

	if appointmentTime.Before(time.Now()) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot book appointments in the past"})
		return
	}

	appointmentID := uuid.New().String()

	query := `
		INSERT INTO appointments (id, doctor_id, patient_name, patient_email, date_time, duration_minutes, status, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, doctor_id, patient_name, patient_email, date_time, duration_minutes, status, created_at
	`

	var appointment Appointment
	err = db.QueryRow(
		query,
		appointmentID,
		req.DoctorID,
		req.PatientName,
		req.PatientEmail,
		appointmentTime,
		req.Duration,
		"confirmed",
		time.Now(),
	).Scan(
		&appointment.ID,
		&appointment.DoctorID,
		&appointment.PatientName,
		&appointment.PatientEmail,
		&appointment.DateTime,
		&appointment.Duration,
		&appointment.Status,
		&appointment.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create appointment"})
		return
	}

	c.JSON(http.StatusCreated, appointment)
}

func getAppointments(c *gin.Context) {
	doctorID := c.Query("doctor_id")
	
	query := `
		SELECT a.id, a.doctor_id, a.patient_name, a.patient_email, a.date_time, a.duration_minutes, a.status, a.created_at
		FROM appointments a
		WHERE 1=1
	`
	args := []interface{}{}
	
	if doctorID != "" {
		query += " AND a.doctor_id = $1"
		args = append(args, doctorID)
	}
	
	query += " ORDER BY a.date_time ASC"

	rows, err := db.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch appointments"})
		return
	}
	defer rows.Close()

	var appointments []Appointment
	for rows.Next() {
		var appointment Appointment
		err := rows.Scan(
			&appointment.ID,
			&appointment.DoctorID,
			&appointment.PatientName,
			&appointment.PatientEmail,
			&appointment.DateTime,
			&appointment.Duration,
			&appointment.Status,
			&appointment.CreatedAt,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan appointment"})
			return
		}
		appointments = append(appointments, appointment)
	}

	c.JSON(http.StatusOK, appointments)
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "healthy",
		"timestamp": time.Now(),
		"service": "doktolib-backend",
	})
}

func main() {
	godotenv.Load()
	
	initDB()
	defer db.Close()

	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization"}
	r.Use(cors.New(config))

	api := r.Group("/api/v1")
	{
		api.GET("/health", healthCheck)
		api.GET("/doctors", getDoctors)
		api.GET("/doctors/:id", getDoctorByID)
		api.POST("/appointments", createAppointment)
		api.GET("/appointments", getAppointments)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}