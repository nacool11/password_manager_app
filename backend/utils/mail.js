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
    subject: 'Vault - Password reset link',
    html: `<p>You requested a password reset. Click the link below to reset your password (expires shortly):</p>
           <p><a href="${resetUrl}">${resetUrl}</a></p>`,
  });
};

// New: send OTP email (6-digit code)
const sendOTPEmail = async (transporter, from, to, otp, minutesValid = 10) => {
  if (!transporter) return;
  const html = `
    <div style="font-family: Arial, sans-serif; line-height:1.4;">
      <h3>Vault — Password reset OTP</h3>
      <p>Your password reset code is:</p>
      <p style="font-size: 28px; letter-spacing: 4px; font-weight:700;">${otp}</p>
      <p>This code will expire in ${minutesValid} minutes.</p>
      <p>If you did not request this code, you can safely ignore this email.</p>
    </div>
  `;
  await transporter.sendMail({
    from,
    to,
    subject: 'Your Vault password reset code',
    html,
  });
};

module.exports = { createTransporter, sendResetEmail, sendOTPEmail };
