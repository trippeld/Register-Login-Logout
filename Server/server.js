const express = require('express');
const path = require('path');
const bodyParser = require('body-parser');
const cors = require('cors');
const passport = require('passport');
const mongoose = require('mongoose');
const config = require('./config/database');

// Connect To Database
mongoose.connect(config.database, { useMongoClient: true });

// On Connection
mongoose.connection.on('connected', () => {
  console.log('Connected to database '+config.database);
});

// On Error
mongoose.connection.on('error', (err) => {
  console.log('Database error: '+err);
});

const server = express();

const users = require('./routes/users');

// Port Number
const port = 3000;

// CORS Middleware
server.use(cors());

// Set Static Folder
server.use(express.static(path.join(__dirname, 'public')));

// Body Parser Middleware
server.use(bodyParser.json());

// Passport Middleware
server.use(passport.initialize());
server.use(passport.session());

require('./config/passport')(passport);

server.use('/users', users);

// Index Route
server.get('/', (req, res) => {
  res.send('Invalid Endpoint');
});

// Start Server
server.listen(port, () => {
  console.log('Server started on port '+port);
});
