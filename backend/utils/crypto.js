const crypto = require('crypto');

const ENCODING = 'base64';

const getKey = (envKey) => {
  // Accept base64 or hex raw 32 byte key in env
  if (!envKey) throw new Error('ENCRYPTION_KEY not set');
  // If base64-looking string: decode and ensure length
  try {
    const buf = Buffer.from(envKey, 'base64');
    if (buf.length === 32) return buf;
  } catch (e) {}
  // fallback to hex
  const bufHex = Buffer.from(envKey, 'hex');
  if (bufHex.length === 32) return bufHex;
  throw new Error('ENCRYPTION_KEY must be 32 bytes (base64 or hex)');
};

const init = (envKey) => {
  const key = getKey(envKey);

  const encrypt = (plaintext) => {
    const iv = crypto.randomBytes(12); // recommended 12 bytes for GCM
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    const payload = Buffer.concat([iv, tag, encrypted]).toString(ENCODING);
    return payload;
  };

  const decrypt = (payload) => {
    const data = Buffer.from(payload, ENCODING);
    const iv = data.slice(0, 12);
    const tag = data.slice(12, 28);
    const encrypted = data.slice(28);
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);
    const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
    return decrypted.toString('utf8');
  };

  return { encrypt, decrypt };
};

module.exports = { init };
