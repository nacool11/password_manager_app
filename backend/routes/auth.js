const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const validator = require('validator');

const User = require('../models/User');
const { createTransporter, sendResetEmail } = require('../utils/mail');

const transporter = createTransporter(process.env);

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

// Forgot password -> generates reset token and emails link (if transporter configured)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email || !validator.isEmail(email)) return res.status(400).json({ message: 'Valid email required' });
  try {
    const user = await User.findOne({ email });
    if (!user) {
      // don't reveal existence
      return res.json({ message: 'If the email exists, a reset link was sent' });
    }

    const token = crypto.randomBytes(20).toString('hex');
    const expires = Date.now() + (Number(process.env.RESET_TOKEN_EXPIRES_MIN || 30) * 60 * 1000);

    user.resetPasswordToken = token;
    user.resetPasswordExpires = new Date(expires);
    await user.save();

    const resetUrl = `${req.get('origin') || req.get('host')}/reset-password?token=${token}&email=${encodeURIComponent(user.email)}`;

    // send email if transporter configured
    await sendResetEmail(transporter, process.env.FROM_EMAIL || 'no-reply@example.com', user.email, resetUrl);

    res.json({ message: 'If the email exists, a reset link was sent' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Reset password
router.post('/reset-password', async (req, res) => {
  const { email, token, newPassword } = req.body;
  if (!email || !token || !newPassword) return res.status(400).json({ message: 'Missing fields' });

  try {
    const user = await User.findOne({
      email,
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: new Date() },
    });
    if (!user) return res.status(400).json({ message: 'Invalid or expired token' });

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
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
