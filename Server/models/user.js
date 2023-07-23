const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const config = require('../config/database');

// User Schema
const UserSchema = mongoose.Schema({
  email: {
    type: String, set: toLower,
    required: true,
    validate: {
      validator: function(v, cb){
        User.find({email: v}, function(err, docs){
          cb(docs.length == 0);
          if(docs.length){
            errMsg = 'Email taken'
          }
        });
      }
    }
  },
  username: {
    type: String,
    required: true,
    validate: {
      validator: function(v, cb){
        User.find({username: new RegExp(v, "i")}, function(err, docs){
          cb(docs.length == 0);
          if(docs.length){
            errMsg = 'Username taken'
          }
        });
      }
    }
  },
  password: {
    type: String,
    required: true
  }
});

function toLower (str) {
  return str.toLowerCase();
}

const User = module.exports = mongoose.model('User', UserSchema);

module.exports.getUserById = function(id, callback){
  User.findById(id, callback);
}

module.exports.getUserByUsername = function(username, callback){
  const query = {username: username}
  User.findOne(query, callback);
}

module.exports.addUser = function(newUser, callback){
  bcrypt.genSalt(10, (err, salt) => {
    bcrypt.hash(newUser.password, salt, (err, hash) => {
      if(err) throw err;
      newUser.password = hash;
      newUser.save(callback);
    });
  });
}

module.exports.comparePassword = function(candidatePassword, hash, callback){
  bcrypt.compare(candidatePassword, hash, (err, isMatch) => {
    if(err) throw err;
    callback(null, isMatch);
  });
}
