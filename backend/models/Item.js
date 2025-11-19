const mongoose = require('mongoose');

const ItemSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  subtitle: { type: String },
  type: { type: String, enum: ['password', 'card', 'note', 'login'], default: 'password' },
  // encryptedData stores JSON string encrypted (e.g. {username, password, notes, cardNumber,...})
  encryptedData: { type: String, required: true },
  category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null },
}, { timestamps: true });

module.exports = mongoose.model('Item', ItemSchema);
