--[[
Title: MailR
Description: MailR is a supplemental addon for the ESO in-game mail system.
Version: 2.5.12
Original Author: pills
Previous Authors: calia1120, Ravalox Darkshire
]]

-- GLOBALS
MailR = {}
-------------------------------------------------
----- early helper                          -----
-------------------------------------------------

local function is_in(search_value, search_table)
  for k, v in pairs(search_table) do
    if search_value == v then return true end
    if type(search_value) == "string" then
      if string.find(string.lower(v), string.lower(search_value)) then return true end
    end
  end
  return false
end

-------------------------------------------------
----- lang setup                            -----
-------------------------------------------------

MailR.client_lang = GetCVar("Language.2")
MailR.effective_lang = nil
MailR.supported_lang = { "de", "en", "fr", "es", }
if is_in(MailR.client_lang, MailR.supported_lang) then
  MailR.effective_lang = MailR.client_lang
else
  MailR.effective_lang = "en"
end
MailR.supported_lang = MailR.client_lang == MailR.effective_lang

-------------------------------------------------
----- mod                                   -----
-------------------------------------------------

MailR.Name = "MailR"
-- Set to true if you want to see debug output to console/chat window
MailR.DEBUG = false
-- default mail color
--MailR.DEFAULT_EXPIRE_MAIL_COLOR_STRING = "|c2dc50e"
MailR.DEFAULT_SAVE_MAIL_COLOR_STRING = "|c2dc50e"
MailR.DEFAULT_SENT_MAIL_COLOR_STRING = "|c3689ef"
MailR.DEFAULT_HEADER_COLOR_STRING = "|cd5b526"
MailR.RESET_COLOR_STRING = "|r"
-- flag to say we havent overridden existing control handlers yet.
-- gets set to false after overriding handlers
MailR.setHandlersOnFirstLoad = true
-- are we in the mailbox UI
MailR.mailboxActive = false
MailR.guildies_visible = false
MailR.guilds = {}
MailR.guildranks = {}
MailR.guildies = {}
MailR.LastKnownRecipient = {}
MailR.CurrentKnownGuild = {}
MailR.LastKnownGuild = {}
MailR.failed_guildies = {}
MailRGuild = ZO_SortFilterList:Subclass()
MailRGuild.defaults = {}
MailR.GuildDropdown = nil
MailR.GuildRankDropdown = nil
MailR.GuildStatusDropdown = nil
MailR.GuildLogicDropdown = nil
MailR.GuildRecipients = {}
MailR.GuildSendProgress = nil
MailR.GuildThrottleTimer = nil
MailR.ThrottleRecipients = 1
MailR.ThrottledRecipients = 0
MailR.RecipientCount = 0
MailR.GuildRecipientCount = 0
MailR.GuildMailRecipientsReady = false
MailR.CancelGuildMail = true
-- max mail attachments
MailR.MAX_ATTACHMENTS = 6
-- table to store the keybind info
MailR.keybindInfo = {}
-- table for current mail inbox intem
MailR.currentMessageInfo = {}
-- table for queued message to be sent
MailR.queuedSentMessage = {}
-- table for current message being composed
MailR.currentSendMessageInfo = {}
-- Saved Mail vars --
-- what version of the saved mail table are we using
MailR.SAVED_MAIL_VERSION = "2.0"
-- default table for above version incase this the first time MailR is used
MailR.SavedMail_defaults = {
  display = "all",
  guildMailVisible = false,
  mailr_version = MailR.SAVED_MAIL_VERSION,
  sent_count = 0,
  sent_messages = {},
  inbox_count = 0,
  inbox_messages = {},
  throttle_time = 1 --seconds (can be fractional)
}
-- saved mail
MailR.SavedMail = nil
-- Locale vars --
MailR.localeStringMap = {
  ["en"] = {
    ["Reply"] = "Reply",
    ["Forward"] = "Forward",
    ["Reply To Message"] = "Reply To Message",
    ["Forward Message"] = "Forward Message",
    ["Original Message"] = "Original Message",
    ["Save Mail"] = "Save Mail",
    ["From: "] = "From: ",
    ["Fwd: "] = "Fwd: ",
    ["Re: "] = "Re: ",
    ["Attachments: "] = "Attachments: ",
    ["To:"] = "To:",
    ["Received:"] = "Received:",
    ["Sent:"] = "Sent:",
    ["Attached Gold: "] = "Attached Gold: ",
    ["COD: "] = "COD: ",
    ["Postage: "] = "Postage: "
  },
  ["de"] = {
    ["Reply"] = "Antworten",
    ["Forward"] = "Vorwärts",
    ["Reply To Message"] = "Antwort auf Beitrag",
    ["Forward Message"] = "Nachricht weiterleiten",
    ["Original Message"] = "Ursprüngliche Nachricht",
    ["Save Mail"] = "Save Mail",
    ["From: "] = "Von: ",
    ["Fwd: "] = "WG: ",
    ["Re: "] = "AW: ",
    ["Attachments: "] = "Anhänge: ",
    ["To:"] = "An:",
    ["Received:"] = "Erhalten am:",
    ["Sent:"] = "Gesendet:",
    ["Attached Gold: "] = "Angehängte Gold: ",
    ["COD: "] = "COD: ",
    ["Postage: "] = "Porto: "
  },
  ["fr"] = {
    ["Reply"] = "Répondre",
    ["Forward"] = "Transférer",
    ["Reply To Message"] = "Répondre au Message",
    ["Forward Message"] = "Transférer le Message",
    ["Original Message: "] = "Message Original: ",
    ["Save Mail"] = "Save Mail",
    ["From: "] = "Von: ",
    ["Fwd: "] = "Tr: ",
    ["Re: "] = "Re: ",
    ["Attachments: "] = "Pièces jointes: ",
    ["To:"] = "A:",
    ["Received:"] = "Reçus:",
    ["Sent:"] = "Envoyé:",
    ["Attached Gold: "] = "Or Attaché: ",
    ["COD: "] = "COD: ",
    ["Postage: "] = "Affranchissement: "
  },
  ["es"] = {
    ["Reply"] = "Responder",
    ["Forward"] = "Reenviar",
    ["Reply To Message"] = "Responder mensaje",
    ["Forward Message"] = "Reenviar mensaje",
    ["Original Message"] = "Mensaje original",
    ["Save Mail"] = "Guardar correo",
    ["From: "] = "De: ",
    ["Fwd: "] = "RV: ",
    ["Re: "] = "RE: ",
    ["Attachments: "] = "Adjuntos: ",
    ["To:"] = "Para:",
    ["Received:"] = "Recibido:",
    ["Sent:"] = "Enviar:",
    ["Attached Gold: "] = "Oro adjunto: ",
    ["COD: "] = "Contra reembolso: ",
    ["Postage: "] = "Gastos de envío: ",
  },
}
local colorYellow = "|cFFFF00"  -- yellow
local colorSoftYellow = "|cCCCC00"    -- Duller Yellow for Description
local colorRed = "|cFF0000"  -- Red
local colorRavalox = "|cB60000"    -- Ravalox Red  -- B6 = Red 182  a brighter 82 red
local colorCMDBlue = "|c1155bb"    -- Dull blue used to indicate "typable" text
local ShowPlayerContextMenu_Orig = CHAT_SYSTEM.ShowPlayerContextMenu
local GetNextMailId_Orig = GetNextMailId
local ShowPlayerInteractMenu_Orig = ZO_PlayerToPlayer.ShowPlayerInteractMenu

MailR.show_log = false
if LibDebugLogger then
  logger = LibDebugLogger.Create(MailR.Name)
  MailR.logger = logger
end
local SDLV = DebugLogViewer
if SDLV then MailR.viewer = true else MailR.viewer = false end

local function create_log(log_type, log_content)
  if log_type == "Debug" then
    MailR.logger:Debug(log_content)
  end
  if log_type == "Info" then
    MailR.logger:Info(log_content)
  end
  if log_type == "Verbose" then
    MailR.logger:Verbose(log_content)
  end
  if log_type == "Warn" then
    MailR.logger:Warn(log_content)
  end
end

local function emit_message(log_type, text)
  if (text == "") then
    text = "[Empty String]"
  end
  create_log(log_type, text)
end

local function emit_table(log_type, t, indent, table_history)
  indent = indent or "."
  table_history = table_history or {}

  for k, v in pairs(t) do
    local vType = type(v)

    emit_message(log_type, indent .. "(" .. vType .. "): " .. tostring(k) .. " = " .. tostring(v))

    if (vType == "table") then
      if (table_history[v]) then
        emit_message(log_type, indent .. "Avoiding cycle on table...")
      else
        table_history[v] = true
        emit_table(log_type, v, indent .. "  ", table_history)
      end
    end
  end
end

function MailR.dm(log_type, ...)
  if not MailR.logger then return end
  if not MailR.show_log then return end
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if (type(value) == "table") then
      emit_table(log_type, value)
    else
      emit_message(log_type, tostring(value))
    end
  end
end

-- temp fix for Wykyyds Mailbox
if type(WYK_MailBox) == "table" then
  WYK_MailBox.ReadMail = function() return end
end
-- /GLOBALS


-- When Reply Button Clicked or Key Pressed
function MailR.CreateReply()
  -- make sure we only try to create/show a reply when the mailInbox is active
  if not MailR.mailboxActive then return end
  if SCENE_MANAGER.currentScene.name ~= "mailInbox" then return end

  if MailR.IsMailIdSentMail(MAIL_INBOX.mailId) then
    local sentMail = MailR.SavedMail.sent_messages[MAIL_INBOX.mailId]["isSentMail"]
    if sentMail == nil or sentMail == true then
      return
    end
    local isReturnable = MailR.SavedMail.sent_messages[MAIL_INBOX.mailId]["returnable"]
    if isReturnable == nil or isReturnable == false then
      return
    end
  else
    if not MailR.currentMessageInfo.returnable then return end
    local openMailId = MAIL_INBOX:GetOpenMailId()
    if not MAIL_INBOX:GetMailData(openMailId) then return end
  end

  MailR.dm("Debug", "Creating Reply")

  ZO_MenuBar_SelectDescriptor(ZO_MainMenuSceneGroupBar, "mailSend", nil, nil)

  -- ZO_MainMenuSceneGroupBarButton2.m_object.m_buttonData:callback()
  ZO_MailSendToField:SetText(MailR.currentMessageInfo["displayName"])
  local reStr = MailR.localeStringMap[MailR.effective_lang]["Re: "]
  local replyString = MailR.currentMessageInfo["subject"]:gsub("^" .. reStr, "")
  ZO_MailSendSubjectField:SetText(reStr .. replyString)
  ZO_MailSendBodyField:TakeFocus()
