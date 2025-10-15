const sqlite3 = require('sqlite3').verbose();
const config = require('../config');

const db = new sqlite3.Database(config.dbPath);

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err); else resolve(this);
    });
  });
}

async function migrate() {
  console.log('Starting migration: add homeLineScore, awayLineScore, leadChanges to games');
  await run('BEGIN TRANSACTION');
  try {
    await run("ALTER TABLE games ADD COLUMN homeLineScore TEXT");
    await run("ALTER TABLE games ADD COLUMN awayLineScore TEXT");
    await run("ALTER TABLE games ADD COLUMN leadChanges INTEGER");
    await run('COMMIT');
    console.log('Migration completed successfully.');
  } catch (err) {
    console.error('Migration failed, rolling back:', err);
    await run('ROLLBACK');
    process.exitCode = 1;
  } finally {
    db.close();
  }
}

if (require.main === module) {
  migrate();
}

module.exports = { migrate };


