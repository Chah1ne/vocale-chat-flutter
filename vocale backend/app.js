const express = require('express');
const bodyParser = require('body-parser');
const mysql = require('mysql');

const app = express();
const port = 3000;

// Configuration de la connexion à la base de données
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'freelance'
});

// Middleware pour traiter les requêtes JSON
app.use(bodyParser.json());

// Middleware pour autoriser les requêtes CORS
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*'); // Autorise les requêtes de n'importe quelle origine
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS'); // Autorise les méthodes HTTP spécifiées
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization'); // Autorise les en-têtes spécifiés

  // Passe au prochain middleware
  next();
});

// Route pour enregistrer le texte dans la base de données
app.post('/enregistrer-texte', (req, res) => {
  const texte = req.body.texte;

  // Insertion du texte dans la base de données, idUser est auto-incrémenté
  const query = 'INSERT INTO user (text) VALUES (?)';
  connection.query(query, [texte], (error, results, fields) => {
    if (error) {
      console.error('Erreur lors de l\'enregistrement du texte :', error);
      res.sendStatus(500);
      return;
    }
    console.log('Texte enregistré avec succès dans la base de données');
    res.sendStatus(200);
  });
});




// Démarrage du serveur
app.listen(port, () => {
  console.log(`Serveur démarré sur le port ${port}`);
});