end

-- When Forward Button Clicked or Key Pressed
function MailR.CreateForward()
  -- make sure we only try to create/show a reply when the mailInbox is active
  MailR.dm("Debug", "CreateForward")
  if not MailR.mailboxActive then return end
  MailR.dm("Debug", "mailboxActive")
  if SCENE_MANAGER.currentScene.name ~= "mailInbox" then return end
  if MailR.currentMessageInfo["numAttachments"] == nil or MailR.currentMessageInfo["isSentMail"] == nil then return end
  if MailR.currentMessageInfo["numAttachments"] > 0 and not MailR.currentMessageInfo["isSentMail"] then return end
  local openMailId = MAIL_INBOX:GetOpenMailId()
  if not MAIL_INBOX:GetMailData(openMailId) then return end

  MailR.dm("Debug", "Creating Forward")

  ZO_MainMenuSceneGroupBarButton2.m_object.m_buttonData:callback()
  local fwdStr = MailR.localeStringMap[MailR.effective_lang]["Fwd: "]
  local replyString = MailR.currentMessageInfo["subject"]:gsub("^" .. fwdStr, "")
  ZO_MailSendSubjectField:SetText(fwdStr .. replyString)
  local origStr = MailR.localeStringMap[MailR.effective_lang]["Original Message"]
  local bodyStr = "\n***" .. MailR.DEFAULT_HEADER_COLOR_STRING .. origStr .. MailR.RESET_COLOR_STRING .. "***\n"
  local senderStr = MailR.currentMessageInfo["displayName"]
  if not MailR.currentMessageInfo["characterName"] == "" and not MailR.currentMessageInfo["characterName"] == nil then
    senderStr = MailR.currentMessageInfo["characterName"] .. "(" .. senderStr .. ")"
  end
  bodyStr = bodyStr .. MailR.DEFAULT_HEADER_COLOR_STRING .. MailR.localeStringMap[MailR.effective_lang]["From: "] .. MailR.RESET_COLOR_STRING .. senderStr .. "\n"
  bodyStr = bodyStr .. "\n" .. MailR.currentMessageInfo["body"] .. "\n"
  bodyStr = bodyStr .. "***" .. MailR.DEFAULT_HEADER_COLOR_STRING .. "/" .. MailR.localeStringMap[MailR.effective_lang]["Original Message"] .. MailR.RESET_COLOR_STRING .. "***\n"
  ZO_MailSendBodyField:SetText(bodyStr)
  ZO_MailSendBodyField:TakeFocus()

end

-- Handles when a message in the inbox is selected
function MailR.InboxMessageSelected(eventCode, mailId)
  MailR.dm("Verbose", "InboxMessageSelected")
  MailR.dm("Verbose", mailId)
  MailR.dm("Verbose", { GetMailItemInfo(idmailId) })

  local senderDisplayName, senderCharacterName, subject, icon, unread,
  fromSystem, fromCustomerService, returned, numAttachments, attachedMoney,
  codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)

  --[[ TODO: Update the concept of isSentMail such that when you send mail
  it is auto saved and flagged as sent. Received Mail is flagged when saved.
  However, both types then indicate that it is a MailR mail and not player or
  system mail.
  ]]--
  MailR.currentMessageInfo["isSentMail"] = MailR.IsMailIdSentMail(mailId)
  MailR.currentMessageInfo["isReceivedMail"] = false
  MailR.currentMessageInfo["displayName"] = senderDisplayName
  MailR.currentMessageInfo["recipient"] = senderDisplayName
  MailR.currentMessageInfo["characterName"] = senderCharacterName
  MailR.currentMessageInfo["subject"] = subject
  MailR.currentMessageInfo["body"] = ZO_MailInboxMessageBody:GetText()
  MailR.currentMessageInfo["numAttachments"] = numAttachments
  MailR.currentMessageInfo["secsSinceReceived"] = secsSinceReceived
  MailR.currentMessageInfo["timeSent"] = GetTimeStamp() - secsSinceReceived
  MailR.currentMessageInfo["attachments"] = {}
  MailR.currentMessageInfo["gold"] = 0
  MailR.currentMessageInfo["cod"] = false
  MailR.currentMessageInfo["postage"] = 0
  MailR.currentMessageInfo["mailId"] = mailId
  for a = 1, MailR.MAX_ATTACHMENTS do
    table.insert(MailR.currentMessageInfo["attachments"], {})
  end
  --[[ we dont do anything with this information yet
  if not MailR.IsMailIdSentMail(mailId) then

  TODO: Make sure the attachments are saved with the mail
  because previously it was checked whether or not it was
  sent mail
  ]]--
  for a = 1, numAttachments do
    local textureName, stack, creatorName = GetAttachedItemInfo(mailId, a)
    local link = GetAttachedItemLink(mailId, a, LINK_STYLE_DEFAULT)
    local icon = GetItemLinkInfo(link)
    MailR.currentMessageInfo["attachments"][a].textureName = textureName
    MailR.currentMessageInfo["attachments"][a].stack = stack
    MailR.currentMessageInfo["attachments"][a].creatorName = creatorName
    MailR.currentMessageInfo["attachments"][a].link = link
    MailR.currentMessageInfo["attachments"][a].icon = icon
  end
  --[[
  end

  TODO: Make sure the attachments are saved with the mail
  because previously it was checked whether or not it was
  sent mail
  ]]--
  -- shoud we include the body of the original message? Is there a message limit?

  -- this doesnt seem to return what I expect so use whats below
  --if IsMailReturnable(mailId) then
  -- some messages you cant reply to (e.g. system messages)
  if senderDisplayName == nil or senderDisplayName == "" or fromSystem or MailR.IsMailIdSentMail(mailId) then
    MailR.currentMessageInfo["returnable"] = false
  else
    MailR.currentMessageInfo["returnable"] = true
  end
end

-- Mail UI opened
function MailR.SetMailboxActive(eventCode)
  MailR.dm("Debug", "SetMailboxActive")
  MailR.mailboxActive = true
end

-- Mail UI closed
function MailR.SetMailboxInactive(eventCode)
  MailR.dm("Debug", "SetMailboxInactive")
  MailR.mailboxActive = false
end

function MailR.GuildMailCancel()
  MailR.CancelGuildMail = true
  SendProgressLabel:SetText("Canceling...")
  SendProgressButton:SetEnabled(false)
  --MailR.FinishedGuildMail()
end

function MailR.ShowGuildies()
  Guildies:SetHidden(false)
  MailR.guildies_visible = true
  local numGuilds = GetNumGuilds()
  for i = 1, numGuilds do
    local guildId = GetGuildId(i)
    local guildName = GetGuildName(guildId)
    MailR.guilds[guildName] = guildId
    local entry = MailR.GuildDropdown:CreateItemEntry(guildName,
      MailR.GuildItemSelect)  --this really just creates a table with {name = choices[i], callback = OnItemSelect} - you may be able to skip this step and just pass the correctly formatted table into the below function...
    MailR.GuildDropdown:AddItem(entry)
  end

  local w, h = ZO_MailSend:GetDimensions()
  Guildies:SetAnchor(TOPRIGHT, ZO_MailSend, TOPLEFT, -32, 0)
  Guildies:SetDimensions(512, h + 32)
  --Guildies:SetHidden(false)
end

function MailR.SendProgressChanged(control, value, eventReason)
  --MailR.GuildSendProgress:SetLabel("Sending..."..tostring(value))
end

function MailR.ThrottleTimerChanged(control, value, eventReason)
  --d(value, MailR.ThrottleTime)
  if value > MailR.SavedMail.throttle_time then
    MailR.GuildThrottleTimer:Stop()
    if not MailR.WaitingForResponse then
      local k, v = next(MailR.GuildRecipients)
      if MailR.CancelGuildMail then
        MailR.FinishedGuildMail()
        return
      end
      if k ~= nil then MailR.SendGuildMailMessage(k) end
    else
      if MailR.CancelGuildMail then
        MailR.FinishedGuildMail()
        return
      end
      SendProgressLabel:SetText(SendProgressLabel:GetText() .. "...Waiting For ZOS")
    end
  end
end

