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

const sendOTPEmail = async (transporter, from, to, otpCode) => {
  if (!transporter) return;
  await transporter.sendMail({
    from,
    to,
    subject: 'Vault - Verification Code',
    html: `<p>Your verification code is: <strong>${otpCode}</strong></p>
           <p>This code will expire in 10 minutes.</p>
           <p>If you didn't request this code, please ignore this email.</p>`,
  });
};

module.exports = { createTransporter, sendResetEmail, sendOTPEmail };
