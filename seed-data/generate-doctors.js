#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// French names and medical specialties
const firstNames = {
  male: [
    'Pierre', 'Jean', 'Michel', 'Philippe', 'Alain', 'Bernard', 'Robert', 'Jacques', 'Daniel', 'Christophe',
    'François', 'Paul', 'Nicolas', 'Marc', 'David', 'Thierry', 'Laurent', 'Patrick', 'Olivier', 'Antoine',
    'Julien', 'Sébastien', 'Frédéric', 'Stéphane', 'Vincent', 'Emmanuel', 'Bruno', 'Thomas', 'Maxime', 'Alexandre',
    'Jérôme', 'Florian', 'Romain', 'Mathieu', 'Damien', 'Fabrice', 'Ludovic', 'Cédric', 'Guillaume', 'Yann',
    'Arnaud', 'Éric', 'Didier', 'Gérard', 'Hervé', 'Serge', 'Claude', 'Henri', 'André', 'Raymond'
  ],
  female: [
    'Marie', 'Nathalie', 'Isabelle', 'Sylvie', 'Catherine', 'Françoise', 'Anne', 'Brigitte', 'Monique', 'Christine',
    'Sophie', 'Valérie', 'Sandrine', 'Céline', 'Martine', 'Véronique', 'Caroline', 'Stéphanie', 'Dominique', 'Patricia',
    'Julie', 'Amélie', 'Émilie', 'Laure', 'Aurélie', 'Claire', 'Hélène', 'Camille', 'Pauline', 'Lucie',
    'Delphine', 'Florence', 'Karine', 'Muriel', 'Corinne', 'Élise', 'Agnès', 'Nadine', 'Chantal', 'Laurence',
    'Béatrice', 'Pascale', 'Odile', 'Nicole', 'Denise', 'Jacqueline', 'Michèle', 'Colette', 'Yvette', 'Simone'
  ]
};

const lastNames = [
  'Martin', 'Bernard', 'Dubois', 'Thomas', 'Robert', 'Richard', 'Petit', 'Durand', 'Leroy', 'Moreau',
  'Simon', 'Laurent', 'Lefebvre', 'Michel', 'Garcia', 'David', 'Bertrand', 'Roux', 'Vincent', 'Fournier',
  'Morel', 'Girard', 'André', 'Lefèvre', 'Mercier', 'Dupont', 'Lambert', 'Bonnet', 'François', 'Martinez',
  'Legrand', 'Garnier', 'Faure', 'Rousseau', 'Blanc', 'Guerin', 'Muller', 'Henry', 'Roussel', 'Nicolas',
  'Perrin', 'Morin', 'Mathieu', 'Clement', 'Gauthier', 'Dumont', 'Lopez', 'Fontaine', 'Chevalier', 'Robin',
  'Masson', 'Sanchez', 'Gerard', 'Nguyen', 'Boyer', 'Denis', 'Lemaire', 'Duval', 'Joly', 'Gautier',
  'Roger', 'Roche', 'Roy', 'Noel', 'Meyer', 'Lucas', 'Meunier', 'Jean', 'Perez', 'Marchand',
  'Dufour', 'Blanchard', 'Marie', 'Barbier', 'Brun', 'Dumas', 'Brunet', 'Schmitt', 'Leroux', 'Colin'
];

const specialties = [
  'Médecin généraliste', 'Cardiologue', 'Dermatologue', 'Gynécologue', 'Pédiatre', 'Psychiatre', 'Neurologue',
  'Ophtalmologue', 'ORL', 'Orthopédiste', 'Rhumatologue', 'Endocrinologue', 'Gastro-entérologue', 'Pneumologue',
  'Urologue', 'Chirurgien', 'Anesthésiste', 'Radiologue', 'Oncologue', 'Dentiste', 'Orthodontiste',
  'Chirurgien-dentiste', 'Kinésithérapeute', 'Ostéopathe', 'Sage-femme', 'Infirmier', 'Pharmacien',
  'Allergologue', 'Gériatre', 'Néphrologue', 'Hématologue', 'Infectiologue', 'Médecin du travail',
  'Médecin urgentiste', 'Réanimateur', 'Pathologiste', 'Médecin légiste', 'Addictologue', 'Sexologue'
];