function MailR.GuildItemSelect(_, guildName, choiceNumber)
  MailR.dm("Debug", "GuildItemSelect")
  MailR.dm("Debug", guildName)
  MailR.dm("Debug", choiceNumber)
  MailR.dm("Debug", MailR.guilds[guildName])
  MailR.guildies = {}
  MailR.guildRanks = {}
  MailR.GuildRankDropdown:ClearItems()
  MailR.GuildStatusDropdown:ClearItems()
  MailR.GuildLogicDropdown:ClearItems()
  MailR.CurrentKnownGuild = { guildName, choiceNumber }
  local guildId = MailR.guilds[guildName]
  local numGuildies = GetNumGuildMembers(guildId)
  local entry
  for i = 1, numGuildies do
    local name, note, rankIndex, status, logoff = GetGuildMemberInfo(guildId, i)
    local rankName = GetFinalGuildRankName(guildId, rankIndex)
    local hasChar, charName, zoneName, classType, alliance, level, vr = GetGuildMemberCharacterInfo(guildId, i)
    if status == PLAYER_STATUS_OFFLINE then status = false else status = true end
    local data = { charName = charName:gsub("%^.*x$",
      ""), rankName = rankName, status = status, recipient = true }
    MailR.guildies[name] = data
  end
  local numGuildRanks = GetNumGuildRanks(guildId)
  for i = 1, numGuildRanks do
    local rankName = GetFinalGuildRankName(guildId, i)
    MailR.guildranks[rankName] = i
    entry = MailR.GuildRankDropdown:CreateItemEntry(rankName,
      MailR.GuildRankItemSelect)  --this really just creates a table with {name = choices[i], callback = OnItemSelect} - you may be able to skip this step and just pass the correctly formatted table into the below function...
    MailR.GuildRankDropdown:AddItem(entry)
  end
  entry = MailR.GuildRankDropdown:CreateItemEntry("All Members", MailR.GuildRankItemSelect)
  MailR.GuildRankDropdown:AddItem(entry)
  MailR.GuildRankDropdown:SetSelectedItem("All Members")

  entry = MailR.GuildStatusDropdown:CreateItemEntry("All", MailR.GuildStatusItemSelect)
  MailR.GuildStatusDropdown:AddItem(entry)
  entry = MailR.GuildStatusDropdown:CreateItemEntry("Online", MailR.GuildStatusItemSelect)
  MailR.GuildStatusDropdown:AddItem(entry)
  entry = MailR.GuildStatusDropdown:CreateItemEntry("Offline", MailR.GuildStatusItemSelect)
  MailR.GuildStatusDropdown:AddItem(entry)
  MailR.GuildStatusDropdown:SetSelectedItem("All")

  entry = MailR.GuildLogicDropdown:CreateItemEntry("==", MailR.GuildLogicItemSelect)
  MailR.GuildLogicDropdown:AddItem(entry)
  entry = MailR.GuildLogicDropdown:CreateItemEntry(">=", MailR.GuildLogicItemSelect)
  MailR.GuildLogicDropdown:AddItem(entry)
  entry = MailR.GuildLogicDropdown:CreateItemEntry("<=", MailR.GuildLogicItemSelect)
  MailR.GuildLogicDropdown:AddItem(entry)
  MailR.GuildLogicDropdown:SetSelectedItem("==")

  MailR.GuildControl:Update()
end

function MailR.GuildRankItemSelect(_, rankName, choiceNumber)
  MailR.dm("Debug", rankName)
  MailR.dm("Debug", choiceNumber)
  MailR.dm("Debug", MailR.guildranks[choiceNumber])
  local statusText = MailR.GuildStatusDropdown:GetSelectedItem()
  local status = true
  if statusText == "Offline" then status = false end
  local logicText = MailR.GuildLogicDropdown:GetSelectedItem()
  for k, v in pairs(MailR.guildies) do
    local recipient = true
    if not (v["status"] == status or statusText == "All") then recipient = false end
    if recipient then
      local guildRank = MailR.guildranks[rankName]
      if (v["rankName"] == rankName or rankName == "All Members") then
        recipient = true
      elseif logicText == ">=" then
        local checkRank = MailR.guildranks[v["rankName"]]
        if checkRank < guildRank then
          recipient = true
        else
          recipient = false
        end
      elseif logicText == "<=" then
        local checkRank = MailR.guildranks[v["rankName"]]
        if checkRank > guildRank then
          recipient = true
        else
          recipient = false
        end
      else
        recipient = false
      end
    end
    v["recipient"] = recipient
  end
  MailR.GuildControl:Update()
end

function MailR.GuildStatusItemSelect(_, statusText, choiceNumber)
  MailR.dm("Debug", statusText)
  MailR.dm("Debug", choiceNumber)
  local rankName = MailR.GuildRankDropdown:GetSelectedItem()
  local status = true
  if statusText == "Offline" then status = false end
  local logicText = MailR.GuildLogicDropdown:GetSelectedItem()
  for k, v in pairs(MailR.guildies) do
    local recipient = true
    if not (v["status"] == status or statusText == "All") then recipient = false end
    if recipient then
      local guildRank = MailR.guildranks[rankName]
      if (v["rankName"] == rankName or rankName == "All Members") then
        recipient = true
      elseif logicText == ">=" then
        local checkRank = MailR.guildranks[v["rankName"]]
        if checkRank < guildRank then
          recipient = true
        else
          recipient = false
        end
      elseif logicText == "<=" then
        local checkRank = MailR.guildranks[v["rankName"]]
        if checkRank > guildRank then
          recipient = true
        else
          recipient = false
        end
      else
        recipient = false
      end
    end
    v["recipient"] = recipient
  end
  MailR.GuildControl:Update()

end

function MailR.GuildLogicItemSelect(_, logicText, choiceNumber)
  MailR.dm("Debug", logicText)
  MailR.dm("Debug", choiceNumber)
  local rankName = MailR.GuildRankDropdown:GetSelectedItem()
  local statusText = MailR.GuildStatusDropdown:GetSelectedItem()
  local status = true
  if statusText == "Offline" then status = false end
  for k, v in pairs(MailR.guildies) do
    local recipient = true
    if not (v["status"] == status or statusText == "All") then recipient = false end
    if recipient then
      local guildRank = MailR.guildranks[rankName]
      if (v["rankName"] == rankName or rankName == "All Members") then
        recipient = true
      elseif logicText == ">=" then
        local checkRank = MailR.guildranks[v["rankName"]]
        if checkRank < guildRank then
          recipient = true
        else
          recipient = false
        end
      elseif logicText == "<=" then
        local checkRank = MailR.guildranks[v["rankName"]]
        if checkRank > guildRank then
          recipient = true
        else
          recipient = false
        end
      else
        recipient = false
      end
    end
    v["recipient"] = recipient
  end
  MailR.GuildControl:Update()
end

-- Get Keybind Layer Index by Layer Name
function MailR.GetKeybindLayerIndex(layerName)
  local layers = GetNumActionLayers()
  for layer = 1, layers do
    if GetActionLayerInfo(layer) == layerName then return layer end
  end

  return 0
end

-- Get keybind category index by name
function MailR.GetKeybindCategoryIndex(layerIndex, categoryName)
  local layerName, numCategories = GetActionLayerInfo(layerIndex)
  for category = 1, numCategories do
    if GetActionLayerCategoryInfo(layerIndex, category) == categoryName then return category end
  end

  return 0
end

-- get keybind action index by name
function MailR.GetKeybindActionIndex(layerIndex, categoryIndex, actionName)
  local categoryName, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
  for action = 1, numActions do
    if GetActionInfo(layerIndex, categoryIndex, action) == actionName then return action end
  end

  return 0
end

-- get only the primary keybind. Suspect there is a oneliner API func somewhere
function MailR.GetPrimaryKeybindInfo(layerName, categoryName, actionName)
  local primaryBindIndex = 1
  local layerIndex = MailR.GetKeybindLayerIndex(layerName)
  local categoryIndex = MailR.GetKeybindCategoryIndex(layerIndex, categoryName)
  local actionIndex = MailR.GetKeybindActionIndex(layerIndex, categoryIndex, actionName)
  local keyCode = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, primaryBindIndex)
  local keyName = GetKeyName(keyCode)
  return { keyCode, keyName }
end

-- somebody updated their keybinds so we should probably update too
function MailR.UpdateKeybindInfo(eventCode)
  local replyKeybind = MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR",
    "MAIL_REPLY")
  local forwardKeybind = MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR",
    "MAIL_FORWARD")
  MailR.keybindInfo["REPLY"] = replyKeybind
  MailR.keybindInfo["FORWARD"] = forwardKeybind
end

-- called when text in recipient field of composed message is updated
--TODO Keep: Examine why this is needed
function MailR.UpdateSendTo()
  MailR.dm("Verbose", "recipient updated")
  MailR.currentSendMessageInfo["recipient"] = ZO_MailSendToField:GetText()
end

-- called when text in subject field of composed message is updated
--TODO Keep: Examine why this is needed
function MailR.UpdateSendSubject()
  MailR.dm("Verbose", "subject updated")
  MailR.currentSendMessageInfo["subject"] = ZO_MailSendSubjectField:GetText()
end

-- called when text in body field of composed message is updated
--TODO Keep: Examine why this is needed
function MailR.UpdateSendBody()
  MailR.dm("Verbose", "body updated")
  MailR.currentSendMessageInfo["body"] = ZO_MailSendBodyField:GetText()
end

MailR.MAX_MAILID = 2147483647
function MailR.GenerateMailId()
  return math.random(MailR.MAX_MAILID)
end

function MailR.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

function MailR.MailSentSuccessfully(eventCode, playerName)
  MailR.dm("Debug", "MailSentSuccessfully")
  if next(MailR.queuedSentMessage) == nil then return end
  if next(MailR.GuildRecipients) ~= nil then return end
  MailR.queuedSentMessage["timeSent"] = GetTimeStamp()
  if MailR.rtrim(MailR.queuedSentMessage["subject"]) == "" then
    MailR.queuedSentMessage["subject"] = "(No Subject)"
  end
  MailR.queuedSentMessage["isSentMail"] = true
  -- MailR.dm("Debug", MailR.queuedSentMessage)
  local mailId = MailR.GenerateMailId()
  while MailR.SavedMail.sent_messages["MailR_" .. tostring(mailId)] ~= nil do
    mailId = MailR.GenerateMailId()
  end
  MailR.SavedMail.sent_messages["MailR_" .. tostring(mailId)] = MailR.CopyMessage(MailR.queuedSentMessage)
  MailR.SavedMail.sent_count = MailR.SavedMail.sent_count + 1
  MailR.ClearCurrentSendMessage()
  MailR.queuedSentMessage = {}
  QueueMoneyAttachment(0) --reset per awesomebillys recommendation for known COD bug as of 2014-05-15
  MAIL_INBOX:RefreshData()
end

-- clear current message table
function MailR.ClearCurrentSendMessage()
  MailR.currentSendMessageInfo["recipient"] = ""
  MailR.currentSendMessageInfo["subject"] = ""
  MailR.currentSendMessageInfo["body"] = ""
  MailR.currentSendMessageInfo["gold"] = 0
  MailR.currentSendMessageInfo["cod"] = false
  MailR.currentSendMessageInfo["postage"] = 0
  MailR.currentSendMessageInfo["timeSent"] = 0
  MailR.currentSendMessageInfo["attachments"] = {}
  for a = 1, MailR.MAX_ATTACHMENTS do
    table.insert(MailR.currentSendMessageInfo["attachments"], {})
  end
end

