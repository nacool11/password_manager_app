require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const connectDB = require('./config/db');

const authRoutes = require('./routes/auth');
const itemRoutes = require('./routes/items');
const categoryRoutes = require('./routes/categories');
const settingsRoutes = require('./routes/settings');
const auditRoutes = require('./routes/audit');
const app = express();

app.use(cors());
app.use(bodyParser.json({ limit: '1mb' }));

// Set request timeout - increased to 50 seconds to accommodate slow connections
app.use((req, res, next) => {
  req.setTimeout(50000); // 50 second timeout
  next();
});

const PORT = process.env.PORT || 4000;

// connect db
connectDB(process.env.MONGO_URI || 'mongodb://localhost:27017/vault_db');

// Api
app.get('/', (req, res) => res.send('Vault backend running'));
app.use('/api/audit', auditRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/settings', settingsRoutes);
// error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error', err);
  res.status(500).json({ message: 'Server error' });
});

app.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
});
