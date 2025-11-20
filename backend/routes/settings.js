const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');

// Get settings
router.get('/', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('settings');
    res.json({ settings: user.settings });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update settings
router.put('/', auth, async (req, res) => {
  const updates = req.body || {};
  try {
    const user = await User.findById(req.user._id);
    user.settings = Object.assign({}, user.settings.toObject ? user.settings.toObject() : {}, updates);
    await user.save();
    res.json({ settings: user.settings });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