-- copy message_table to a new table
function MailR.CopyMessage(messageToCopy)
  local copyMessage = {}
  copyMessage["recipient"] = messageToCopy["recipient"]
  copyMessage["subject"] = messageToCopy["subject"]
  copyMessage["body"] = messageToCopy["body"]
  copyMessage["gold"] = messageToCopy["gold"]
  copyMessage["cod"] = messageToCopy["cod"]
  copyMessage["postage"] = messageToCopy["postage"]
  copyMessage["timeSent"] = messageToCopy["timeSent"]
  copyMessage["isSentMail"] = messageToCopy["isSentMail"]
  copyMessage["isReceivedMail"] = messageToCopy["isReceivedMail"]
  copyMessage["returnable"] = messageToCopy["returnable"]
  copyMessage["attachments"] = {}
  for a = 1, MailR.MAX_ATTACHMENTS do
    table.insert(copyMessage["attachments"], messageToCopy["attachments"][a])
  end
  return copyMessage
end

-- called when attachments are added to composed mail
function MailR.AttachmentAdded(eventCode, slot)
  MailR.dm("Debug", "AttachmentAdded")
  local attachment = ZO_MailSendAttachments:GetChild(slot)
  local bagid = attachment.bagId
  local slotid = attachment.slotIndex
  local stack = attachment.stackCount
  local link = GetItemLink(bagid, slotid, LINK_STYLE_DEFAULT)
  local icon = GetItemLinkInfo(link)
  MailR.currentSendMessageInfo["attachments"][slot] = { ["stack"] = stack, ["link"] = link, ["icon"] = icon }
  MailR.currentSendMessageInfo["postage"] = GetQueuedMailPostage()
end

-- called when attachments are removed from composed mail
function MailR.AttachmentRemoved(eventCode, slot)
  MailR.dm("Debug", "AttachmentRemoved")
  MailR.currentSendMessageInfo["attachments"][slot] = {}
  MailR.currentSendMessageInfo["postage"] = GetQueuedMailPostage()
end

-- called when attached money updated
function MailR.AttachmentMoneyChanged(eventCode, gold)
  MailR.currentSendMessageInfo["gold"] = gold
  MailR.currentSendMessageInfo["postage"] = GetQueuedMailPostage()
end

-- called when changed from gold payment to COD
function MailR.CODChanged()
  if GetQueuedCOD() > 0 then
    MailR.currentSendMessageInfo["cod"] = true
    MailR.currentSendMessageInfo["gold"] = GetQueuedCOD()
  else
    MailR.currentSendMessageInfo["cod"] = false
  end
  MailR.currentSendMessageInfo["postage"] = GetQueuedMailPostage()
end

function MailR.GuildMailSent(eventCode, playerName)
  MailR.dm("Debug", "GuildMailSent")
  MailR.WaitingForResponse = false
  local k, v = next(MailR.GuildRecipients)
  if k == nil or MailR.CancelGuildMail then
    MailR.FinishedGuildMail()
    return
  end
  MailR.guildies[MailR.LastKnownRecipient.name].recipient = false
  MailR.RecipientCount = MailR.RecipientCount + 1
  SendProgressStatus:SetValue(MailR.RecipientCount)
  SendProgressLabel:SetText("Sent " .. tostring(MailR.RecipientCount) .. "/" .. tostring(MailR.GuildRecipientCount))
  if not MailR.GuildThrottleTimer:IsStarted() then
    MailR.SendGuildMailMessage(k)
  end
  MailR.GuildControl:RefreshVisible()
end

function MailR.GuildMailFailSent()
  MailR.dm("Debug", "Mail Failed To Send To")
  MailR.dm("Debug", MailR.LastKnownRecipient)
  MailR.WaitingForResponse = false
  local k, v = next(MailR.GuildRecipients)
  if k == nil or MailR.CancelGuildMail then
    MailR.FinishedGuildMail()
    return
  end
  MailR.RecipientCount = MailR.RecipientCount + 1
  SendProgressStatus:SetValue(MailR.RecipientCount)
  SendProgressLabel:SetText("Sent " .. tostring(MailR.RecipientCount) .. "/" .. tostring(MailR.GuildRecipientCount))
  if not MailR.GuildThrottleTimer:IsStarted() then
    MailR.SendGuildMailMessage(k)
  end
end

function MailR.FinishedGuildMail()
  MailR.dm("Debug", "FinishedGuildMail")
  MAIL_SEND:ClearFields()
  QueueMoneyAttachment(0) -- just to make sure
  MailR.GuildThrottleTimer:Stop()
  SendProgress:SetHidden(true)

  local k, v = next(MailR.GuildRecipients)
  MailR.GuildRecipients = {}
  if MailR.CancelGuildMail and k ~= nil then
    toStr = MailR.queuedSentMessage["recipient"]:gsub(" %([0-9]*%)", "")
    toStr = toStr .. " (" .. tostring(MailR.RecipientCount) .. "/" .. tostring(MailR.GuildRecipientCount) .. ")"
    MailR.queuedSentMessage["recipient"] = toStr
    MailR.MailSentSuccessfully()
  end
  MailR.GuildMailRecipientsReady = false
  MailR.GuildRecipientCount = 0
  MailR.RecipientCount = 0
  MailR.ThrottledRecipients = 0
  GuildiesButton:SetEnabled(true)
  MailR.GuildControl:RefreshVisible()
end

function MailR.SendGuildMail()
  if not MailR.GuildMailRecipientsReady then return end
  MailR.GuildMailRecipientsReady = false
  MailR.GuildRecipients = {}
  MailR.GuildRecipient = {}
  MailR.LastKnownGuild = MailR.CurrentKnownGuild
  MailR.CancelGuildMail = false
  MailR.queuedSentMessage["body"] = MailR.queuedSentMessage["body"] .. "\n\nSent via MailR's Guild Mail"
  MailR.GuildRecipientCount = 0
  for k, v in pairs(MailR.guildies) do
    if GetDisplayName() ~= k and v["recipient"] then
      MailR.GuildRecipients[k] = v
      MailR.GuildRecipientCount = MailR.GuildRecipientCount + 1
    end
  end
  local k, v = next(MailR.GuildRecipients)
  if k == nil then
    MailR.FinishedGuildMail()
    return
  end

  SendProgressStatus:SetMinMax(0, MailR.GuildRecipientCount)
  SendProgress:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
  ThrottleTimer:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
  SendProgressButton:SetEnabled(true)
  GuildiesButton:SetEnabled(false)
  SendProgress:SetDrawLayer(3)
  SendProgressStatus:SetValue(0)
  MailR.RecipientCount = 0
  MailR.ThrottledRecipients = 0
  SendProgress:SetHidden(false)
  SendProgressLabel:SetText("Sent 0/" .. tostring(MailR.GuildRecipientCount))
  MailR.SendGuildMailMessage(k)
end

function MailR.SendGuildMailMessage(recipient)
  MailR.dm("Debug", "Sending GM To " .. recipient)
  local body = MailR.queuedSentMessage["body"]
  local subject = MailR.queuedSentMessage["subject"]
  MailR.WaitingForResponse = true
  MailR.LastKnownRecipient = MailR.GuildRecipients[recipient]
  SendMail(recipient, subject, body)
  MailR.GuildRecipients[recipient] = nil
  MailR.ThrottledRecipients = MailR.ThrottledRecipients + 1
  if MailR.ThrottledRecipients >= MailR.ThrottleRecipients then
    MailR.ThrottledRecipients = 0
    MailR.GuildThrottleTimer:Start(GetFrameTimeSeconds(), GetFrameTimeSeconds() + MailR.SavedMail.throttle_time + 1)
  end
end

-- when SendMail is called do this first, otherwise currentSendMessageInfo gets cleared (by ZOS)
function MailR.QueueSentMessage()
  MailR.dm("Debug", "QueueSentMessage")
  MailR.queuedSentMessage = {}
  MailR.queuedSentMessage = MailR.CopyMessage(MailR.currentSendMessageInfo)
  if MailR.guildies_visible then
    MailR.queuedSentMessage["gold"] = 0
    MailR.queuedSentMessage["cod"] = false
    MailR.queuedSentMessage["postage"] = 0
    MailR.queuedSentMessage["attachments"] = {}
    for a = 1, MailR.MAX_ATTACHMENTS do
      table.insert(MailR.queuedSentMessage["attachments"], {})
    end
  end
end

function MailR.OnMouseUp(control, button, upInside)
  MailR.dm("Debug", "OnMouseUp")
  MAIL_INBOX:Row_OnMouseUp(control)
  if not control then return end
  local mailId = control.dataEntry.data.mailId

  if MailR.IsMailIdSentMail(mailId) then
    return
  end
  if button == 2 then
    ClearMenu()
    AddMenuItem("Save Message", MailR.SaveMail)
    ShowMenu()
  end
end

function MailR.SaveMail()
  MailR.dm("Debug", "SaveMail")
  local mail = MailR.currentMessageInfo
  local savedMailId = "MailR_" .. Id64ToString(MailR.currentMessageInfo.mailId)
  mail.isSentMail = false
  mail.isReceivedMail = true
  MailR.SavedMail.sent_messages[savedMailId] = MailR.CopyMessage(MailR.currentMessageInfo)
  MailR.SavedMail.sent_count = MailR.SavedMail.sent_count + 1
  KEYBIND_STRIP:UpdateKeybindButtonGroup(MAIL_INBOX.selectionKeybindStripDescriptor)
  MAIL_INBOX:RefreshData()
end

function MailR.ShowPlayerContextMenu(self, playerName, rawName)
  ShowPlayerContextMenu_Orig(self, playerName, rawName)
  AddMenuItem('Send Mail', function()
    SCENE_MANAGER:Show('mailSend')
    ZO_MailSendToField:SetText(playerName)
  end)
  ShowMenu()
end

function MailR.ShowPlayerInteractMenu(self, isIgnored)
  local currentTarget = self.currentTargetCharacterName
  local icons = {
    enabledNormal = "EsoUI/Art/Mail/mail_tabicon_compose_up.dds",
    enabledSelected = "EsoUI/Art/Mail/mail_tabicon_compose_down.dds",
    disabledNormal = "EsoUI/Art/Mail/mail_tabicon_compose_up.dds",
    disabledSelected = "EsoUI/Art/Mail/mail_tabicon_compose_down.dds",
  }
  self:AddMenuEntry("Send Mail", icons, isIgnored, function()
    SCENE_MANAGER:Show('mailSend')
    ZO_MailSendToField:SetText(currentTarget)
  end)
  ShowPlayerInteractMenu_Orig(self, isIgnored)
