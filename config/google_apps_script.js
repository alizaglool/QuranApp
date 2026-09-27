// ============================================================
// Google Apps Script — Sync Google Sheet → GitHub
// Paste this in: Extensions → Apps Script → Code.gs
// ============================================================

// ⚙️ CONFIGURATION — fill these in once
const CONFIG = {
  GITHUB_TOKEN: 'YOUR_GITHUB_PERSONAL_ACCESS_TOKEN',
  GITHUB_REPO:  'YOUR_GITHUB_USERNAME/wird-app-config',
  GITHUB_FILE:  'config/channels_config.json',
  GITHUB_BRANCH: 'main'
};

// ============================================================
// Runs when spreadsheet opens — adds "Sync" menu
// ============================================================
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🔄 Sync to GitHub')
    .addItem('Sync Now', 'syncToGitHub')
    .addToUi();
}

// ============================================================
// Main sync function — reads sheet → pushes JSON to GitHub
// ============================================================
function syncToGitHub() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  const data  = sheet.getDataRange().getValues();

  // Skip header row (row 1), read column A (channelId)
  const channelIds = data
    .slice(1)
    .map(row => row[0])
    .map(id  => id ? id.toString().trim() : '')
    .filter(id => id.length > 0);

  if (channelIds.length === 0) {
    SpreadsheetApp.getUi().alert('⚠️ No channel IDs found in column A.');
    return;
  }

  const json = JSON.stringify({
    version:       '1.0',
    updatedAt:     new Date().toISOString(),
    totalChannels: channelIds.length,
    channelIds:    channelIds
  }, null, 2);

  const apiUrl = `https://api.github.com/repos/${CONFIG.GITHUB_REPO}/contents/${CONFIG.GITHUB_FILE}`;
  const headers = {
    'Authorization': `token ${CONFIG.GITHUB_TOKEN}`,
    'Accept':        'application/vnd.github.v3+json',
    'Content-Type':  'application/json'
  };

  // Step 1: Get current file SHA (required for update)
  let sha = '';
  try {
    const getRes = UrlFetchApp.fetch(apiUrl, { headers, muteHttpExceptions: true });
    if (getRes.getResponseCode() === 200) {
      sha = JSON.parse(getRes.getContentText()).sha;
    }
  } catch (e) {
    // File doesn't exist yet — first push
  }

  // Step 2: Push updated JSON to GitHub
  const payload = {
    message: `Update channels_config.json — ${channelIds.length} channels`,
    content: Utilities.base64Encode(json, Utilities.Charset.UTF_8),
    branch:  CONFIG.GITHUB_BRANCH
  };
  if (sha) payload.sha = sha;

  const putRes = UrlFetchApp.fetch(apiUrl, {
    method:           'put',
    headers:          headers,
    payload:          JSON.stringify(payload),
    muteHttpExceptions: true
  });

  const code = putRes.getResponseCode();
  if (code === 200 || code === 201) {
    SpreadsheetApp.getUi().alert(
      `✅ GitHub updated!\n\n${channelIds.length} channels synced.\n\nRaw URL:\nhttps://raw.githubusercontent.com/${CONFIG.GITHUB_REPO}/${CONFIG.GITHUB_BRANCH}/${CONFIG.GITHUB_FILE}`
    );
  } else {
    SpreadsheetApp.getUi().alert(`❌ GitHub error ${code}:\n${putRes.getContentText()}`);
  }
}

// ============================================================
// Optional: Auto-sync on every edit (uncomment to enable)
// Warning: may be slow if sheet is large
// ============================================================
// function onEdit(e) {
//   syncToGitHub();
// }
