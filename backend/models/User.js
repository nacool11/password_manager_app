const mongoose = require('mongoose');

const SettingsSchema = new mongoose.Schema({
  darkMode: { type: Boolean, default: false },
  largeFont: { type: Boolean, default: false },
});

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },
  resetPasswordToken: { type: String },
  resetPasswordExpires: { type: Date },
  settings: { type: SettingsSchema, default: () => ({}) },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
