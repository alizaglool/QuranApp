// Google Apps Script - sync channel IDs from Sheet to hadith-books repo
// Setup:
//   1. Open your Google Sheet > Extensions > Apps Script > paste this file
//   2. Project Settings > Script Properties > add:
//        GITHUB_TOKEN = ghp_your_personal_access_token
//   3. Run syncToGitHub() once to authorize, then add an On Change trigger.

var REPO_OWNER = "alizaglool";
var REPO_NAME  = "hadith-books";
var FILE_PATH  = "config/channels_config.json";
var BRANCH     = "main";
var RAW_API    = "https://api.github.com/repos/" + REPO_OWNER + "/" + REPO_NAME + "/contents/" + FILE_PATH;

function syncToGitHub() {
  var token = PropertiesService.getScriptProperties().getProperty("GITHUB_TOKEN");
  if (!token) throw new Error("GITHUB_TOKEN not set in Script Properties");

  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var rows  = sheet.getRange("A2:A" + sheet.getLastRow()).getValues();
  var ids   = rows.map(function(r) { return String(r[0]).trim(); }).filter(function(id) { return id.length > 0; });

  var payload = JSON.stringify({ channelIds: ids }, null, 2);

  var getResp = UrlFetchApp.fetch(RAW_API, {
    headers: { Authorization: "token " + token, Accept: "application/vnd.github+json" },
    muteHttpExceptions: true
  });

  var sha = getResp.getResponseCode() === 200
    ? JSON.parse(getResp.getContentText()).sha
    : null;

  var body = {
    message: "Update channels_config.json (" + ids.length + " channels)",
    content: Utilities.base64Encode(payload),
    branch:  BRANCH
  };
  if (sha) body.sha = sha;

  var putResp = UrlFetchApp.fetch(RAW_API, {
    method:  "PUT",
    headers: { Authorization: "token " + token, Accept: "application/vnd.github+json" },
    contentType: "application/json",
    payload: JSON.stringify(body),
    muteHttpExceptions: true
  });

  var code = putResp.getResponseCode();
  if (code !== 200 && code !== 201) {
    throw new Error("GitHub API error " + code + ": " + putResp.getContentText());
  }

  Logger.log("Synced " + ids.length + " channel IDs to GitHub");
}
