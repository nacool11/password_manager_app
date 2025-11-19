const nodemailer = require('nodemailer');

const createTransporter = (config) => {
  if (!config.SMTP_HOST) return null;
  const transporter = nodemailer.createTransport({
    host: config.SMTP_HOST,
    port: Number(config.SMTP_PORT) || 587,
    secure: Number(config.SMTP_PORT) === 465, // true for 465
    auth: {
      user: config.SMTP_USER,
      pass: config.SMTP_PASS,
    },
  });
  return transporter;
};

const sendResetEmail = async (transporter, from, to, resetUrl) => {
  if (!transporter) return;
  await transporter.sendMail({
    from,
    to,
    subject: 'Vault - Password reset',
    html: `<p>You requested a password reset. Use the link below to reset your password (valid for limited time):</p>
           <p><a href="${resetUrl}">${resetUrl}</a></p>`,
  });
};

module.exports = { createTransporter, sendResetEmail };
