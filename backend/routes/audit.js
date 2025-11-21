const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Item = require('../models/Item');
const { init } = require('../utils/crypto');
const { analyzeItem, computeUserAudit } = require('../utils/auditutils');

const crypto = init(process.env.ENCRYPTION_KEY);

// Protected route: run on-demand audit for the authenticated user
router.get('/', auth, async (req, res) => {
  try {
    // fetch all items for user
    const items = await Item.find({ user: req.user._id }).lean();

    // decrypt each item's encryptedData
    const itemReports = [];
    for (const it of items) {
      let dataObj = null;
      try {
        const dec = crypto.decrypt(it.encryptedData);
        dataObj = (() => {
          try { return JSON.parse(dec); } catch (e) { return { raw: dec }; }
        })();
      } catch (e) {
        // If decrypt fails, note that
        dataObj = { _decryptError: true };
      }
      const report = analyzeItem(it, dataObj, new Date());
      itemReports.push(report);
    }

    const auditResult = computeUserAudit(itemReports);

    // Optionally: attach timestamp
    auditResult.generatedAt = new Date();

    return res.json({ audit: auditResult });
  } catch (err) {
    console.error('Audit error:', err);
    return res.status(500).json({ message: 'Could not run audit' });
  }
});

module.exports = router;