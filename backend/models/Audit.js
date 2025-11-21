const mongoose = require('mongoose');

const AuditSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  scorePercent: Number,
  riskLevel: String,
  summary: Object,
  issues: Array,
  itemReports: Array,
  generatedAt: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Audit', AuditSchema);