end

function MailR.CheckMailIdEquality(mailId1, mailId2)
  return mailId1 == mailId2
end

function MailR.MailIdEquality(...)
  MailR.dm("Debug", "MailIdEquality")
  -- return MailR.CheckMailIdEquality(data1.mailId, data2.mailId)
  return true
end

function MailR.GetMailData(self, mailId)
  if (self.masterList) then
    for i = 1, #self.masterList do
      local data = self.masterList[i]
      if data.mailId == mailId then
        return data
      end
    end
  end
end

function MailR.HasAlreadyReportedSelectedMail(self)
  if MailR.IsMailIdSentMail(self.mailId) then return end
  return self.reportedMailIds[zo_getSafeId64Key(self.mailId)]
end

MailR.defaultMailInboxFn = {}
function MailR.OverloadMailInbox()
  local originalIsMailReturnable = IsMailReturnable
  IsMailReturnable = function(mailId)
    if MailR.IsMailIdSentMail(mailId) then
      MailR.dm("Debug", "MailR IsMailReturnable")
      return false
    else
      MailR.dm("Debug", "Original IsMailReturnable")
      return originalIsMailReturnable(mailId)
    end
  end
  --[[ removed because it is not a ScrollList now
    MAIL_INBOX.IsMailReturnable = IsMailReturnable -- redefined above

    IsMailReturnable = function(mailId)
                            if MailR.IsMailIdSentMail(mailId) then
                                return false
                            else
                                return MAIL_INBOX.IsMailReturnable(mailId)
                            end
                        end
    MAIL_INBOX.IsMailReturnable = IsMailReturnable

    MAIL_INBOX.BuildMasterList = MailR.BuildMasterList
    MAIL_INBOX.OnSelectionChanged = MailR.OnSelectionChanged
    MAIL_INBOX.OnMailReadable = MailR.OnMailReadable
    MAIL_INBOX.RefreshAttachmentSlots = MailR.RefreshAttachmentSlots
    MAIL_INBOX.RefreshMoneyControls = MailR.RefreshMoneyControls
    MAIL_INBOX.RefreshAttachmentsHeaderShown = MailR.RefreshAttachmentsHeaderShown
    MAIL_INBOX.GetMailData = MailR.GetMailData
    MAIL_INBOX.RequestReadMessage = MailR.RequestReadMessage
    MAIL_INBOX.HasAlreadyReportedSelectedMail = MailR.HasAlreadyReportedSelectedMail
    local MAIL_DATA = 1
  MailR.dm("Debug", MAIL_DATA)
  local mailListData = MAIL_INBOX.masterList or {}
  mailListData[1] = {nothing = true}
  mailListData.dataTypes = {}
  mailListData.dataTypes[MAIL_DATA] = {}
  mailListData.dataTypes[MAIL_DATA].equalityFunction = {}
  MailR.dm("Debug", mailListData)
  MailR.dm("Debug", "ZO_ScrollList_SetEqualityFunction")
    ZO_ScrollList_SetEqualityFunction(mailListData, MAIL_DATA, function(...) MailR.MailIdEquality(...) end)
    GetNextMailId = MailR.GetNextMailId
    ZO_MailInboxRow_OnMouseUp = MailR.OnMouseUp
    MAIL_INBOX.GetMailItemInfo = GetMailItemInfo
    GetMailItemInfo = MailR.GetMailItemInfo
    ZO_PlayerToPlayer.ShowPlayerInteractMenu = MailR.ShowPlayerInteractMenu
  ]]--
  CHAT_SYSTEM.ShowPlayerContextMenu = MailR.ShowPlayerContextMenu
  MAIL_INBOX.IsMailDeletable = MailR.IsMailDeletable
  MAIL_INBOX.ConfirmDelete = MailR.ConfirmDelete
  MAIL_INBOX.Delete = MailR.Delete
  for i = 1, MailR.MAX_READ_ATTACHMENTS do
    table.insert(MailR.defaultMailInboxFn,
      { MAIL_INBOX.attachmentSlots[i]:GetHandler("OnMouseEnter"), MAIL_INBOX.attachmentSlots[i]:GetHandler("OnClicked"), MAIL_INBOX.attachmentSlots[i]:GetHandler("OnMouseDoubleClicked") })
  end

  -- overload keybinds...I think I have effectively rewritten ESO Mail at this point
  -- instead of adding on :/
  MAIL_INBOX.InitializeKeybindDescriptors = MailR.InitializeInboxKeybindDescriptors
  MAIL_INBOX:InitializeKeybindDescriptors()
end

function MailRGuild:Update()
  self:RefreshData()
end

function MailR.OverloadMailSend()
  MAIL_SEND.InitializeKeybindDescriptors = MailR.InitializeSendKeybindDescriptors
  MAIL_SEND:InitializeKeybindDescriptors()

  local dropdownContainer = CreateControlFromVirtual("GuildiesDropdown", Guildies, "ZO_StatsDropdownRow")
  dropdownContainer:SetAnchor(TOPLEFT, GuildiesHeading, BOTTOMLEFT, 0, 16)
  dropdownContainer:GetNamedChild("Dropdown"):SetWidth(200)
  -- MailR.GuildDropdown = dropdownContainer.dropdown
  GuildiesDropdown:SetWidth(200)

  local dropdownLogicContainer = CreateControlFromVirtual("GuildiesLogicDropdown", Guildies, "ZO_StatsDropdownRow")
  dropdownLogicContainer:SetAnchor(TOPLEFT, GuildiesDropdown, TOPRIGHT, 2, 0)
  dropdownLogicContainer:GetNamedChild("Dropdown"):SetWidth(60)
  -- MailR.GuildLogicDropdown = dropdownLogicContainer.dropdown
  GuildiesLogicDropdown:SetWidth(60)

  local dropdownRankContainer = CreateControlFromVirtual("GuildiesRankDropdown", Guildies, "ZO_StatsDropdownRow")
  dropdownRankContainer:SetAnchor(TOPLEFT, GuildiesLogicDropdown, TOPRIGHT, 2, 0)
  dropdownRankContainer:GetNamedChild("Dropdown"):SetWidth(128)
  -- MailR.GuildRankDropdown = dropdownRankContainer.dropdown
  GuildiesRankDropdown:SetWidth(128)

  local dropdownStatusContainer = CreateControlFromVirtual("GuildiesStatusDropdown", Guildies, "ZO_StatsDropdownRow")
  dropdownStatusContainer:SetAnchor(TOPLEFT, GuildiesRankDropdown, TOPRIGHT, 2, 0)
  dropdownStatusContainer:GetNamedChild("Dropdown"):SetWidth(88)
  -- MailR.GuildStatusDropdown = dropdownStatusContainer.dropdown
  GuildiesStatusDropdown:SetWidth(88)

  GuildiesHeaders:SetAnchor(TOPLEFT, GuildiesDropdown, BOTTOMLEFT, 0, 16)

  MailR.GuildControl = MailRGuild:New()
end

function MailR.Guild_MouseEnter(control)
  MailR.GuildControl:Row_OnMouseEnter(control)
end

function MailR.Guild_MouseExit(control)
  MailR.GuildControl:Row_OnMouseExit(control)
end

function MailR.ShowGuildiesFailed()
  if #MailR.LastKnownGuild == 0 then return end
  local count = 0
  for k, v in pairs(MailR.failed_guildies) do
    count = count + 1
  end
  if count == 0 then return end
  MailR.GuildDropdown:SelectItem(MailR.LastKnownGuild[2])
  for k, v in pairs(MailR.guildies) do
    d(k, v)
    if MailR.failed_guildies[k] ~= nil then
      MailR.guildies[k].recipient = true
    else
      MailR.guildies[k].recipient = false
    end
  end

  MailR.GuildControl:RefreshVisible()
end

function MailR.Guild_MouseUp(control, button, upInside)
  -- contro.data.name, etc
  local pressed_button = 1
  local api_ver = GetAPIVersion()

  if api_ver > 100011 then pressed_button = MOUSE_BUTTON_INDEX_LEFT end

  if button == pressed_button then

    local name = control.data.name
    if MailR.guildies[name]["recipient"] then
      MailR.guildies[name]["recipient"] = false
    else
      MailR.guildies[name]["recipient"] = true
    end
    MailR.GuildControl:RefreshVisible()

  end
  --MailR.Guild:MouseEnter(control, button, upInside)
end

MailR.SORT_KEYS = {
  ["name"] = {},
  ["status"] = { tiebreaker = "name" },
  ["rankName"] = { tiebreaker = "status" },
  ["recipient"] = { tiebreaker = "rankName" }
}

function MailRGuild:New()
  local guildies = ZO_SortFilterList.New(self, Guildies)

  guildies.masterList = {}
  --self.sortHeaderGroup:SelectHeaderByKey("timeStamp")

  ZO_ScrollList_AddDataType(guildies.list, 1, "GuildiesRow", 30,
    function(control, data) self:SetupGuildiesRow(control, data) end, nil, nil)

  ZO_ScrollList_EnableHighlight(guildies.list, "ZO_ThinListHighlight")
  guildies.sortFunction = function(listEntry1, listEntry2) return ZO_TableOrderingFunction(listEntry1.data,
    listEntry2.data, guildies.currentSortKey, MailR.SORT_KEYS, guildies.currentSortOrder) end

  guildies:RefreshData()
  return guildies
end

function MailRGuild:BuildMasterList()
  self.masterList = {}
  local guildies = MailR.guildies
  for k, v in pairs(guildies) do
    local data = v
    data["name"] = k
    table.insert(self.masterList, data)
  end
end

function MailRGuild:FilterScrollList()
  local scrollData = ZO_ScrollList_GetDataList(self.list)
  ZO_ClearNumericallyIndexedTable(scrollData)

  for i = 1, #self.masterList do
    local data = self.masterList[i]
    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
  end
end

function MailRGuild:SortScrollList()
  local scrollData = ZO_ScrollList_GetDataList(self.list)
  table.sort(scrollData, self.sortFunction)
end

