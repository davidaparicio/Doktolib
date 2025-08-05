#!/usr/bin/env node

const { Client } = require('pg');

function getSSLConfig(sslMode) {
  console.log(`🔒 Testing SSL Mode: ${sslMode}`);
  
  switch (sslMode.toLowerCase()) {
    case 'disable':
      return false;
    
    case 'require':
      return { rejectUnauthorized: false };
    
    case 'verify-ca':
      return {
        rejectUnauthorized: true,
        ca: process.env.DB_SSL_ROOT_CERT ? [process.env.DB_SSL_ROOT_CERT] : undefined
      };
    
    case 'verify-full':
      return {
        rejectUnauthorized: true,
        ca: process.env.DB_SSL_ROOT_CERT ? [process.env.DB_SSL_ROOT_CERT] : undefined,
        cert: process.env.DB_SSL_CERT,
        key: process.env.DB_SSL_KEY
      };
    
    default:
      console.log(`⚠️ Unknown SSL mode '${sslMode}', defaulting to 'disable'`);
      return false;
  }
}

async function testConnection(sslMode) {
  const sslConfig = getSSLConfig(sslMode);
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: sslConfig
  });

  try {
    console.log(`🔌 Testing connection with SSL mode: ${sslMode}`);
    await client.connect();
    console.log(`✅ Connection successful with SSL mode: ${sslMode}`);
    
    // Test a simple query
    const result = await client.query('SELECT 1 as test');
    console.log(`✅ Query successful: ${JSON.stringify(result.rows[0])}`);
    
    await client.end();
    return true;
  } catch (error) {
    console.log(`❌ Connection failed with SSL mode ${sslMode}: ${error.message}`);
    await client.end().catch(() => {});
    return false;
  }
}

async function main() {
  console.log('🧪 SSL Configuration Test for Doktolib Seed Data');
  console.log('================================================');
  
  if (!process.env.DATABASE_URL) {
    console.error('❌ DATABASE_URL environment variable is required');
    process.exit(1);
  }
  
  console.log(`🔧 Database URL: ${process.env.DATABASE_URL.replace(/\/\/[^:]+:[^@]+@/, '//***:***@')}`);
  console.log('');
  
  const sslModes = ['disable', 'require', 'verify-ca', 'verify-full'];
  const results = {};
  
  for (const mode of sslModes) {
    try {
      results[mode] = await testConnection(mode);
    } catch (error) {
      results[mode] = false;
      console.log(`❌ Unexpected error testing ${mode}: ${error.message}`);
    }
    console.log('');
  }
  
  console.log('📊 Test Results Summary:');
  console.log('========================');
  for (const [mode, success] of Object.entries(results)) {
    const status = success ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} ${mode.padEnd(12)} - ${success ? 'Connection successful' : 'Connection failed'}`);
  }
  
  const successfulModes = Object.entries(results).filter(([_, success]) => success).map(([mode, _]) => mode);
  
  if (successfulModes.length > 0) {
    console.log('');
    console.log(`🎉 Recommended SSL modes for your database: ${successfulModes.join(', ')}`);
    console.log(`💡 Use: export DB_SSL_MODE="${successfulModes[0]}" for seeding`);
  } else {
    console.log('');
    console.log('⚠️ No SSL modes worked. Check your database configuration.');
  }
}

if (require.main === module) {
  main().catch(console.error);
}