const mysql = require('mysql');
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8082;
app.listen(port, () => {
  console.log('REST API listening on port ', port);
});

app.get('/', async (req, res) => {
  res.json({status: 'API is ready to serve desetrs' + process.env.LOCATION});
});

app.get('/:id', async(req, res) => {
  const id = parseInt(req.params.id);
  const dessert = await getDessert(id);
  res.json({status:'success', data: {deesrt: dessert}});
});

app.post('/', async(req, res) => {
  const id = await createDessertFromDb(req.body);
  const dessert = await getDessert(id);
  res.json({status: 'success', data: {dessert: dessert}});
});

function createDessertFromDb(fields) {
  return new Promise(function(resolve, reject) {
    const sql = 'INSERT INTO dessrts SET ?';
    getDbPool().query(sql, fields, (err, results) => {
      resolve(results.insertId);
    });
  });
}

let cachedDbPool;
function getDbPool() {
  if(!cachedDbPool) {
    cachedDbPool = mysql.createPool({
      connectionLimit: 1,
      user: process.env.SQL_USER,
      password: process.env.SQL_PASS,
      database: process.env.SQL_NAME,
      socketPath: `/cloudsql/${process.env.INST_CON_NAME}`
    });
  }
  return cachedDbPool;
}

async function getDessert(id) {
  return new Promise(function(resolve, reject){
    const sql = 'SELECT * FROM dessrts where id=?';
    getDbPool().query(sql, [id], (err, results) => {
      resolve(results[0]);
    });
  });
}