MailR.ONLINE_TEXT = ZO_ColorDef:New(0.4627, 0.737, 0.7647, 1)
MailR.OFFLINE_TEXT = ZO_ColorDef:New(0.4, 0.4, 0.4, 1)
function MailRGuild:SetupGuildiesRow(control, data)
  control.data = data
  control.name = GetControl(control, "Name")
  control.status = GetControl(control, "Status")
  control.recipient = GetControl(control, "Recipient")
  control.rank = GetControl(control, "Rank")

  control.name:SetText(data.name)
  control.rank:SetText(data.rankName)
  control.recipient:SetText("Yes")
  control.status:SetText("Online")
  if data.recipient == false then
    control.recipient:SetText("No")
  end

  control.name.normalColor = MailR.ONLINE_TEXT
  control.rank.normalColor = MailR.ONLINE_TEXT
  control.recipient.normalColor = MailR.ONLINE_TEXT
  control.status.normalColor = MailR.ONLINE_TEXT

  if not data.status then
    control.status:SetText("Offline")
    control.name.normalColor = MailR.OFFLINE_TEXT
    control.rank.normalColor = MailR.OFFLINE_TEXT
    control.recipient.normalColor = MailR.OFFLINE_TEXT
    control.status.normalColor = MailR.OFFLINE_TEXT
  end
  self:SetLockedForUpdates(true)
  ZO_SortFilterList.SetupRow(self, control, data)
  self:SetLockedForUpdates(false)
end

function MailR.InitializeInboxKeybindDescriptors(self)

  local function ReportAndDeleteCallback()
    self:RecordSelectedMailAsReported()
    self:Delete()
  end

  self.selectionKeybindStripDescriptor = {
    alignment = KEYBIND_STRIP_ALIGN_CENTER,

    --Return
    {
      name = GetString(SI_MAIL_READ_RETURN),
      keybind = "UI_SHORTCUT_SECONDARY",

      callback = function()
        self:Return()
      end,

      visible = function()
        if self.mailId then
          return IsMailReturnable(self.mailId)
        end
        return false
      end
    },

    --Reply
    {
      name = GetString(SI_MAIL_READ_REPLY),
      keybind = "UI_SHORTCUT_TERTIARY",

      callback = function()
        self:Reply()
      end,

      visible = function()
        if self.mailId then
          local mailData = self:GetMailData(self.mailId)
          return mailData and mailData.isFromPlayer or false
        end
        return false
      end
    },

    -- Delete
    {
      name = GetString(SI_MAIL_READ_DELETE),
      keybind = "UI_SHORTCUT_NEGATIVE",

      callback = function()
        self:Delete()
      end,

      visible = function()
        if self.mailId then
          return not IsMailReturnable(self.mailId) and self:IsMailDeletable()
        end
        return false
      end
    },

    -- Take Attachments
    {
      name = GetString(SI_MAIL_READ_ATTACHMENTS_TAKE),
      keybind = "UI_SHORTCUT_PRIMARY",

      callback = function()
        self:TryTakeAll()
      end,

      visible = function()
        if self.mailId then
          local numAttachments, attachedMoney, codAmount = GetMailAttachmentInfo(self.mailId)
          if numAttachments > 0 or attachedMoney > 0 then
            return true
          end
        end
        return false
      end
    },

    --Report Player
    {
      name = GetString(SI_MAIL_READ_REPORT_PLAYER),
      keybind = "UI_SHORTCUT_REPORT_PLAYER",

      visible = function()
        if not self:HasAlreadyReportedSelectedMail() then
          local mailData = self:GetMailData(self.mailId)
          return mailData and mailData.isFromPlayer
        end
      end,

      callback = function()
        if self.mailId then
          local senderDisplayName = GetMailSender(self.mailId)
          local function ReportCallback()
            self:RecordSelectedMailAsReported()
            if not IsIgnored() then
              AddIgnore(senderDisplayName)
            end
          end
          ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(senderDisplayName, ReportCallback)
        end
      end,
    },

    --Forward Mail
    {
      name = MailR.localeStringMap[MailR.effective_lang]["Forward"],
      keybind = "MAIL_FORWARD", --MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR", "MAIL_FORWARD")[2],

      visible = function()
        if MailR.IsMailIdSentMail(self.mailId) then
          return true
        end
        if (self.mailId) then
          return not IsMailReturnable(self.mailId)
        end
      end,

      callback = function()
        if (self.mailId) then
          MailR.CreateForward()
        end
      end,
    },

    --Save Mail
    {
      name = MailR.localeStringMap[MailR.effective_lang]["Save Mail"],
      keybind = "MAIL_SAVE", --MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR", "MAIL_SAVE")[2],

      visible = function()
        if self.mailId == nil then return false end
        if not MailR.SavedMail.sent_messages["MailR_" .. Id64ToString(self.mailId)] then
          return true
        end
      end,

      callback = function()
        if self.mailId then
          MailR.SaveMail()
        end
      end,
    },
  }
end

function MailR:InitializeSendKeybindDescriptors()
  self.staticKeybindStripDescriptor = {
    alignment = KEYBIND_STRIP_ALIGN_CENTER,

    -- Clear
    {
      name = GetString(SI_MAIL_SEND_CLEAR),
      keybind = "UI_SHORTCUT_NEGATIVE",
      callback = function()
        ZO_Dialogs_ShowDialog("CONFIRM_CLEAR_MAIL_COMPOSE", { callback = function() self:ClearFields() end })
      end,
    },

    -- Send
    {
      name = GetString(SI_MAIL_SEND_SEND),
      keybind = "UI_SHORTCUT_SECONDARY",
      callback = function()
        MailR.QueueSentMessage()
        self:Send()
      end,
    },
  }
end

function MailR.ConfirmDelete(self)
  if MailR.IsMailIdSentMail(self.mailId) then
    MailR.SavedMail.sent_messages[self.mailId] = nil
    MailR.SavedMail.sent_count = #MailR.SavedMail.sent_messages
    PlaySound(SOUNDS.MAIL_ITEM_DELETED)
    MAIL_INBOX:RefreshData()
    return
  end

  -- original
  if self.mailId and not IsMailReturnable(self.mailId) then
    DeleteMail(self.mailId, true)
    PlaySound(SOUNDS.MAIL_ITEM_DELETED)
  end
end

function MailR.Delete(self)
  MailR.dm("Debug", "Delete")
  if MailR.IsMailIdSentMail(self.mailId) then
    self:ConfirmDelete()
    return
  end

  -- original
  if self.mailId then
    if self:IsMailDeletable() then
      local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)

      if numAttachments > 0 and attachedMoney > 0 then
        ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS_AND_MONEY", self.mailId)
      elseif numAttachments > 0 then
        ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS", self.mailId)
      elseif attachedMoney > 0 then
        ZO_Dialogs_ShowDialog("DELETE_MAIL_MONEY", self.mailId)
      else
        --no confirmation popup, immediately delete
        self:ConfirmDelete()
      end
    end
  end
end

function MailR.IsMailDeletable(self)
  if MailR.IsMailIdSentMail(self.mailId) then
    return true
  end

  -- original
  local mailData = self:GetMailData(self.mailId)
  if (mailData) then
    return mailData.attachedMoney == 0 and mailData.numAttachments == 0
  end
end

function MailR.GetMailItemInfo(mailId)
  if not MailR.IsMailIdSentMail(mailId) then
    local senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = MAIL_INBOX.GetMailItemInfo(mailId)
    return senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived
  else
    local message = MailR.GetSentMessageFromMailId(mailId)
    local senderDisplayName = message.recipient
    local senderCharacterName = ""
    local subject = message.subject
    local icon = "/esoui/art/mail/mail_inbox_readmessage.dds"
    local unread = false
    local fromSystem = false
    local fromCustomerService = false
    local returned = false
    local count = 0
    for i = 1, MailR.MAX_ATTACHMENTS do
      if message.attachments[i].stack ~= nil then
        count = count + 1
      end
    end
    local numAttachments = count
    local codAmount = 0
    local attachedMoney = 0
    if message.cod then
      codAmount = message.gold
      attachedMoney = 0
    else
      codAmount = 0
      attachedMoney = message.gold
    end
    local expiresInDays = 1
    local secsSinceReceived = GetDiffBetweenTimeStamps(GetTimeStamp(), message.timeSent)

    return senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived
  end
end

function MailR.GetMailAttachmentInfo(self, mailId)
  if MailR.IsMailIdSentMail(mailId) then
    local message = MailR.GetSentMessageFromMailId(mailId)
    return message.numAttachments, message.gold
  else
    return select(9, GetMailItemInfo(mailId))
  end
end

function MailR.RequestReadMessage(self, mailId)
  -- this should not be called if mailId is a MAILR id, but the previously/currently selected
  -- mailId can be a MAILR id causing the AreId64sEqual check to fail, when really
  -- we want it to request read mail
  --	if MailR.IsMailIdSentMail(self.mailId) or  then
  if type(self.mailId) == "string" or not AreId64sEqual(self.mailId, mailId) then
    -- hack for deleted MAILR messages
    RequestReadMail(mailId)
    return
  end
end

function MailR.OnSelectionChanged(self, previouslySelected, selected, reselectingDuringRebuild)
  ZO_SortFilterList.OnSelectionChanged(self, previouslySelected, selected)
  if (not reselectingDuringRebuild) then
    if selected and MailR.IsMailIdSentMail(selected.mailId) then
      MailR.OnMailReadable(self, selected.mailId)
      MailR.InboxMessageSelected(nil, selected.mailId)
    elseif (selected) then
      MAIL_INBOX:RequestReadMessage(selected.mailId)
    else
      MAIL_INBOX:EndRead()
    end
  end
end

function GetMailFlags(mailId)
  local unread, returned, fromSystem, fromCustomerService = select(5, GetMailItemInfo(mailId))
  return unread, returned, fromSystem, fromCustomerService
end

function GetMailAttachmentInfo(mailId)
  local numAttachments, attachedMoney, codAmount = select(9, GetMailItemInfo(mailId))
  return numAttachments, attachedMoney, codAmount
end

function GetMailSender(mailId)
  local senderDisplayName, senderCharacterName = GetMailItemInfo(mailId)
  return senderDisplayName, senderCharacterName
end

