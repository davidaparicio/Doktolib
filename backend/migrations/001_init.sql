-- Create doctors table
CREATE TABLE IF NOT EXISTS doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    specialty VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    rating DECIMAL(3,2) DEFAULT 0.0,
    price_per_hour INTEGER DEFAULT 0,
    avatar TEXT,
    experience_years INTEGER DEFAULT 0,
    languages TEXT DEFAULT 'English',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID NOT NULL REFERENCES doctors(id),
    patient_name VARCHAR(255) NOT NULL,
    patient_email VARCHAR(255) NOT NULL,
    date_time TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status VARCHAR(50) DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample doctors
INSERT INTO doctors (name, specialty, location, rating, price_per_hour, avatar, experience_years, languages) VALUES
('Dr. Sandra Jackson', 'General Practitioner', 'New York, NY', 4.8, 60, 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face', 15, 'English, Spanish'),
('Dr. James Wilson', 'Cardiologist', 'Los Angeles, CA', 4.9, 120, 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face', 20, 'English'),
('Dr. Jennifer Brown', 'Dermatologist', 'Chicago, IL', 4.7, 80, 'https://images.unsplash.com/photo-1594824072407-1cb42b80ef54?w=400&h=400&fit=crop&crop=face', 12, 'English, Spanish, French'),
('Dr. Michael Davis', 'Dentist', 'Houston, TX', 4.6, 90, 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=400&fit=crop&crop=face', 18, 'English'),
('Dr. Sarah Martinez', 'Gynecologist', 'Phoenix, AZ', 4.9, 100, 'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400&h=400&fit=crop&crop=face', 22, 'English, Spanish'),
('Dr. Robert Johnson', 'Ophthalmologist', 'Philadelphia, PA', 4.8, 110, 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=400&fit=crop&crop=face', 16, 'English, Italian'),
('Dr. Linda Garcia', 'Pediatrician', 'San Antonio, TX', 4.9, 70, 'https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=400&h=400&fit=crop&crop=face', 14, 'English, Spanish'),
('Dr. David Miller', 'Psychiatrist', 'San Diego, CA', 4.7, 85, 'https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?w=400&h=400&fit=crop&crop=face', 25, 'English'),
('Dr. Mary Rodriguez', 'Neurologist', 'Dallas, TX', 4.8, 130, 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=400&fit=crop&crop=face', 19, 'English, Spanish'),
('Dr. Thomas Anderson', 'Orthopedist', 'San Jose, CA', 4.6, 140, 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&h=400&fit=crop&crop=face', 17, 'English, German');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON doctors(specialty);
CREATE INDEX IF NOT EXISTS idx_doctors_location ON doctors(location);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date_time ON appointments(date_time);