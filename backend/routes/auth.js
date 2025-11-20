const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const validator = require('validator');

const User = require('../models/User');
const { createTransporter, sendResetEmail, sendOTPEmail } = require('../utils/mail');

const transporter = createTransporter(process.env);

// Helper: generate 6-digit numeric OTP as string
function generateOtp() {
  // generate number 0..999999 and pad left with zeros
  const n = Math.floor(Math.random() * 1000000);
  return String(n).padStart(6, '0');
}

// Register
router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !validator.isEmail(email)) return res.status(400).json({ message: 'Valid email required' });
  if (!password || password.length < 6) return res.status(400).json({ message: 'Password min 6 chars' });

  try {
    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ message: 'Email already registered' });

    const salt = await bcrypt.genSalt(10);
    const hashed = await bcrypt.hash(password, salt);

    user = new User({ email, password: hashed });
    await user.save();

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
    res.json({ token, user: { id: user._id, email: user.email, settings: user.settings } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ message: 'Email and password required' });

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
    res.json({ token, user: { id: user._id, email: user.email, settings: user.settings } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

/*
  NEW FLOW - OTP based reset
  POST /auth/forgot-password  -> generate OTP & email it
  POST /auth/reset-password   -> accept email + otp + newPassword
*/

// Forgot password (generate OTP)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email || !validator.isEmail(email)) return res.status(400).json({ message: 'Valid email required' });

  try {
    const user = await User.findOne({ email });
    // Always respond success message to avoid email enumeration
    const genericMsg = { message: 'If the email exists, a reset code was sent' };

    if (!user) {
      // still respond success
      return res.json(genericMsg);
    }

    // Generate 6-digit OTP
    const otp = generateOtp();
    const expiresMs = Number(process.env.RESET_TOKEN_EXPIRES_MIN || 10) * 60 * 1000;
    const expiresAt = new Date(Date.now() + expiresMs);

    user.resetOTP = otp;
    user.resetOTPExpires = expiresAt;
    // clear legacy token fields (safe)
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;

    await user.save();

    // Send OTP via email (if transporter configured)
    try {
      await sendOTPEmail(transporter, process.env.FROM_EMAIL || process.env.SMTP_USER, user.email, otp, Number(process.env.RESET_TOKEN_EXPIRES_MIN || 10));
    } catch (mailErr) {
      console.error('Failed to send OTP email:', mailErr);
      // Do not reveal this error to client; still return generic message
    }

    return res.json(genericMsg);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Reset password using OTP
router.post('/reset-password', async (req, res) => {
  const { email, otp, newPassword } = req.body;
  if (!email || !validator.isEmail(email) || !otp || !newPassword) {
    return res.status(400).json({ message: 'Missing fields' });
  }

  try {
    const user = await User.findOne({
      email,
      resetOTP: otp,
      resetOTPExpires: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    // Update password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);

    // clear OTP and expirations
    user.resetOTP = undefined;
    user.resetOTPExpires = undefined;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;

    await user.save();

    res.json({ message: 'Password reset successful' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
