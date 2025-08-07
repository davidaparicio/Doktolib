package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
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

type Prescription struct {
	ID            string    `json:"id"`
	AppointmentID string    `json:"appointment_id"`
	DoctorID      string    `json:"doctor_id"`
	PatientName   string    `json:"patient_name"`
	Medications   string    `json:"medications"`
	Dosage        string    `json:"dosage"`
	Instructions  string    `json:"instructions"`
	CreatedAt     time.Time `json:"created_at"`
}

type CreatePrescriptionRequest struct {
	AppointmentID string `json:"appointment_id" binding:"required"`
	Medications   string `json:"medications" binding:"required"`
	Dosage        string `json:"dosage" binding:"required"`
	Instructions  string `json:"instructions"`
}

type AppointmentWithPatientAndPrescription struct {
	ID            string        `json:"id"`
	DoctorID      string        `json:"doctor_id"`
	PatientName   string        `json:"patient_name"`
	PatientEmail  string        `json:"patient_email"`
	DateTime      time.Time     `json:"date_time"`
	Duration      int           `json:"duration_minutes"`
	Status        string        `json:"status"`
	CreatedAt     time.Time     `json:"created_at"`
	Prescription  *Prescription `json:"prescription,omitempty"`
}

var db *sql.DB

func initDB() {
	var err error
	databaseURL := os.Getenv("DATABASE_URL")
	
	// Default local development configuration
	if databaseURL == "" {
		databaseURL = "postgres://doktolib:password123@localhost:5432/doktolib?sslmode=disable"
	} else {
		// Configure SSL mode based on environment variables
		databaseURL = configureSSLMode(databaseURL)
	}

	log.Printf("Connecting to database with URL: %s", maskPassword(databaseURL))

	db, err = sql.Open("postgres", databaseURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("Successfully connected to database")
}

// configureSSLMode adds or modifies SSL configuration in the database URL
func configureSSLMode(databaseURL string) string {
	sslMode := os.Getenv("DB_SSL_MODE")
	if sslMode == "" {
		sslMode = "disable" // Default to disable for compatibility
	}

	// Parse the URL
	u, err := url.Parse(databaseURL)
	if err != nil {
		log.Printf("Warning: Could not parse DATABASE_URL, using as-is: %v", err)
		return databaseURL
	}

	// Get existing query parameters
	query := u.Query()
	
	// Set or update sslmode
	query.Set("sslmode", sslMode)
	
	// Add additional SSL parameters if needed
	if sslMode != "disable" {
		// Set SSL cert configuration if provided
		if sslCert := os.Getenv("DB_SSL_CERT"); sslCert != "" {
			query.Set("sslcert", sslCert)
		}
		if sslKey := os.Getenv("DB_SSL_KEY"); sslKey != "" {
			query.Set("sslkey", sslKey)
		}
		if sslRootCert := os.Getenv("DB_SSL_ROOT_CERT"); sslRootCert != "" {
			query.Set("sslrootcert", sslRootCert)
		}
	}

	// Rebuild the URL
	u.RawQuery = query.Encode()
	return u.String()
}

// maskPassword hides the password in database URL for logging
func maskPassword(databaseURL string) string {
	u, err := url.Parse(databaseURL)
	if err != nil {
		return databaseURL
	}
	
	if u.User != nil && u.User.Username() != "" {
		if _, hasPassword := u.User.Password(); hasPassword {
			u.User = url.UserPassword(u.User.Username(), "***")
		}
	}
	
	return u.String()
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

func getDoctorAppointments(c *gin.Context) {
	doctorID := c.Param("doctorId")
	filter := c.Query("filter") // "past", "today", "future"
	
	query := `
		SELECT a.id, a.doctor_id, a.patient_name, a.patient_email, a.date_time, a.duration_minutes, a.status, a.created_at,
		       p.id, p.medications, p.dosage, p.instructions, p.created_at
		FROM appointments a
		LEFT JOIN prescriptions p ON a.id = p.appointment_id
		WHERE a.doctor_id = $1
	`
	
	// Add date filtering
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	tomorrow := today.AddDate(0, 0, 1)
	
	switch filter {
	case "past":
		query += " AND a.date_time < $2"
	case "today":
		query += " AND a.date_time >= $2 AND a.date_time < $3"
	case "future":
		query += " AND a.date_time >= $2"
	}
	
	query += " ORDER BY a.date_time DESC"
	
	var rows *sql.Rows
	var err error
	
	switch filter {
	case "past":
		rows, err = db.Query(query, doctorID, today)
	case "today":
		rows, err = db.Query(query, doctorID, today, tomorrow)
	case "future":
		rows, err = db.Query(query, doctorID, tomorrow)
	default:
		rows, err = db.Query(query[:len(query)-25]+" ORDER BY a.date_time DESC", doctorID) // Remove WHERE clause
	}
	
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch appointments"})
		return
	}
	defer rows.Close()

	var appointments []AppointmentWithPatientAndPrescription
	for rows.Next() {
		var appointment AppointmentWithPatientAndPrescription
		var prescriptionID sql.NullString
		var medications sql.NullString
		var dosage sql.NullString
		var instructions sql.NullString
		var prescriptionCreatedAt sql.NullTime
		
		err := rows.Scan(
			&appointment.ID,
			&appointment.DoctorID,
			&appointment.PatientName,
			&appointment.PatientEmail,
			&appointment.DateTime,
			&appointment.Duration,
			&appointment.Status,
			&appointment.CreatedAt,
			&prescriptionID,
			&medications,
			&dosage,
			&instructions,
			&prescriptionCreatedAt,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan appointment"})
			return
		}
		
		// Add prescription if exists
		if prescriptionID.Valid {
			appointment.Prescription = &Prescription{
				ID:            prescriptionID.String,
				AppointmentID: appointment.ID,
				DoctorID:      appointment.DoctorID,
				PatientName:   appointment.PatientName,
				Medications:   medications.String,
				Dosage:        dosage.String,
				Instructions:  instructions.String,
				CreatedAt:     prescriptionCreatedAt.Time,
			}
		}
		
		appointments = append(appointments, appointment)
	}

	c.JSON(http.StatusOK, appointments)
}

func createPrescription(c *gin.Context) {
	var req CreatePrescriptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify appointment exists and get doctor and patient info
	var appointment Appointment
	err := db.QueryRow(`
		SELECT id, doctor_id, patient_name, patient_email, date_time, duration_minutes, status, created_at
		FROM appointments WHERE id = $1
	`, req.AppointmentID).Scan(
		&appointment.ID, &appointment.DoctorID, &appointment.PatientName,
		&appointment.PatientEmail, &appointment.DateTime, &appointment.Duration,
		&appointment.Status, &appointment.CreatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Appointment not found"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch appointment"})
		return
	}

	prescriptionID := uuid.New().String()

	query := `
		INSERT INTO prescriptions (id, appointment_id, doctor_id, patient_name, medications, dosage, instructions, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, appointment_id, doctor_id, patient_name, medications, dosage, instructions, created_at
	`

	var prescription Prescription
	err = db.QueryRow(
		query,
		prescriptionID,
		req.AppointmentID,
		appointment.DoctorID,
		appointment.PatientName,
		req.Medications,
		req.Dosage,
		req.Instructions,
		time.Now(),
	).Scan(
		&prescription.ID,
		&prescription.AppointmentID,
		&prescription.DoctorID,
		&prescription.PatientName,
		&prescription.Medications,
		&prescription.Dosage,
		&prescription.Instructions,
		&prescription.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create prescription"})
		return
	}

	c.JSON(http.StatusCreated, prescription)
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
		api.GET("/doctors/:doctorId/appointments", getDoctorAppointments)
		api.POST("/appointments", createAppointment)
		api.GET("/appointments", getAppointments)
		api.POST("/prescriptions", createPrescription)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}