const mongoose = require('mongoose');

const connectDB = async (mongoUri) => {
  try {
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000, // Fail fast if server selection takes too long
      socketTimeoutMS: 45000, // 45 second socket timeout for operations
      connectTimeoutMS: 10000, // 10 second connection timeout
    });
    console.log('MongoDB connected');
  } catch (err) {
    console.error('Mongo connection error:', err);
    process.exit(1);
  }
};

module.exports = connectDB;
