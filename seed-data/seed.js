#!/usr/bin/env node

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function connectToDatabase(retries = 10) {
  for (let i = 0; i < retries; i++) {
    const client = new Client({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.DB_SSL_MODE === 'disable' ? false : { rejectUnauthorized: false }
    });

    try {
      console.log(`🔌 Attempting to connect to database (attempt ${i + 1}/${retries})...`);
      await client.connect();
      console.log('✅ Connected to database successfully');
      return client;
    } catch (error) {
      console.log(`❌ Connection failed: ${error.message}`);
      await client.end().catch(() => {}); // Cleanup failed connection
      
      if (i === retries - 1) {
        throw error;
      }
      console.log(`⏳ Retrying in 5 seconds...`);
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
}

async function checkExistingDoctors(client) {
  try {
    const result = await client.query('SELECT COUNT(*) as count FROM doctors');
    const count = parseInt(result.rows[0].count);
    console.log(`📊 Found ${count} existing doctors in database`);
    return count;
  } catch (error) {
    console.log('ℹ️ Doctors table may not exist yet, will be created during migration');
    return 0;
  }
}

async function seedDatabase(client, force = false) {
  try {
    // Check if we should skip seeding
    const existingCount = await checkExistingDoctors(client);
    
    if (existingCount > 10 && !force) {
      console.log(`⏭️ Database already has ${existingCount} doctors, skipping seed`);
      console.log('   Use FORCE_SEED=true to override');
      return;
    }

    if (force && existingCount > 0) {
      console.log(`🗑️ Force mode: clearing ${existingCount} existing doctors...`);
      await client.query('DELETE FROM doctors');
      console.log('✅ Existing doctors cleared');
    }

    // Generate doctors
    console.log('🏥 Generating seed data...');
    const { generateDoctors } = require('./generate-doctors.js');
    const doctorCount = parseInt(process.env.DOCTOR_COUNT) || 1500;
    const doctors = generateDoctors(doctorCount);
    
    console.log(`💉 Inserting ${doctors.length} doctors into database...`);
    
    // Insert in batches for better performance
    const batchSize = 100;
    let insertedCount = 0;
    
    for (let i = 0; i < doctors.length; i += batchSize) {
      const batch = doctors.slice(i, i + batchSize);
      
      const values = batch.map((doctor, index) => {
        const baseIndex = i * 8 + index * 8;
        return `($${baseIndex + 1}, $${baseIndex + 2}, $${baseIndex + 3}, $${baseIndex + 4}, $${baseIndex + 5}, $${baseIndex + 6}, $${baseIndex + 7}, $${baseIndex + 8})`;
      }).join(', ');
      
      const params = batch.flatMap(doctor => [
        doctor.name,
        doctor.specialty,
        doctor.location,
        doctor.rating,
        doctor.price_per_hour,
        doctor.avatar,
        doctor.experience_years,
        doctor.languages
      ]);
      
      const query = `
        INSERT INTO doctors (name, specialty, location, rating, price_per_hour, avatar, experience_years, languages)
        VALUES ${values}
      `;
      
      await client.query(query, params);
      insertedCount += batch.length;
      
      console.log(`   📝 Inserted ${insertedCount}/${doctors.length} doctors...`);
    }
    
    // Create indexes
    console.log('🔍 Creating indexes for better performance...');
    await client.query('CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON doctors(specialty)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_doctors_location ON doctors(location)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_doctors_rating ON doctors(rating DESC)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_doctors_price ON doctors(price_per_hour)');
    
    // Get statistics
    const stats = await client.query(`
      SELECT 
        COUNT(*) as total_doctors,
        COUNT(DISTINCT specialty) as specialties_count,
        COUNT(DISTINCT location) as locations_count,
        ROUND(AVG(rating), 2) as avg_rating,
        ROUND(AVG(price_per_hour), 2) as avg_price,
        ROUND(AVG(experience_years), 2) as avg_experience
      FROM doctors
    `);
    
    const row = stats.rows[0];
    console.log(`\n📊 Seeding completed successfully!`);
    console.log(`- Total doctors: ${row.total_doctors}`);
    console.log(`- Specialties: ${row.specialties_count}`);
    console.log(`- Locations: ${row.locations_count}`);
    console.log(`- Average rating: ${row.avg_rating}`);
    console.log(`- Average price: €${row.avg_price}`);
    console.log(`- Average experience: ${row.avg_experience} years`);
    
  } catch (error) {
    console.error('❌ Error during seeding:', error);
    throw error;
  }
}

async function main() {
  console.log('🌱 Doktolib Database Seeder');
  console.log('===========================');
  
  // Check required environment variables
  if (!process.env.DATABASE_URL) {
    console.error('❌ DATABASE_URL environment variable is required');
    process.exit(1);
  }
  
  const force = process.env.FORCE_SEED === 'true';
  const doctorCount = parseInt(process.env.DOCTOR_COUNT) || 1500;
  
  console.log(`🔧 Configuration:`);
  console.log(`- Database URL: ${process.env.DATABASE_URL.replace(/\/\/[^:]+:[^@]+@/, '//***:***@')}`);
  console.log(`- SSL Mode: ${process.env.DB_SSL_MODE || 'default'}`);
  console.log(`- Doctor Count: ${doctorCount}`);
  console.log(`- Force Mode: ${force}`);
  
  let client;
  
  try {
    client = await connectToDatabase();
    await seedDatabase(client, force);
    console.log('\n🎉 Database seeding completed successfully!');
    
  } catch (error) {
    console.error('\n💥 Seeding failed:', error.message);
    process.exit(1);
    
  } finally {
    if (client) {
      await client.end();
      console.log('🔌 Database connection closed');
    }
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n⚠️ Received SIGINT, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n⚠️ Received SIGTERM, shutting down gracefully...');
  process.exit(0);
});

if (require.main === module) {
  main();
}