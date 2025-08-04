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
    languages TEXT DEFAULT 'French',
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
('Dr. Marie Dubois', 'Médecin généraliste', 'Paris 1er', 4.8, 60, 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face', 15, 'Français, Anglais'),
('Dr. Jean Martin', 'Cardiologue', 'Paris 8ème', 4.9, 120, 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face', 20, 'Français'),
('Dr. Sophie Laurent', 'Dermatologue', 'Paris 16ème', 4.7, 80, 'https://images.unsplash.com/photo-1594824072407-1cb42b80ef54?w=400&h=400&fit=crop&crop=face', 12, 'Français, Anglais, Espagnol'),
('Dr. Pierre Moreau', 'Dentiste', 'Paris 3ème', 4.6, 90, 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=400&fit=crop&crop=face', 18, 'Français'),
('Dr. Claire Bernard', 'Gynécologue', 'Paris 14ème', 4.9, 100, 'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400&h=400&fit=crop&crop=face', 22, 'Français, Anglais'),
('Dr. Antoine Leroy', 'Ophtalmologue', 'Paris 7ème', 4.8, 110, 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=400&fit=crop&crop=face', 16, 'Français, Italiano'),
('Dr. Isabelle Petit', 'Pédiatre', 'Paris 12ème', 4.9, 70, 'https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=400&h=400&fit=crop&crop=face', 14, 'Français, Anglais'),
('Dr. Michel Rousseau', 'Psychiatre', 'Paris 5ème', 4.7, 85, 'https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?w=400&h=400&fit=crop&crop=face', 25, 'Français'),
('Dr. Nathalie Blanc', 'Neurologue', 'Paris 13ème', 4.8, 130, 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=400&fit=crop&crop=face', 19, 'Français, Anglais'),
('Dr. Vincent Garnier', 'Orthopédiste', 'Paris 10ème', 4.6, 140, 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&h=400&fit=crop&crop=face', 17, 'Français, Allemand');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON doctors(specialty);
CREATE INDEX IF NOT EXISTS idx_doctors_location ON doctors(location);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date_time ON appointments(date_time);