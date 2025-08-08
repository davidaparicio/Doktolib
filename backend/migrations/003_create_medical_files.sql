-- Migration: Create medical_files table for S3 file uploads
-- This table stores metadata for medical files uploaded to S3

CREATE TABLE IF NOT EXISTS medical_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id VARCHAR(255) NOT NULL,
    patient_name VARCHAR(255) NOT NULL,
    file_name VARCHAR(500) NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    s3_key VARCHAR(1000) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'other',
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_medical_files_patient_id ON medical_files(patient_id);
CREATE INDEX IF NOT EXISTS idx_medical_files_category ON medical_files(category);
CREATE INDEX IF NOT EXISTS idx_medical_files_uploaded_at ON medical_files(uploaded_at);

-- Comments for documentation
COMMENT ON TABLE medical_files IS 'Stores metadata for medical files uploaded to AWS S3';
COMMENT ON COLUMN medical_files.patient_id IS 'Unique identifier for the patient';
COMMENT ON COLUMN medical_files.patient_name IS 'Full name of the patient for easy reference';
COMMENT ON COLUMN medical_files.file_name IS 'Original filename as uploaded by user';
COMMENT ON COLUMN medical_files.file_type IS 'MIME type of the uploaded file';
COMMENT ON COLUMN medical_files.file_size IS 'Size of the file in bytes';
COMMENT ON COLUMN medical_files.s3_key IS 'S3 object key for file location';
COMMENT ON COLUMN medical_files.category IS 'File category: lab_results, insurance, prescription, medical_records, other';