const parisDistricts = [
  'Paris 1er', 'Paris 2ème', 'Paris 3ème', 'Paris 4ème', 'Paris 5ème', 'Paris 6ème', 'Paris 7ème', 'Paris 8ème',
  'Paris 9ème', 'Paris 10ème', 'Paris 11ème', 'Paris 12ème', 'Paris 13ème', 'Paris 14ème', 'Paris 15ème', 'Paris 16ème',
  'Paris 17ème', 'Paris 18ème', 'Paris 19ème', 'Paris 20ème', 'Boulogne-Billancourt', 'Saint-Denis', 'Argenteuil',
  'Montreuil', 'Créteil', 'Nanterre', 'Asnières-sur-Seine', 'Versailles', 'Courbevoie', 'Vitry-sur-Seine',
  'Champigny-sur-Marne', 'Rueil-Malmaison', 'Aubervilliers', 'Levallois-Perret', 'Issy-les-Moulineaux',
  'Antony', 'Neuilly-sur-Seine', 'Clichy', 'Ivry-sur-Seine', 'Villejuif'
];

const languages = [
  'Français', 'Français, Anglais', 'Français, Espagnol', 'Français, Italien', 'Français, Allemand',
  'Français, Arabe', 'Français, Portugais', 'Français, Anglais, Espagnol', 'Français, Anglais, Italien',
  'Français, Anglais, Allemand', 'Français, Mandarin', 'Français, Russe', 'Français, Japonais'
];

// Avatar URLs from diverse professional photos
const avatarUrls = [
  'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1594824072407-1cb42b80ef54?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1607990281513-2c110a25bd8c?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1612531386530-497d5dc1c7cd?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1643297654632-0cc29dd2b1a8?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1584467735871-8e1810b4ed2d?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1577202214328-c04b77cefb5d?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1527613426441-4da17471b66d?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1545167622-3a6ac756afa4?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1619946794135-5bc917a27793?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1651008376811-b98baee60c1f?w=400&h=400&fit=crop&crop=face',
  'https://images.unsplash.com/photo-1612835362596-72ee7aa8d0b0?w=400&h=400&fit=crop&crop=face'
];

function getRandomElement(array) {
  return array[Math.floor(Math.random() * array.length)];
}

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function getRandomFloat(min, max, decimals = 1) {
  return +(Math.random() * (max - min) + min).toFixed(decimals);
}

function generateDoctor(id) {
  const isWoman = Math.random() > 0.4; // 60% women, 40% men (realistic for medical field)
  const gender = isWoman ? 'female' : 'male';
  const firstName = getRandomElement(firstNames[gender]);
  const lastName = getRandomElement(lastNames);
  const specialty = getRandomElement(specialties);
  const location = getRandomElement(parisDistricts);
  
  // Rating distribution: mostly 4.0-5.0, few lower
  const rating = Math.random() > 0.1 ? getRandomFloat(4.0, 5.0) : getRandomFloat(3.0, 4.0);
  
  // Price based on specialty (specialists cost more)
  const specialistSpecialties = ['Cardiologue', 'Neurologue', 'Chirurgien', 'Oncologue', 'Ophtalmologue'];
  const isSpecialist = specialistSpecialties.includes(specialty);
  const basePrice = isSpecialist ? getRandomInt(100, 200) : getRandomInt(50, 120);
  
  // Experience years
  const experienceYears = getRandomInt(3, 40);
  
  // Languages
  const language = getRandomElement(languages);
  
  // Avatar
  const avatar = getRandomElement(avatarUrls);
  
  return {
    id: id,
    name: `Dr. ${firstName} ${lastName}`,
    specialty: specialty,
    location: location,
    rating: rating,
    price_per_hour: basePrice,
    avatar: avatar,
    experience_years: experienceYears,
    languages: language
  };
}

function generateDoctors(count) {
  console.log(`Generating ${count} doctors...`);
  const doctors = [];
  
  for (let i = 1; i <= count; i++) {
    doctors.push(generateDoctor(i));
    
    if (i % 100 === 0) {
      console.log(`Generated ${i}/${count} doctors...`);
    }
  }
  
  return doctors;
}