function MailR.GetNextMailIdIter(state, var1)
  return GetNextMailId(var1)
end

function MailR.GetNextMailId(mailId)
  local nextMailId = nil

  if not MailR.IsMailIdSentMail(mailId) then
    --valid mailId or nil to get first message
    nextMailId = GetNextMailId_Orig(mailId)
  end

  if nextMailId == nil then
    --custom mailId or no next mail in the inbox, try to get next Id from saved mail
    nextMailId = next(MailR.SavedMail.sent_messages, mailId)
  end

  return nextMailId
end

function MailR.IsMailIdSentMail(mailId)
  if type(mailId) ~= "string" then return false end
  -- local uniqueMailID = Id64ToString(mailId)
  if mailId == nil or MailR.SavedMail.sent_messages[mailId] == nil then return false end
  return true
end

function MailR.GetSentMessageFromMailId(mailId)
  if MailR.IsMailIdSentMail(mailId) then
    return MailR.SavedMail.sent_messages[mailId]
  else
    return nil
  end
end

function MailR.GenerateBodyMessageForViewing(message)
  local originalBody = message.body .. "\n\n"
  local attachedGoldStr = MailR.localeStringMap[MailR.effective_lang]["Attached Gold: "]
  local codStr = MailR.localeStringMap[MailR.effective_lang]["COD: "]
  local postageStr = MailR.localeStringMap[MailR.effective_lang]["Postage: "]
  local attachmentStr = MailR.localeStringMap[MailR.effective_lang]["Attachments: "]
  local goldString = MailR.DEFAULT_HEADER_COLOR_STRING .. attachedGoldStr .. MailR.RESET_COLOR_STRING .. tostring(message.gold) .. "\n"
  local codString
  if message.cod then
    codString = MailR.DEFAULT_HEADER_COLOR_STRING .. codStr .. MailR.RESET_COLOR_STRING .. "Yes\n"
  else
    codString = MailR.DEFAULT_HEADER_COLOR_STRING .. codStr .. MailR.RESET_COLOR_STRING .. "No\n"
  end
  local postageString = MailR.DEFAULT_HEADER_COLOR_STRING .. postageStr .. MailR.RESET_COLOR_STRING .. tostring(message.postage) .. "\n"
  local attachmentString = MailR.DEFAULT_HEADER_COLOR_STRING .. attachmentStr .. "\n" .. MailR.RESET_COLOR_STRING
  for i = 1, MailR.MAX_ATTACHMENTS do
    -- message.numAttachments do
    if message.attachments[i].stack ~= nil then
      local count = message.attachments[i].stack
      local link = message.attachments[i].link
      attachmentString = attachmentString .. tostring(count) .. "x" .. link .. "\n"
    end
  end
  local bodyString = originalBody .. goldString .. codString .. postageString .. attachmentString
  return bodyString
end

function MailR.OnMailReadable(self, mailId)
  if self.control:IsHidden() then
    self.dirtyMail = mailId
    return
  end
  self.dirtyMail = nil
  self:EndRead()

  local sentMail = MailR.IsMailIdSentMail(mailId)
  if sentMail then
    sentMail = MailR.SavedMail.sent_messages[mailId]["isSentMail"]
    -- required to support old saved mail
    if sentMail == nil then
      sentMail = true
    end
  else
    sentMail = nil
  end

  self.mailId = mailId
  self.messageControl:SetHidden(false)
  KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)
  -- do this here instead of above so controls from KeybindButtonGroup display correctly
  self.mailId = mailId

  local mailData
  if sentMail ~= nil then
    local sentMessage = MailR.GetSentMessageFromMailId(mailId)
    mailData = MailR.ConvertSavedMessageToMailData(mailId, sentMessage)
  else
    mailData = self:GetMailData(mailId)
    ZO_MailInboxShared_PopulateMailData(mailData, mailId)
  end
  ZO_ScrollList_RefreshVisible(self.list, mailData)

  -- start custom ZO_MailInboxShared_UpdateInbox
  local body
  if sentMail ~= nil then
    body = MailR.GenerateBodyMessageForViewing(MailR.GetSentMessageFromMailId(mailId))
  else
    body = ReadMail(mailId)
    if (body == "") then
      body = GetString(SI_MAIL_READ_NO_BODY)
    end
  end

  local fromLabel = GetControl(self.messageControl, "From")
  fromLabel:SetText(mailData.senderDisplayName)
  if sentMail == true then
    GetControl(self.messageControl, "FromLabel"):SetText(MailR.localeStringMap[MailR.effective_lang]["To:"])
    GetControl(self.messageControl, "ReceivedLabel"):SetText(MailR.localeStringMap[MailR.effective_lang]["Sent:"])
  else
    GetControl(self.messageControl, "FromLabel"):SetText(GetString(SI_MAIL_READ_FROM_LABEL))
    GetControl(self.messageControl, "ReceivedLabel"):SetText(GetString(SI_MAIL_READ_RECEIVED_LABEL))
  end
  if (mailData.fromCS or mailData.fromSystem) then
    fromLabel:SetColor(ZO_GAME_REPRESENTATIVE_TEXT:UnpackRGBA())
  else
    fromLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
  end

  GetControl(self.messageControl, "Subject"):SetText(mailData:GetFormattedSubject())
  GetControl(self.messageControl, "Expires"):SetText(mailData:GetExpiresText())
  GetControl(self.messageControl, "Received"):SetText(mailData:GetReceivedText())
  GetControl(self.messageControl, "Body"):SetText(body)
  -- end custom ZO_MailInboxShared_UpdateInbox
  --ZO_MailInboxShared_UpdateInbox(mailData, GetControl(self.messageControl, "From"), GetControl(self.messageControl, "Subject"), GetControl(self.messageControl, "Expires"), GetControl(self.messageControl, "Received"), GetControl(self.messageControl, "Body"))
  ZO_Scroll_ResetToTop(GetControl(self.messageControl, "Pane"))

  self:RefreshMoneyControls()
  self:RefreshAttachmentsHeaderShown()
  self:RefreshAttachmentSlots()
end

MailR.MAX_READ_ATTACHMENTS = MailR.MAX_ATTACHMENTS + 1
function MailR.RefreshAttachmentSlots(self)
  local sentMail = MailR.IsMailIdSentMail(self.mailId)
  local mailData
  local sentMessage
  if sentMail then
    sentMessage = MailR.GetSentMessageFromMailId(self.mailId)
    mailData = MailR.ConvertSavedMessageToMailData(self.mailId, sentMessage)
  else
    mailData = self:GetMailData(self.mailId)
  end
  local numAttachments = mailData.numAttachments

  -- have to do this for now, I really need to update the savedvariable table to not have static attachment allocations
  local sentMailAttachments = {}
  if sentMail then
    for i = 1, MailR.MAX_ATTACHMENTS do
      if sentMessage.attachments[i].stack ~= nil then
        table.insert(sentMailAttachments, sentMessage.attachments[i])
      end
    end
  end

  for i = 1, numAttachments do
    self.attachmentSlots[i]:SetHidden(false)
    local icon, stack, creator
    if sentMail then
      icon = sentMailAttachments[i].icon
      stack = sentMailAttachments[i].stack
    else
      icon, stack, creator = GetAttachedItemInfo(self.mailId, i)
    end
    if sentMail then
      -- I think this can be done by using the button control EnableMouseButton function
      -- will try in code refactor
      self.attachmentSlots[i]:SetHandler("OnMouseEnter", function(...) end)
      self.attachmentSlots[i]:SetHandler("OnClicked", function(...) end)
      self.attachmentSlots[i]:SetHandler("OnMouseDoubleClicked", function(...) end)
      self.attachmentSlots[i]:SetMouseOverTexture("/esoui/art/buttons/decline_up.dds")
      self.attachmentSlots[i]:SetMouseOverBlendMode(TEX_BLEND_MODE_ALPHA)
      self.attachmentSlots[i]:SetPressedTexture("/esoui/art/buttons/decline_up.dds")
    else
      self.attachmentSlots[i]:SetHandler("OnMouseEnter", function(...) MailR.defaultMailInboxFn[i][1](...) end)
      self.attachmentSlots[i]:SetHandler("OnClicked", function(...) MailR.defaultMailInboxFn[i][2](...) end)
      self.attachmentSlots[i]:SetHandler("OnMouseDoubleClicked", function(...) MailR.defaultMailInboxFn[i][3](...) end)
      self.attachmentSlots[i]:SetMouseOverTexture("")
      self.attachmentSlots[i]:SetPressedTexture("")
    end
    ZO_Inventory_SetupSlot(self.attachmentSlots[i], stack, icon)
  end

  for i = numAttachments + 1, MailR.MAX_READ_ATTACHMENTS do
    self.attachmentSlots[i]:SetHidden(true)
  end
end

function MailR.RefreshMoneyControls(self)
  local sentMail = MailR.IsMailIdSentMail(self.mailId)
  local mailData

  if sentMail then
    local sentMessage = MailR.GetSentMessageFromMailId(self.mailId)
    mailData = MailR.ConvertSavedMessageToMailData(self.mailId, sentMessage)
  else
    mailData = self:GetMailData(self.mailId)
  end

  self.sentMoneyControl:SetHidden(true)
  self.codControl:SetHidden(true)
  if (mailData.attachedMoney > 0) then
    self.sentMoneyControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.sentMoneyControl, "Currency"), CURT_MONEY,
      mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
  elseif (mailData.codAmount > 0) then
    self.codControl:SetHidden(false)
    ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.codControl, "Currency"), CURT_MONEY, mailData.codAmount,
      MAIL_COD_ATTACHED_MONEY_OPTIONS)
  end
end

function MailR.RefreshAttachmentsHeaderShown(self)
  local numAttachments, attachedMoney
  if MailR.IsMailIdSentMail(self.mailId) then
    numAttachments, attachedMoney = MailR.GetMailAttachmentInfo(self.mailId)
  else
    numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
  end
  local noAttachments = numAttachments == 0 and attachedMoney == 0
  self.attachmentsHeaderControl:SetHidden(noAttachments)
  self.attachmentsDividerControl:SetHidden(noAttachments)
end

