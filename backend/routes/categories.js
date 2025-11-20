const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Category = require('../models/Category');

// List categories
router.get('/', auth, async (req, res) => {
  try {
    const cats = await Category.find({ user: req.user._id }).sort({ name: 1 });
    res.json({ categories: cats });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create
router.post('/', auth, async (req, res) => {
  const { name, icon, color } = req.body;
  if (!name) return res.status(400).json({ message: 'name required' });
  try {
    const c = new Category({ user: req.user._id, name, icon: icon || null, color: color || null });
    await c.save();
    res.json({ category: c });
  } catch (err) {
    console.error(err);
    if (err.code === 11000) return res.status(400).json({ message: 'Category exists' });
    res.status(500).json({ message: 'Server error' });
  }
});

// Update
router.put('/:id', auth, async (req, res) => {
  const { name, icon, color } = req.body;
  try {
    const cat = await Category.findOne({ _id: req.params.id, user: req.user._id });
    if (!cat) return res.status(404).json({ message: 'Not found' });
    if (name) cat.name = name;
    if (icon !== undefined) cat.icon = icon;
    if (color !== undefined) cat.color = color;
    await cat.save();
    res.json({ category: cat });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete
router.delete('/:id', auth, async (req, res) => {
  try {
    const cat = await Category.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!cat) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