function generateSQL(doctors) {
  console.log('Generating SQL statements...');
  
  let sql = `-- Generated seed data for ${doctors.length} doctors
-- This file contains INSERT statements to populate the doctors table

BEGIN;

-- Clear existing data (optional - remove if you want to keep existing doctors)
-- DELETE FROM doctors;

-- Insert doctors
`;

  // Split into batches of 100 for better performance
  const batchSize = 100;
  for (let i = 0; i < doctors.length; i += batchSize) {
    const batch = doctors.slice(i, i + batchSize);
    
    sql += `\n-- Batch ${Math.floor(i / batchSize) + 1}\n`;
    sql += 'INSERT INTO doctors (name, specialty, location, rating, price_per_hour, avatar, experience_years, languages) VALUES\n';
    
    const values = batch.map(doctor => 
      `  ('${doctor.name.replace(/'/g, "''")}', '${doctor.specialty}', '${doctor.location}', ${doctor.rating}, ${doctor.price_per_hour}, '${doctor.avatar}', ${doctor.experience_years}, '${doctor.languages.replace(/'/g, "''")}')`
    );
    
    sql += values.join(',\n') + ';\n';
  }

  sql += `
-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON doctors(specialty);
CREATE INDEX IF NOT EXISTS idx_doctors_location ON doctors(location);
CREATE INDEX IF NOT EXISTS idx_doctors_rating ON doctors(rating DESC);
CREATE INDEX IF NOT EXISTS idx_doctors_price ON doctors(price_per_hour);

COMMIT;

-- Statistics
SELECT 
  COUNT(*) as total_doctors,
  COUNT(DISTINCT specialty) as specialties_count,
  COUNT(DISTINCT location) as locations_count,
  ROUND(AVG(rating), 2) as avg_rating,
  ROUND(AVG(price_per_hour), 2) as avg_price,
  ROUND(AVG(experience_years), 2) as avg_experience
FROM doctors;
`;

  return sql;
}

function main() {
  const doctorCount = parseInt(process.argv[2]) || 1500;
  
  console.log(`🏥 Doktolib Seed Data Generator`);
  console.log(`===============================`);
  console.log(`Generating ${doctorCount} doctors with realistic French data...`);
  
  const doctors = generateDoctors(doctorCount);
  const sql = generateSQL(doctors);
  
  // Write SQL file
  const sqlPath = path.join(__dirname, 'doctors-seed.sql');
  fs.writeFileSync(sqlPath, sql, 'utf8');
  console.log(`✅ SQL file written to: ${sqlPath}`);
  
  // Write JSON file for reference
  const jsonPath = path.join(__dirname, 'doctors-seed.json');
  fs.writeFileSync(jsonPath, JSON.stringify(doctors, null, 2), 'utf8');
  console.log(`✅ JSON file written to: ${jsonPath}`);
  
  // Statistics
  const specialtyStats = {};
  const locationStats = {};
  
  doctors.forEach(doctor => {
    specialtyStats[doctor.specialty] = (specialtyStats[doctor.specialty] || 0) + 1;
    locationStats[doctor.location] = (locationStats[doctor.location] || 0) + 1;
  });
  
  console.log(`\n📊 Statistics:`);
  console.log(`- Total doctors: ${doctors.length}`);
  console.log(`- Specialties: ${Object.keys(specialtyStats).length}`);
  console.log(`- Locations: ${Object.keys(locationStats).length}`);
  console.log(`- Average rating: ${(doctors.reduce((sum, d) => sum + d.rating, 0) / doctors.length).toFixed(2)}`);
  console.log(`- Average price: €${Math.round(doctors.reduce((sum, d) => sum + d.price_per_hour, 0) / doctors.length)}`);
  console.log(`- Average experience: ${Math.round(doctors.reduce((sum, d) => sum + d.experience_years, 0) / doctors.length)} years`);
  
  console.log(`\n🚀 Ready for deployment!`);
  console.log(`Run the seed script with: node seed.js`);
}

if (require.main === module) {
  main();
}

module.exports = { generateDoctors, generateSQL };