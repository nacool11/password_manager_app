// backend/utils/auditUtils.js
const commonPasswords = [
  '123456','password','12345678','qwerty','123456789','12345','1234','111111',
  '1234567','dragon','123123','baseball','abc123','football','monkey','letmein',
  '696969','shadow','master','666666','qwertyuiop','123321','mustang','1234567890'
];

// estimate entropy (very simple heuristic)
function estimateEntropy(str) {
  if (!str) return 0;
  const unique = new Set(str).size;
  // rough: entropy ≈ log2(unique choices^length) = length * log2(unique)
  const log2 = (x) => Math.log(x) / Math.log(2);
  const val = str.length * Math.max(1, log2(unique));
  return Math.round(val);
}

function isCommonPassword(pw) {
  if (!pw) return false;
  const low = pw.toLowerCase().trim();
  return commonPasswords.includes(low);
}

function analyzeItem(item, decryptedData, now = new Date()) {
  // returns an object: { itemId, title, type, checks: [{name, ok, reason}], itemScore }
  const checks = [];
  // default total checks to 0 and increment as checks are relevant to type
  let totalChecks = 0;
  let passedChecks = 0;

  const addCheck = (name, ok, reason) => {
    totalChecks++;
    if (ok) passedChecks++;
    checks.push({ name, ok, reason });
  };

  // Common checks for login/password items
  if (item.type === 'password' || item.type === 'login' || !item.type) {
    const pw = decryptedData?.password || decryptedData?.pass || decryptedData?.value || null;
    // Check: password exists
    if (!pw) {
      addCheck('hasPassword', false, 'No password field found in item data');
    } else {
      addCheck('hasPassword', true, 'Password present');
      // length
      const lenOk = pw.length >= 12; // prefer 12+
      addCheck('length>=12', lenOk, lenOk ? 'Good length' : 'Password shorter than 12 chars');
      // entropy
      const ent = estimateEntropy(pw);
      const entOk = ent >= 50; // heuristic
      addCheck('entropy', entOk, `Estimated entropy ${ent} bits`);
      // common password
      const common = isCommonPassword(pw) || pw.length <= 6;
      addCheck('notCommon', !common, common ? 'Password is common or very short' : 'Not common');
    }
    // age (use item.updatedAt or createdAt)
    const updated = item.updatedAt ? new Date(item.updatedAt) : new Date(item.createdAt);
    if (updated) {
      const ageDays = Math.floor((now - updated) / (1000 * 60 * 60 * 24));
      const freshOk = ageDays <= 365; // updated within 1 year
      addCheck('recentlyUpdated', freshOk, freshOk ? `Updated ${ageDays} days ago` : `Not updated in ${ageDays} days`);
    }
  }

  // For card type items, check expiry
  if (item.type === 'card') {
    const exp = decryptedData?.expiry || decryptedData?.exp || decryptedData?.cardExpiry || null;
    totalChecks += 1; // card expiry check
    if (!exp) {
      addCheck('cardExpiry', false, 'No expiry date found');
    } else {
      // parse expiry formats: MM/YY, MM/YYYY, ISO
      const parseExpiry = (str) => {
        try {
          str = String(str).trim();
          if (/^\d{2}\/\d{2}$/.test(str)) {
            const [mm, yy] = str.split('/').map(Number);
            const year = 2000 + yy;
            return new Date(year, mm - 1, 1);
          }
          if (/^\d{2}\/\d{4}$/.test(str)) {
            const [mm, yyyy] = str.split('/').map(Number);
            return new Date(yyyy, mm - 1, 1);
          }
          const d = new Date(str);
          if (!isNaN(d)) return d;
          return null;
        } catch (e) {
          return null;
        }
      };
      const dt = parseExpiry(exp);
      if (!dt) {
        addCheck('cardExpiry', false, `Could not parse expiry: ${exp}`);
      } else {
        // consider valid until end of month
        const endOfMonth = new Date(dt.getFullYear(), dt.getMonth() + 1, 0);
        const ok = endOfMonth >= now;
        addCheck('cardExpiry', ok, ok ? `Expires ${endOfMonth.toISOString().slice(0,10)}` : `Expired on ${endOfMonth.toISOString().slice(0,10)}`);
      }
    }
  }

  // If type is 'note' or other, perform minimal checks
  if (item.type === 'note' || item.type === 'secure_note') {
    // ensure there is some content
    const content = decryptedData?.note || decryptedData?.content || '';
    addCheck('hasContent', Boolean(content && String(content).trim().length > 0), content ? 'Has content' : 'Empty note');
  }

  // Avoid division by zero: if totalChecks is zero, set passed=total
  if (totalChecks === 0) {
    totalChecks = 1;
    // assume ok
    passedChecks = 1;
    checks.push({ name: 'noChecks', ok: true, reason: 'No applicable automated checks for this item type' });
  }

  const itemScore = Math.round((passedChecks / totalChecks) * 100);
  return {
    itemId: item._id,
    title: item.title || decryptedData?.username || 'Untitled',
    type: item.type,
    totalChecks,
    passedChecks,
    itemScore,
    checks
  };
}

/**
 * computeUserAudit(items, options)
 * items: array of item documents (decrypted)
 * returns: { scorePercent, riskLevel, summary, issues, itemReports }
 */
function computeUserAudit(itemReports) {
  // itemReports is array produced by analyzeItem
  const totalItems = itemReports.length || 0;
  if (totalItems === 0) {
    return {
      scorePercent: 100,
      riskLevel: 'low',
      summary: { totalItems: 0, flaggedItems: 0 },
      issues: [],
      itemReports: []
    };
  }

  // average item score
  const sum = itemReports.reduce((s, r) => s + (r.itemScore || 0), 0);
  const avg = Math.round(sum / itemReports.length);

  // flagged items = items with itemScore < 70
  const flagged = itemReports.filter(r => (r.itemScore || 0) < 70);

  // risk level thresholds
  let riskLevel = 'low';
  if (avg < 40) riskLevel = 'high';
  else if (avg < 70) riskLevel = 'medium';

  // collect issues: flatten checks where ok === false
  const issues = [];
  itemReports.forEach(r => {
    r.checks.forEach(c => {
      if (!c.ok) {
        issues.push({
          itemId: r.itemId,
          title: r.title,
          type: r.type,
          check: c.name,
          reason: c.reason,
        });
      }
    });
  });

  return {
    scorePercent: avg,
    riskLevel,
    summary: { totalItems, flaggedItems: flagged.length },
    issues,
    itemReports
  };
}

module.exports = { analyzeItem, computeUserAudit, estimateEntropy, isCommonPassword };
