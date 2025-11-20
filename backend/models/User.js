const mongoose = require('mongoose');

const SettingsSchema = new mongoose.Schema({
  darkMode: { type: Boolean, default: false },
  largeFont: { type: Boolean, default: false },
});

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },

  // OTP fields for password reset (6-digit numeric)
  resetOTP: { type: String, default: undefined },
  resetOTPExpires: { type: Date, default: undefined },

  // legacy possible fields kept optional (if you used tokens earlier)
  resetPasswordToken: { type: String, default: undefined },
  resetPasswordExpires: { type: Date, default: undefined },

  settings: { type: SettingsSchema, default: () => ({}) },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);