function MailR.ConvertSavedMessageToMailData(mailId, message)
  local mailData = {}
  mailData.mailId = mailId
  -- check for nil for old versions of MailR SavedVar
  if message.isSentMail == true or message.isSentMail == nil then
    mailData.subject = MailR.DEFAULT_SENT_MAIL_COLOR_STRING .. message.subject
  else
    mailData.subject = MailR.DEFAULT_SAVE_MAIL_COLOR_STRING .. message.subject
  end
  mailData.formattedSubject = mailData.subject
  mailData.senderDisplayName = message.recipient
  mailData.senderCharacterName = ""
  mailData.expiresInDays = 0
  mailData.expiresText = "MAILR"
  mailData.state = 0
  mailData.unread = false
  local count = 0
  for i = 1, MailR.MAX_ATTACHMENTS do
    if message.attachments[i].stack ~= nil then
      count = count + 1
    end
  end
  mailData.numAttachments = count--message.numAttachments
  if message.cod then
    mailData.codAmount = message.gold
    mailData.attachedMoney = 0
  else
    mailData.attachedMoney = message.gold
    mailData.codAmount = 0
  end
  mailData.secsSinceReceived = GetDiffBetweenTimeStamps(GetTimeStamp(), message.timeSent)
  mailData.receivedText = ZO_FormatDurationAgo(mailData.secsSinceReceived)
  mailData.fromSystem = false
  mailData.fromCS = false
  mailData.priority = 2
  mailData.GetFormattedSubject = function(self) return self.formattedSubject end
  mailData.GetExpiresText = function(self) return self.expiresText end
  mailData.GetReceivedText = function(self) return self.receivedText end
  return mailData
end

function MailR.BuildMasterList(self)
  if MailR.DEBUG then d("Building Master List") end
  self.inboxDirty = false
  self.masterList = {}
  self.numEmptyRows = 0

  if MailR.SavedMail.display == "inbox" or MailR.SavedMail.display == "all" then
    for mailId in MailR.GetNextMailIdIter do
      if not MailR.IsMailIdSentMail(mailId) then
        local mailData = {}
        ZO_MailInboxShared_PopulateMailData(mailData, mailId)
        table.insert(self.masterList, mailData)
      end
    end
  end

  -- add sent mail to masterList
  if MailR.SavedMail.display == "sent" or MailR.SavedMail.display == "all" then
    for mailId, messageInfo in pairs(MailR.SavedMail.sent_messages) do
      if MailR.rtrim(messageInfo["subject"]) == "" then
        messageInfo.subject = "(No Subject)"
      end
      local mailData = MailR.ConvertSavedMessageToMailData(mailId, messageInfo)
      -- table.insert(self.masterList, mailData)
    end
  end

  local listHeight = self.list:GetHeight()
  local currentHeight = #self.masterList * 50
  if (currentHeight < listHeight) then
    self.numEmptyRows = zo_floor((listHeight - currentHeight) / 50)
  end

  GetControl(self.control, "Empty"):SetHidden(#self.masterList > 0)
  GetControl(self.control, "Full"):SetHidden(not IsLocalMailboxFull())
end

function MailR.FilterDisplay(allArgs)
  -- /mailr inbox
  -- /mailr sent
  -- /mailr all
  local args = ""
  local var2 = 0
  local var3 = 0
  local argNum = 0
  for w in string.gmatch(allArgs, "%w+") do
    argNum = argNum + 1
    if argNum == 1 then args = w end
    if argNum == 2 then var2 = tonumber(w) end
    if argNum == 3 then var3 = tonumber(w) end
  end
  args = string.lower(args)

  if not args or args == "help" or args == "" or args == "?" then
    d(colorRavalox .. "[MailR]" .. colorYellow .. " Accepted Commands:")
    d(colorRavalox .. "[MailR]" .. colorCMDBlue .. " /mailr" .. colorSoftYellow .. " << shows help")
    d(colorRavalox .. "[MailR]" .. colorCMDBlue .. " /mailr help" .. colorSoftYellow .. " << shows help")
    d(colorRavalox .. "[MailR]" .. colorCMDBlue .. " /mailer" .. colorSoftYellow .. " << shows MailR settings menu")
    d(colorRavalox .. "[MailR]" .. colorCMDBlue .. " /mailr inbox" .. colorSoftYellow .. " << shows only saved messages")
    d(colorRavalox .. "[MailR]" .. colorCMDBlue .. " /mailr sent" .. colorSoftYellow .. " << shows only sent messages")
    d(colorRavalox .. "[MailR]" .. colorCMDBlue .. " /mailr all" .. colorSoftYellow .. " << shows all messages")
  end
  if args == "inbox" then
    MailR.SavedMail.display = "inbox"
  elseif args == "sent" then
    MailR.SavedMail.display = "sent"
  elseif args == "all" then
    MailR.SavedMail.display = "all"
  else
    d("Unrecognized mailr option. Use inbox, sent, or all.")
    return
  end
  MAIL_INBOX:RefreshData()
end

function MailR.ConvertSavedMail()
  -- version 1.0 to 2.0
  if MailR.SavedMail.messages ~= nil then
    MailR.SavedMail.inbox_messages = {}
    MailR.SavedMail.inbox_count = 0
    MailR.SavedMail.sent_messages = {}
    for k, v in pairs(MailR.SavedMail.messages) do
      MailR.SavedMail.sent_messages[k] = v
    end
    MailR.SavedMail.sent_count = #MailR.SavedMail.sent_messages
    MailR.SavedMail.messages = nil
    MailR.SavedMail.count = nil
    MailR.SavedMail.mailr_version = MailR.SAVED_MAIL_VERSION
  end
end

-- do all this when the addon is loaded
function MailR.Init(eventCode, addOnName)
  if addOnName ~= "MailR" then return end

  -- Event Registration
  EVENT_MANAGER:RegisterForEvent("MailR_InboxMessageSelected", EVENT_MAIL_READABLE, MailR.InboxMessageSelected)
  EVENT_MANAGER:RegisterForEvent("MailR_SetMailboxActive", EVENT_MAIL_OPEN_MAILBOX, MailR.SetMailboxActive)
  EVENT_MANAGER:RegisterForEvent("MailR_SetMailboxInactive", EVENT_MAIL_CLOSE_MAILBOX, MailR.SetMailboxInactive)
  EVENT_MANAGER:RegisterForEvent("MailR_UpdateKeybindInfo", EVENT_KEYBINDING_SET, MailR.UpdateKeybindInfo)
  EVENT_MANAGER:RegisterForEvent("MailR_MailSentSuccessfully", EVENT_MAIL_SEND_SUCCESS, MailR.MailSentSuccessfully)
  -- EVENT_MANAGER:RegisterForEvent("MailR_GuildMailSentSuccessfully", EVENT_MAIL_SEND_SUCCESS, MailR.GuildMailSent)
  -- EVENT_MANAGER:RegisterForEvent("MailR_GuildMailSentUnsuccessfully", EVENT_MAIL_SEND_FAILED, MailR.GuildMailFailSent)
  EVENT_MANAGER:RegisterForEvent("MailR_AttachmentAdded", EVENT_MAIL_ATTACHMENT_ADDED, MailR.AttachmentAdded)
  EVENT_MANAGER:RegisterForEvent("MailR_AttachmentRemoved", EVENT_MAIL_ATTACHMENT_REMOVED, MailR.AttachmentRemoved)
  EVENT_MANAGER:RegisterForEvent("MailR_CODChanged", EVENT_MAIL_COD_CHANGED, MailR.CODChanged)
  EVENT_MANAGER:RegisterForEvent("MailR_AttachmentMoneyChanged", EVENT_MAIL_ATTACHED_MONEY_CHANGED, MailR.AttachmentMoneyChanged)

  SLASH_COMMANDS["/mailr"] = MailR.FilterDisplay

  MailR.mailboxActive = false
  MailR.ClearCurrentSendMessage()
  MailR.SavedMail = ZO_SavedVars:New("SV_MailR_SavedMail", 1, nil, MailR.SavedMail_defaults)
  MailR.SavedMail.guildMailVisible = false
  if MailR.SavedMail.display == nil then
    MailR.SavedMail.display = "all"
  end
  -- we have to do this because if we tell ZO_SavedVars our version changed it will delete everything
  -- check for messags as well as version because of version 1.0 conflict with ZOS
  if MailR.SavedMail.messages ~= nil or MailR.SavedMail.mailr_version ~= MailR.SAVED_MAIL_VERSION then
    MailR.ConvertSavedMail()
  end
  math.randomseed(GetTimeStamp())

  local replySettingStr = MailR.localeStringMap[MailR.effective_lang]["Reply To Message"]
  local forwardSettingStr = MailR.localeStringMap[MailR.effective_lang]["Forward Message"]
  local mailSaveStr = MailR.localeStringMap[MailR.effective_lang]["Save Mail"]
  ZO_CreateStringId("SI_BINDING_NAME_MAIL_REPLY", replySettingStr)
  ZO_CreateStringId("SI_BINDING_NAME_MAIL_FORWARD", forwardSettingStr)
  ZO_CreateStringId("SI_BINDING_NAME_MAIL_SAVE", mailSaveStr)

  local originalSendToHandler = ZO_MailSendToField:GetHandler("OnTextChanged")
  ZO_MailSendToField:SetHandler("OnTextChanged", function(...)
    originalSendToHandler(...)
    MailR.UpdateSendTo()
  end)
  local originalSubjectHandler = ZO_MailSendSubjectField:GetHandler("OnTextChanged")
  if originalSubjectHandler then
    ZO_MailSendSubjectField:SetHandler("OnTextChanged", function(...)
      originalSubjectHandler(...)
      MailR.UpdateSendSubject()
    end)
  else
    ZO_MailSendSubjectField:SetHandler("OnTextChanged", function(...) MailR.UpdateSendSubject() end)
  end
  ZO_MailSendBodyField:SetHandler("OnTextChanged", function(...) MailR.UpdateSendBody() end)

  MailR.OverloadMailInbox()
  MailR.OverloadMailSend()
  MailR.UpdateKeybindInfo()
  MailR.GuildThrottleTimer = ZO_TimerBar:New(ThrottleTimer)
end
EVENT_MANAGER:RegisterForEvent("MailR_Init", EVENT_ADD_ON_LOADED, MailR.Init)