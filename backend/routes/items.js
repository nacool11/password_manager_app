const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Item = require('../models/Item');
const { init } = require('../utils/crypto');

const crypto = init(process.env.ENCRYPTION_KEY);

// Create item
router.post('/', auth, async (req, res) => {
  const { title, subtitle, type, data, category } = req.body;
  if (!title || !data) return res.status(400).json({ message: 'title and data required' });

  try {
    // data should be plain JSON object from client; server encrypts it
    const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
    const encrypted = crypto.encrypt(dataStr);

    const item = new Item({
      user: req.user._id,
      title,
      subtitle,
      type: type || 'password',
      encryptedData: encrypted,
      category: category || null,
    });
    await item.save();
    res.json({ item });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// List items
router.get('/', auth, async (req, res) => {
  try {
    const items = await Item.find({ user: req.user._id }).sort({ createdAt: -1 }).lean();
    // Decrypt before sending
    const decrypted = items.map(it => {
      let data = null;
      try {
        data = JSON.parse(crypto.decrypt(it.encryptedData));
      } catch (e) {
        data = null;
      }
      return { ...it, data };
    });
    res.json({ items: decrypted });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get single
router.get('/:id', auth, async (req, res) => {
  try {
    const item = await Item.findOne({ _id: req.params.id, user: req.user._id }).lean();
    if (!item) return res.status(404).json({ message: 'Not found' });
    let data = null;
    try {
      data = JSON.parse(crypto.decrypt(item.encryptedData));
    } catch (e) {
      data = null;
    }
    res.json({ ...item, data });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update
router.put('/:id', auth, async (req, res) => {
  const { title, subtitle, type, data, category } = req.body;
  try {
    const item = await Item.findOne({ _id: req.params.id, user: req.user._id });
    if (!item) return res.status(404).json({ message: 'Not found' });

    if (title) item.title = title;
    if (subtitle) item.subtitle = subtitle;
    if (type) item.type = type;
    if (category !== undefined) item.category = category;
    if (data !== undefined) {
      const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
      item.encryptedData = crypto.encrypt(dataStr);
    }
    await item.save();
    res.json({ item });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete
router.delete('/:id', auth, async (req, res) => {
  try {
    const item = await Item.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!item) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
