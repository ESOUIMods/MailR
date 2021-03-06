--[[
Title: MailR
Description: MailR is a supplemental addon for the ESO in-game mail system.
Version: 2.4.0.0
Date: 2018-05-17 Calia1120
]]

local LAM2 = LibAddonMenu2
-- GLOBALS
MailR = {}
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
MailR.DEFAULT_DONATION = 1000
MailR.DonateButton = nil
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
	guildMailVisible = true,
	mailr_version = MailR.SAVED_MAIL_VERSION,
	sent_count = 0,
	sent_messages = {},
	inbox_count = 0,
	inbox_messages = {},
	show_donation = true,
	throttle_time = 1 --seconds (can be fractional)
}
-- saved mail
MailR.SavedMail = nil
-- Locale vars --
-- translation map from EN -> (DE, FR)
MailR.localeStringMap = {
	["EN"] = {
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
	["DE"] = {
		["Reply"] = "Antworten",
		["Forward"] = "Vorw??rts",
		["Reply To Message"] = "Antwort auf Beitrag",
		["Forward Message"] = "Nachricht weiterleiten",
		["Original Message"] = "Urspr??ngliche Nachricht",
		["Save Mail"] = "Save Mail",
		["From: "] = "Von: ",
		["Fwd: "] = "WG: ",
		["Re: "] = "AW: ",
		["Attachments: "] = "Anh??nge: ",
		["To:"] = "An:",
		["Received:"] = "Erhalten am:",
		["Sent:"] = "Gesendet:",
		["Attached Gold: "] = "Angeh??ngte Gold: ",
		["COD: "] = "COD: ",
		["Postage: "] = "Porto: "
	},
	["FR"] = {
		["Reply"] = "R??pondre",
		["Forward"] = "Transf??rer",
		["Reply To Message"] = "R??pondre au Message",
		["Forward Message"] = "Transf??rer le Message",
		["Original Message: "] = "Message Original: ",
		["Save Mail"] = "Save Mail",
		["From: "] = "Von: ",
		["Fwd: "] = "Tr: ",
		["Re: "] = "Re: ",
		["Attachments: "] = "Pi??ces jointes: ",
		["To:"] = "A:",
		["Received:"] = "Re??us:",
		["Sent:"] = "Envoy??:",
		["Attached Gold: "] = "Or Attach??: ",
		["COD: "] = "COD: ",
		["Postage: "] = "Affranchissement: "
	},
	["RU"] = {
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
}
local colorYellow 		= "|cFFFF00" 	-- yellow
local colorSoftYellow	= "|cCCCC00"    -- Duller Yellow for Description
local colorRed 			= "|cFF0000" 	-- Red
local colorRavalox		= "|cB60000"    -- Ravalox Red  -- B6 = Red 182  a brighter 82 red
local colorCMDBlue		= "|c1155bb"    -- Dull blue used to indicate "typable" text
local lang
local ShowPlayerContextMenu_Orig = CHAT_SYSTEM.ShowPlayerContextMenu
local GetNextMailId_Orig = GetNextMailId
local ShowPlayerInteractMenu_Orig = ZO_PlayerToPlayer.ShowPlayerInteractMenu

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

	ZO_MainMenuSceneGroupBarButton2.m_object.m_buttonData:callback()
	ZO_MailSendToField:SetText(MailR.currentMessageInfo["displayName"])
	local reStr = MailR.localeStringMap[lang]["Re: "]
	local replyString = MailR.currentMessageInfo["subject"]:gsub("^"..reStr,"")
	ZO_MailSendSubjectField:SetText(reStr..replyString)
	ZO_MailSendBodyField:TakeFocus()
end

-- When Forward Button Clicked or Key Pressed
function MailR.CreateForward()
	-- make sure we only try to create/show a reply when the mailInbox is active
	if not MailR.mailboxActive then return end
	if SCENE_MANAGER.currentScene.name ~= "mailInbox" then return end
	if MailR.currentMessageInfo["numAttachments"] == nil or MailR.currentMessageInfo["isSentMail"] == nil then return end
	if MailR.currentMessageInfo["numAttachments"] > 0 and not MailR.currentMessageInfo["isSentMail"] then return end
	local openMailId = MAIL_INBOX:GetOpenMailId()
	if not MAIL_INBOX:GetMailData(openMailId) then return end

	MailR.dm("Debug", "Creating Forward")

	ZO_MainMenuSceneGroupBarButton2.m_object.m_buttonData:callback()
	local fwdStr = MailR.localeStringMap[lang]["Fwd: "]
	local replyString = MailR.currentMessageInfo["subject"]:gsub("^"..fwdStr,"")
	ZO_MailSendSubjectField:SetText(fwdStr..replyString)
	local origStr = MailR.localeStringMap[lang]["Original Message"]
	local bodyStr = "\n***"..MailR.DEFAULT_HEADER_COLOR_STRING..origStr..MailR.RESET_COLOR_STRING.."***\n"
	local senderStr = MailR.currentMessageInfo["displayName"]
	if not MailR.currentMessageInfo["characterName"] == "" and not MailR.currentMessageInfo["characterName"] == nil then
		senderStr = MailR.currentMessageInfo["characterName"].."("..senderStr..")"
	end
	bodyStr = bodyStr..MailR.DEFAULT_HEADER_COLOR_STRING..MailR.localeStringMap[lang]["From: "]..MailR.RESET_COLOR_STRING..senderStr.."\n"
	bodyStr = bodyStr.."\n"..MailR.currentMessageInfo["body"].."\n"
	bodyStr = bodyStr.."***"..MailR.DEFAULT_HEADER_COLOR_STRING.."/"..MailR.localeStringMap[lang]["Original Message"]..MailR.RESET_COLOR_STRING.."***\n"
	ZO_MailSendBodyField:SetText(bodyStr)
	ZO_MailSendBodyField:TakeFocus()

end

-- Handles when a message in the inbox is selected
function MailR.InboxMessageSelected(eventCode, mailId)
  local senderDisplayName, senderCharacterName, subject, icon, unread,
  fromSystem, fromCustomerService, returned, numAttachments, attachedMoney,
  codAmount, expiresInDays, secsSinceReceived  = GetMailItemInfo(mailId)

  MailR.currentMessageInfo["isSentMail"] = MailR.IsMailIdSentMail(mailId)
	MailR.currentMessageInfo["displayName"] = senderDisplayName
	MailR.currentMessageInfo["recipient"] = senderDisplayName
	MailR.currentMessageInfo["characterName"] = senderCharacterName
	MailR.currentMessageInfo["subject"] = subject
	MailR.currentMessageInfo["body"] = ZO_MailInboxMessageBody:GetText()
	MailR.currentMessageInfo["numAttachments"] = numAttachments
	MailR.currentMessageInfo["secsSinceReceived"] = secsSinceReceived
	MailR.currentMessageInfo["timeSent"] = GetDiffBetweenTimeStamps(GetTimeStamp() - secsSinceReceived)
	MailR.currentMessageInfo["attachments"] = {}
	MailR.currentMessageInfo["gold"] = 0
	MailR.currentMessageInfo["cod"] = false
	MailR.currentMessageInfo["postage"] = 0
  MailR.currentMessageInfo["mailId"] = mailId
	for a=1,MailR.MAX_ATTACHMENTS do
		table.insert(MailR.currentMessageInfo["attachments"], {})
	end
	-- we dont do anything with this information yet
	if not MailR.IsMailIdSentMail(mailId) then
		for a=1,numAttachments do
			local textureName, stack, creatorName = GetAttachedItemInfo(mailId, a)
			local link = GetAttachedItemLink(mailId, a, LINK_STYLE_DEFAULT)
			MailR.currentMessageInfo["attachments"][a].textureName = textureName
			MailR.currentMessageInfo["attachments"][a].stack = stack
			MailR.currentMessageInfo["attachments"][a].creatorName = creatorName
			MailR.currentMessageInfo["attachments"][a].link = link
		end
	end
	-- shoud we include the body of the original message? Is there a message limit?

	-- this doesnt seem to return what I expect so use whats below
	--if IsMailReturnable(mailId) then
	-- some messages you cant reply to (e.g. system messages)
	if senderDisplayName == nil or senderDisplayName == ""  or fromSystem or MailR.IsMailIdSentMail(mailId) then
		MailR.currentMessageInfo["returnable"] = false
	else
		MailR.currentMessageInfo["returnable"] = true
	end
end

-- Mail UI opened
function MailR.SetMailboxActive(eventCode)
  MailR.dm("Debug", "Mailbox Active")
	MailR.mailboxActive = true
	if SCENE_MANAGER.currentScene.name == 'mailSend' then return end
	-- overload the event handler for mailbox buttons so we can maintain proper
	-- visibilty of our buttons on the KeybindStrip control
	-- only reset the handlers once! Also they dont exist until mailbox is opened for the first time
	-- probably not needed anymore
	if MailR.setHandlersOnFirstLoad then
		-- need to do this because objects not created if mailsend is first menu loaded
		-- this can happen if someone right clicks chat to send message before opening mailbox first
		MailR.setHandlersOnFirstLoad = false
		local handlerFunc = ZO_MainMenuSceneGroupBarButton1:GetHandler("OnMouseUp")
		ZO_MainMenuSceneGroupBarButton1:SetHandler("OnMouseUp", function(...) MailR.HideGuildies() handlerFunc(...) end)
	end
	if MailR.SavedMail.show_donation then
		if MasterMerchantMailButton ~= nil then
			MailR.DonateButton:SetAnchor(TOPLEFT, MasterMerchantMailButton, BOTTOMLEFT, 0, 4)
		else
			MailR.DonateButton:SetAnchor(TOPLEFT, ZO_MailInbox, TOPLEFT, 100, 4)
		end
		MailR.DonateButton:SetHidden(false)
	else
		MailR.DonateButton:SetHidden(true)
	end
end

-- Mail UI closed
function MailR.SetMailboxInactive(eventCode)
  MailR.dm("Debug", "Mailbox Inactive")
	MailR.mailboxActive = false
	MailR.HideGuildies()
	local k, v = next(MailR.GuildRecipients)
	if k ~= nil then
		MailR.GuildMailCancel()
	end
end

function MailR.HideGuildies()
	Guildies:SetHidden(true)
	MailR.guildies_visible = false
	-- MailR.GuildDropdown:ClearItems()
	-- MailR.GuildRankDropdown:ClearItems()
	-- MailR.GuildStatusDropdown:ClearItems()
	-- MailR.GuildLogicDropdown:ClearItems()
	MailR.guilds = {}
	MailR.guildranks = {}
	MailR.guildies = {}
end

function MailR.GuildMailCancel()
	MailR.CancelGuildMail = true
	SendProgressLabel:SetText("Canceling...")
	SendProgressButton:SetEnabled(false)
	--MailR.FinishedGuildMail()
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
			if MailR.CancelGuildMail then MailR.FinishedGuildMail() return end
			if k ~= nil then MailR.SendGuildMailMessage(k) end
		else
			if MailR.CancelGuildMail then MailR.FinishedGuildMail() return end
			SendProgressLabel:SetText(SendProgressLabel:GetText().."...Waiting For ZOS")
		end
	end
end

function MailR.GuildItemSelect(_, guildName, choiceNumber)
	MailR.dm("Debug", guildName)
	MailR.dm("Debug", choiceNumber)
	MailR.dm("Debug", MailR.guilds[guildName])
	MailR.guildies = {}
	MailR.guildRanks = {}
	MailR.GuildRankDropdown:ClearItems()
	MailR.GuildStatusDropdown:ClearItems()
	MailR.GuildLogicDropdown:ClearItems()
	MailR.CurrentKnownGuild = {guildName, choiceNumber}
	local guildId = MailR.guilds[guildName]
	local numGuildies = GetNumGuildMembers(guildId)
	local entry
	for i=1,numGuildies do
		local name, note, rankIndex, status, logoff = GetGuildMemberInfo(guildId, i)
		local rankName = GetFinalGuildRankName(guildId, rankIndex)
		local hasChar, charName, zoneName, classType, alliance, level, vr = GetGuildMemberCharacterInfo(guildId, i)
		if status == PLAYER_STATUS_OFFLINE then status = false else status = true end
		local data = {charName=charName:gsub("%^.*x$",""), rankName=rankName, status=status, recipient=true}
		MailR.guildies[name] = data
	end
	local numGuildRanks = GetNumGuildRanks(guildId)
	for i=1,numGuildRanks do
		local rankName = GetFinalGuildRankName(guildId, i)
		MailR.guildranks[rankName] = i
		entry = MailR.GuildRankDropdown:CreateItemEntry(rankName, MailR.GuildRankItemSelect)  --this really just creates a table with {name = choices[i], callback = OnItemSelect} - you may be able to skip this step and just pass the correctly formatted table into the below function...
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
		if not (v["status"] == status or statusText=="All")  then recipient = false end
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
		if not (v["status"] == status or statusText=="All")  then recipient = false end
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
		if not (v["status"] == status or statusText=="All")  then recipient = false end
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
end

-- Get Keybind Layer Index by Layer Name
function MailR.GetKeybindLayerIndex(layerName)
	local layers = GetNumActionLayers()
	for layer=1,layers do
		if GetActionLayerInfo(layer) == layerName then return layer end
	end

	return 0
end

-- Get keybind category index by name
function MailR.GetKeybindCategoryIndex(layerIndex, categoryName)
	local layerName, numCategories = GetActionLayerInfo(layerIndex)
	for category=1,numCategories do
		if GetActionLayerCategoryInfo(layerIndex, category) == categoryName then return category end
	end

	return 0
end

-- get keybind action index by name
function MailR.GetKeybindActionIndex(layerIndex, categoryIndex, actionName)
	local categoryName, numActions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
	for action=1,numActions do
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
	return {keyCode, keyName}
end

-- somebody updated their keybinds so we should probably update too
function MailR.UpdateKeybindInfo(eventCode)
	local replyKeybind = MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR", "MAIL_REPLY")
	local forwardKeybind = MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR", "MAIL_FORWARD")
	MailR.keybindInfo["REPLY"] = replyKeybind
	MailR.keybindInfo["FORWARD"] = forwardKeybind
end

-- called when text in recipient field of composed message is updated
function MailR.UpdateSendTo()
  MailR.dm("Verbose", "recipient updated")
	MailR.currentSendMessageInfo["recipient"] = ZO_MailSendToField:GetText()
end

-- called when text in subject field of composed message is updated
function MailR.UpdateSendSubject()
  MailR.dm("Verbose", "subject updated")
	MailR.currentSendMessageInfo["subject"] = ZO_MailSendSubjectField:GetText()
end

-- called when text in body field of composed message is updated
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

function MailR.MailSentSuccessfully()
  MailR.dm("Debug", "mail sent")
	if next(MailR.queuedSentMessage) == nil then return end
	if next(MailR.GuildRecipients) ~= nil then return end
	MailR.queuedSentMessage["timeSent"] = GetTimeStamp()
	if MailR.rtrim(MailR.queuedSentMessage["subject"]) == "" then
		MailR.queuedSentMessage["subject"] = "(No Subject)"
	end
	MailR.queuedSentMessage["isSentMail"] = true
  MailR.dm("Debug", MailR.queuedSentMessage)
	local mailId = MailR.GenerateMailId()
	while MailR.SavedMail.sent_messages["MailR_"..tostring(mailId)] ~= nil do
		mailId = MailR.GenerateMailId()
	end
	MailR.SavedMail.sent_messages["MailR_"..tostring(mailId)] = MailR.CopyMessage(MailR.queuedSentMessage)
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
	for a=1,MailR.MAX_ATTACHMENTS do
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
	copyMessage["returnable"] = messageToCopy["returnable"]
	copyMessage["attachments"] = {}
	for a=1,MailR.MAX_ATTACHMENTS do
		table.insert(copyMessage["attachments"],messageToCopy["attachments"][a])
	end
	return copyMessage
end

-- called when attachments are added to composed mail
function MailR.AttachmentAdded(eventCode, slot)
	MailR.dm("Debug", "attachment")
	local attachment = ZO_MailSendAttachments:GetChild(slot)
	local bagid = attachment.bagId
	local slotid = attachment.slotIndex
	local stack = attachment.stackCount
	local link = GetItemLink(bagid, slotid, LINK_STYLE_DEFAULT)
	local icon = GetItemLinkInfo(link)
	MailR.currentSendMessageInfo["attachments"][slot] = {["stack"]=stack, ["link"]=link, ["icon"]=icon}
	MailR.currentSendMessageInfo["postage"] = GetQueuedMailPostage()
end

-- called when attachments are removed from composed mail
function MailR.AttachmentRemoved(eventCode, slot)
	MailR.dm("Debug", "removing attachment")
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

function MailR.GuildMailSent()
  MailR.dm("Debug", "Guild Mail Sent")
	MailR.WaitingForResponse = false
	local k, v = next(MailR.GuildRecipients)
	if k == nil or MailR.CancelGuildMail then MailR.FinishedGuildMail() return end
	MailR.guildies[MailR.LastKnownRecipient.name].recipient = false
	MailR.RecipientCount = MailR.RecipientCount + 1
	SendProgressStatus:SetValue(MailR.RecipientCount)
	SendProgressLabel:SetText("Sent "..tostring(MailR.RecipientCount).."/"..tostring(MailR.GuildRecipientCount))
	if not MailR.GuildThrottleTimer:IsStarted() then
		MailR.SendGuildMailMessage(k)
	end
end

function MailR.GuildMailFailSent()
  MailR.dm("Debug", "Mail Failed To Send To")
  MailR.dm("Debug", MailR.LastKnownRecipient)
	MailR.WaitingForResponse = false
	local k, v = next(MailR.GuildRecipients)
	if k == nil or MailR.CancelGuildMail then MailR.FinishedGuildMail() return end
	MailR.RecipientCount = MailR.RecipientCount + 1
	SendProgressStatus:SetValue(MailR.RecipientCount)
	SendProgressLabel:SetText("Sent "..tostring(MailR.RecipientCount).."/"..tostring(MailR.GuildRecipientCount))
	if not MailR.GuildThrottleTimer:IsStarted() then
		MailR.SendGuildMailMessage(k)
	end
end

function MailR.FinishedGuildMail()
  MailR.dm("Debug", "Guild Mail Finished")
	MAIL_SEND:ClearFields()
	QueueMoneyAttachment(0) -- just to make sure
	MailR.GuildThrottleTimer:Stop()
	--MailR.HideGuildies()
	SendProgress:SetHidden(true)

	local k, v = next(MailR.GuildRecipients)
	MailR.GuildRecipients = {}
	if MailR.CancelGuildMail and k ~= nil then
		toStr = MailR.queuedSentMessage["recipient"]:gsub(" %([0-9]*%)","")
		toStr = toStr.." ("..tostring(MailR.RecipientCount).."/"..tostring(MailR.GuildRecipientCount)..")"
		MailR.queuedSentMessage["recipient"] = toStr
		MailR.MailSentSuccessfully()
	end
	MailR.GuildMailRecipientsReady = false
	MailR.GuildRecipientCount = 0
	MailR.RecipientCount = 0
	MailR.ThrottledRecipients = 0
end

function MailR.SendGuildMailMessage(recipient)
  MailR.dm("Debug", "Sending GM To "..recipient)
	local body = MailR.queuedSentMessage["body"]
	local subject = MailR.queuedSentMessage["subject"]
	MailR.WaitingForResponse = true
	MailR.LastKnownRecipient = MailR.GuildRecipients[recipient]
	SendMail(recipient, subject, body)
	MailR.GuildRecipients[recipient] = nil
	MailR.ThrottledRecipients = MailR.ThrottledRecipients + 1
	if MailR.ThrottledRecipients >= MailR.ThrottleRecipients then
		MailR.ThrottledRecipients = 0
		MailR.GuildThrottleTimer:Start(GetFrameTimeSeconds(), GetFrameTimeSeconds()+MailR.SavedMail.throttle_time+1)
	end
end

-- when SendMail is called do this first, otherwise currentSendMessageInfo gets cleared (by ZOS)
function MailR.QueueSentMessage()
	MailR.dm("Debug", "queuing message")
	MailR.queuedSentMessage = {}
	MailR.queuedSentMessage = MailR.CopyMessage(MailR.currentSendMessageInfo)
    --[[
	if MailR.guildies_visible then
		MailR.queuedSentMessage["gold"] = 0
		MailR.queuedSentMessage["cod"] = false
		MailR.queuedSentMessage["postage"] = 0
		MailR.queuedSentMessage["attachments"] = {}
		for a=1,MailR.MAX_ATTACHMENTS do
			table.insert(MailR.queuedSentMessage["attachments"], {})
		end
	end
    ]]--
end

function MailR.Row_OnMouseUp(control, button, upInside)
  MailR.dm("Debug", "OnMouseUp")
  ZO_TreeEntry_OnMouseUp(control, upInside)
  if not control then return end
  MailR.a_temp = control
  --[[
	local mailId = control.dataEntry.data.mailId

	if MailR.IsMailIdSentMail(mailId) then
		return
	end
	if button == 2 then
		ClearMenu()
		AddMenuItem("Save Message", MailR.SaveMail)
		ShowMenu()
	end
  ]]--
end

function MailR.SaveMail()
  MailR.dm("Debug", "SaveMail")
	local mail = MailR.currentMessageInfo
	mail.isSentMail = false
	MailR.SavedMail.sent_messages["MailR_"..Id64ToString(mail.mailId)] = MailR.CopyMessage(MailR.currentMessageInfo)
	MailR.SavedMail.sent_count = MailR.SavedMail.sent_count + 1
	MAIL_INBOX:RefreshData()
end

function MailR.ShowPlayerContextMenu(self, playerName, rawName)
	ShowPlayerContextMenu_Orig(self, playerName, rawName)
	AddMenuItem('Send Mail', function() SCENE_MANAGER:Show('mailSend') ZO_MailSendToField:SetText(playerName) end)
	ShowMenu()
end

function MailR.ShowPlayerInteractMenu(self, isIgnored)
	local api_ver = GetAPIVersion()
	if  api_ver == 100011 then
		local currentTarget = self.currentTarget
		self.menu:AddEntry("Send Mail", "EsoUI/Art/Mail/mail_tabicon_compose_up.dds", "EsoUI/Art/Mail/mail_tabicon_compose_up.dds", function() SCENE_MANAGER:Show('mailSend') ZO_MailSendToField:SetText(currentTarget) end)
		ShowPlayerInteractMenu_Orig(self, isIgnored)
	elseif api_ver > 100011 then

		local currentTarget = self.currentTargetCharacterName
		local icons =
	    {
	        enabledNormal = "EsoUI/Art/Mail/mail_tabicon_compose_up.dds",
	        enabledSelected = "EsoUI/Art/Mail/mail_tabicon_compose_down.dds",
	        disabledNormal = "EsoUI/Art/Mail/mail_tabicon_compose_up.dds",
	        disabledSelected = "EsoUI/Art/Mail/mail_tabicon_compose_down.dds",
	    }
		self:AddMenuEntry("Send Mail", icons, isIgnored, function() SCENE_MANAGER:Show('mailSend') ZO_MailSendToField:SetText(currentTarget) end)
		ShowPlayerInteractMenu_Orig(self, isIgnored)
	end
end

function MailR.CheckMailIdEquality(mailId1, mailId2)
	return mailId1 == mailId2
end

function MailR.MailIdEquality(...)
  MailR.dm("Debug", "MailIdEquality")
  MailR.dm("Debug", self)
  MailR.dm("Debug", ...)
	-- return MailR.CheckMailIdEquality(data1.mailId, data2.mailId)
	return true
end

function MailR.GetMailData(self, mailId)
	if self.masterList then
		for i = 1, #self.masterList do
			local data = self.masterList[i]
            -- if data.mailId == mailId then
			if AreId64sEqual(data.mailId, mailId) then
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
  local originalGetMailItemInfo = GetMailItemInfo
  GetMailItemInfo = function(mailId)
                       if MailR.IsMailIdSentMail(mailId) then
                         return MailR.GetMailItemInfo(mailId)
                       else
                         return originalGetMailItemInfo(mailId)
                       end
                     end
  local originalIsMailReturnable = IsMailReturnable
  IsMailReturnable = function(mailId)
                       if MailR.IsMailIdSentMail(mailId) then
                         return false
                       else
                         return originalIsMailReturnable(mailId)
                       end
                     end
    --[[ removed because it is not a ScrollList now
	MAIL_INBOX.BuildMasterList = MailR.BuildMasterList
	MAIL_INBOX.OnSelectionChanged = MailR.OnSelectionChanged
	MAIL_INBOX.IsMailReturnable = IsMailReturnable -- redefined above
	MAIL_INBOX.GetMailData = MailR.GetMailData -- Is same as current code
	MAIL_INBOX.GetMailItemInfo = GetMailItemInfo
	GetMailItemInfo = MailR.GetMailItemInfo
    ]]--
	MAIL_INBOX.OnMailReadable = MailR.OnMailReadable
	MAIL_INBOX.RefreshAttachmentSlots = MailR.RefreshAttachmentSlots
	MAIL_INBOX.RefreshMoneyControls = MailR.RefreshMoneyControls
	MAIL_INBOX.RefreshAttachmentsHeaderShown = MailR.RefreshAttachmentsHeaderShown
	MAIL_INBOX.IsMailDeletable = MailR.IsMailDeletable
	MAIL_INBOX.Delete = MailR.Delete
	MAIL_INBOX.ConfirmDelete = MailR.ConfirmDelete
	MAIL_INBOX.RequestReadMessage = MailR.RequestReadMessage
	MAIL_INBOX.HasAlreadyReportedSelectedMail = MailR.HasAlreadyReportedSelectedMail
	local MAIL_DATA = 1
	GetNextMailId = MailR.GetNextMailId
	CHAT_SYSTEM.ShowPlayerContextMenu = MailR.ShowPlayerContextMenu
	for i=1,MailR.MAX_READ_ATTACHMENTS do
		table.insert(MailR.defaultMailInboxFn, {MAIL_INBOX.attachmentSlots[i]:GetHandler("OnMouseEnter"),MAIL_INBOX.attachmentSlots[i]:GetHandler("OnClicked"), MAIL_INBOX.attachmentSlots[i]:GetHandler("OnMouseDoubleClicked")})
	end

	-- overload keybinds...I think I have effectively rewritten ESO Mail at this point
	-- instead of adding on :/
	MAIL_INBOX.InitializeKeybindDescriptors = MailR.InitializeKeybindDescriptors
	MAIL_INBOX:InitializeKeybindDescriptors()
end

function MailR.MailGuild()
  MailR.dm("Debug", "MailGuild")
	if not MailR.SavedMail.guildMailVisible then return end
	if not SCENE_MANAGER:IsShowing("mailSend") then return end
end

function MailR.OverloadMailSend()
	local initKB = MAIL_SEND.InitializeKeybindDescriptors
	local guildKB = {
				name = MailR.localeStringMap[lang]["Save Mail"],
				keybind = "MAIL_GUILD",

				callback = function()
					MailR.MailGuild()
				end,

				visible = function() return MailR.SavedMail.guildMailVisible end
			}
	MAIL_SEND.InitializeKeybindDescriptors = function(self)

		local sendName = GetString(SI_MAIL_SEND_SEND)
		for k,v in pairs(MAIL_SEND.staticKeybindStripDescriptor) do
			if type(v)=="table" and v.name == sendName then
				v.callback = function()
					if not MailR.guildies_visible then
						MailR.QueueSentMessage()
						self:Send()
					else
						if MailR.GuildMailRecipientsReady then
							MailR.QueueSentMessage()
							MailR.SendGuildMail()
						end
					end
				end
			end
		end
		--[[
		self.staticKeybindStripDescriptor =
		{
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
					if not MailR.guildies_visible then
						MailR.QueueSentMessage()
						self:Send()
					else
						if MailR.GuildMailRecipientsReady then
							MailR.QueueSentMessage()
							MailR.SendGuildMail()
						end
					end
				end,
			},
		} --]]
	end
	MAIL_SEND:InitializeKeybindDescriptors()
  --[[
	table.insert(MAIL_SEND.staticKeybindStripDescriptor, guildKB)

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
  ]]--
end

function MailR.InitializeKeybindDescriptors(self)

	local function ReportAndDeleteCallback()
 		self:RecordSelectedMailAsReported()
		self:Delete()
	end

	self.selectionKeybindStripDescriptor =
	{
		alignment = KEYBIND_STRIP_ALIGN_CENTER,

		--Return
		{
			name = GetString(SI_MAIL_READ_RETURN),
			keybind = "UI_SHORTCUT_SECONDARY",

			callback = function()
				self:Return()
			end,

			visible = function()
				if MailR.IsMailIdSentMail(self.mailId) then
					return false
				elseif(self.mailId) then
					return IsMailReturnable(self.mailId)
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
				if MailR.IsMailIdSentMail(self.mailId) then
					return true
				elseif(self.mailId) then
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
				if MailR.IsMailIdSentMail(self.mailId) then
					return false
				elseif(self.mailId) then
					local numAttachments, attachedMoney, codAmount = GetMailAttachmentInfo(self.mailId)
					if(numAttachments > 0 or attachedMoney > 0) then
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
					if MailR.IsMailIdSentMail(self.mailId) or self.mailId == nil then
						return false
					end
                    local mailData = self:GetMailData(self.mailId)
                    return mailData and mailData.isFromPlayer
                end
            end,

            callback = function()
                if(self.mailId) then
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
			name = MailR.localeStringMap[lang]["Forward"],
			keybind =  "MAIL_FORWARD", --MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR", "MAIL_FORWARD")[2],

			visible = function()
				if MailR.IsMailIdSentMail(self.mailId) then
					return true
				end
				if(self.mailId) then
					return not IsMailReturnable(self.mailId)
				end
			end,

			callback = function()
				if(self.mailId) then
					MailR.CreateForward()
				end
			end,
		},

		--Reply Mail
		{
			name = MailR.localeStringMap[lang]["Reply"],
			keybind = "MAIL_REPLY",

			visible = function()
				if self.mailId == nil then return end
				if MailR.IsMailIdSentMail(self.mailId) then
					local isSentMail = MailR.SavedMail.sent_messages[self.mailId]["isSentMail"]
					local isReturnable = MailR.SavedMail.sent_messages[self.mailId]["returnable"]
					if isSentMail == nil or isSentMail == true then
						return false
					else
						return isReturnable
					end
				end
				local mailData = self:GetMailData(self.mailId)
				if(mailData) then
					return not (mailData.fromCS or mailData.fromSystem)
				end
			end,

			callback = function()
				if(self.mailId) then
					MailR.CreateReply()
				end
			end,
		},

    --Save Mail
    {
      name = MailR.localeStringMap[lang]["Save Mail"],
      keybind =  "MAIL_SAVE", --MailR.GetPrimaryKeybindInfo(GetString(SI_KEYBINDINGS_LAYER_GENERAL), "MailR", "MAIL_FORWARD")[2],

      visible = function()
        if self.mailId == nil then return false end
        if not MailR.SavedMail.sent_messages["MailR_"..Id64ToString(self.mailId)] then
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
  MailR.dm("Debug", "MailR.Delete")
  MailR.dm("Debug", self.mailId)
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
      else --no confirmation popup, immediately delete
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
	if(mailData) then
		return mailData.attachedMoney == 0 and mailData.numAttachments == 0
	end
end

function MailR.GetMailItemInfo(mailId)
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
  for i=1,MailR.MAX_ATTACHMENTS do
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
	if type(self.mailId) == "string" or not AreId64sEqual(self.mailId, mailId) then -- hack for deleted MAILR messages
		RequestReadMail(mailId)
		return
	end
end

function MailR.OnSelectionChanged(self, previouslySelected, selected, reselectingDuringRebuild)
	ZO_SortFilterList.OnSelectionChanged(self, previouslySelected, selected)
	if(not reselectingDuringRebuild) then
		if selected and MailR.IsMailIdSentMail(selected.mailId) then
			MailR.OnMailReadable(self, selected.mailId)
			MailR.InboxMessageSelected(nil, selected.mailId)
		elseif(selected) then
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

	if not MailR.IsMailIdSentMail(mailId) then --valid mailId or nil to get first message
		nextMailId = GetNextMailId_Orig(mailId)
	end

	if nextMailId == nil then --custom mailId or no next mail in the inbox, try to get next Id from saved mail
		nextMailId = next(MailR.SavedMail.sent_messages, mailId)
	end

	return nextMailId
end

function MailR.IsMailRMail(mailId)
  --[[ don't check for an Id64 because there seems to not
  be one when you send mail to a player.
  ]]--
  --if type(mailId) ~= "number" then mailId = Id64ToString(mailId) end
	--if type(mailId) ~= "string" then return false end
	if mailId == nil then return false end
  if type(mailId) == "number" then return false end
  if type(mailId) == "string" and string.find(mailId, "MailR_") then
    MailR.dm("Debug", string.format("Mail ID contained MailR_ : %s",mailId))
    return true
  end
end

function MailR.IsMailIdSentMail(mailId)
	if type(mailId) ~= "string" then return false end
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
	local originalBody = message.body.."\n\n"
	local attachedGoldStr = MailR.localeStringMap[lang]["Attached Gold: "]
	local codStr = MailR.localeStringMap[lang]["COD: "]
	local postageStr = MailR.localeStringMap[lang]["Postage: "]
	local attachmentStr = MailR.localeStringMap[lang]["Attachments: "]
	local goldString = MailR.DEFAULT_HEADER_COLOR_STRING..attachedGoldStr..MailR.RESET_COLOR_STRING..tostring(message.gold).."\n"
	local codString
	if message.cod then
		codString = MailR.DEFAULT_HEADER_COLOR_STRING..codStr..MailR.RESET_COLOR_STRING.."Yes\n"
	else
		codString = MailR.DEFAULT_HEADER_COLOR_STRING..codStr..MailR.RESET_COLOR_STRING.."No\n"
	end
	local postageString = MailR.DEFAULT_HEADER_COLOR_STRING..postageStr..MailR.RESET_COLOR_STRING..tostring(message.postage).."\n"
	local attachmentString = MailR.DEFAULT_HEADER_COLOR_STRING..attachmentStr.."\n"..MailR.RESET_COLOR_STRING
	for i=1,MailR.MAX_ATTACHMENTS do -- message.numAttachments do
		if message.attachments[i].stack ~= nil then
			local count = message.attachments[i].stack
			local link = message.attachments[i].link
			attachmentString = attachmentString..tostring(count).."x"..link.."\n"
		end
	end
	local bodyString = originalBody..goldString..codString..postageString..attachmentString
	return bodyString
end

function MailR.OnMailReadable(mailId)
    MailR.dm("Debug", "OnMailReadable")
    if MailR.IsMailRMail(mailId) then return end
    if not AreId64sEqual(mailId, self.pendingRequestMailId) then
        return
    end

    self:EndRead()

    self.pendingRequestMailId = nil
    self.mailId = mailId
    self.messageControl:SetHidden(false)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)

    local mailData = self:GetMailData(mailId)
    ZO_MailInboxShared_PopulateMailData(mailData, mailId)
    if not mailData.unread then
        mailData.node.parentNode.data.unreadData[mailData] = nil
    end
    local NOT_USER_REQUESTED = false
    self.navigationTree:RefreshVisible(NOT_USER_REQUESTED)

    ZO_MailInboxShared_UpdateInbox(mailData, self.fromControl, self.subjectLabel, self.expirationLabel, self.receivedLabel, self.bodyLabel)
    self:RefreshMailFrom()
    ZO_Scroll_ResetToTop(self.messagePaneControl)

    self:RefreshMoneyControls()
    self:RefreshAttachmentsHeaderShown()
    self:RefreshAttachmentSlots()
end

MailR.MAX_READ_ATTACHMENTS = MailR.MAX_ATTACHMENTS+1
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
		for i=1, MailR.MAX_ATTACHMENTS do
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
	if(mailData.attachedMoney > 0) then
		self.sentMoneyControl:SetHidden(false)
		ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.sentMoneyControl, "Currency"), CURT_MONEY, mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
	elseif(mailData.codAmount > 0) then
		self.codControl:SetHidden(false)
		ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.codControl, "Currency"), CURT_MONEY, mailData.codAmount, MAIL_COD_ATTACHED_MONEY_OPTIONS)
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
		mailData.subject = MailR.DEFAULT_SENT_MAIL_COLOR_STRING..message.subject
	else
		mailData.subject = MailR.DEFAULT_SAVE_MAIL_COLOR_STRING..message.subject
	end
	mailData.formattedSubject = mailData.subject
	mailData.senderDisplayName = message.recipient
	mailData.senderCharacterName = ""
	mailData.expiresInDays = 0
	mailData.expiresText = "MAILR"
	mailData.state = 0
	mailData.unread = false
	local count = 0
	for i=1,MailR.MAX_ATTACHMENTS do
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

function MailR.FilterDisplay(allArgs)
	-- /mailr inbox
	-- /mailr sent
	-- /mailr all
  local args        = ""
  local var2 = 0
  local var3   = 0
  local argNum      = 0
  for w in string.gmatch(allArgs, "%w+") do
    argNum = argNum + 1
    if argNum == 1 then args = w end
    if argNum == 2 then var2 = tonumber(w) end
    if argNum == 3 then var3 = tonumber(w) end
  end
  args = string.lower(args)

	if not args or args == "help" or args == ""  or args == "?" then
		d(colorRavalox.."[MailR]"..colorYellow.." Accepted Commands:")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailr"..colorSoftYellow.." << shows help")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailr help"..colorSoftYellow.." << shows help")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailr settings"..colorSoftYellow.." << shows MailR settings menu")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailer"..colorSoftYellow.." << shows MailR settings menu")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailr inbox"..colorSoftYellow.." << shows only saved messages")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailr sent"..colorSoftYellow.." << shows only sent messages")
		d(colorRavalox.."[MailR]"..colorCMDBlue.." /mailr all"..colorSoftYellow.." << shows all messages")
	end
	if args == "settings" then
		LAM2:OpenToPanel(MailR.addonPanel)
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
		for k,v in pairs(MailR.SavedMail.messages) do
			MailR.SavedMail.sent_messages[k] = v
		end
		MailR.SavedMail.sent_count = #MailR.SavedMail.sent_messages
		MailR.SavedMail.messages = nil
		MailR.SavedMail.count = nil
		MailR.SavedMail.mailr_version = MailR.SAVED_MAIL_VERSION
	end
end

function MailR.Donate()
	SCENE_MANAGER:Show('mailSend')
	ZO_MailSendToField:SetText("@Sharlikran")
	ZO_MailSendSubjectField:SetText("Donation From "..GetDisplayName())
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
	EVENT_MANAGER:RegisterForEvent("MailR_GuildMailSentSuccessfully", EVENT_MAIL_SEND_SUCCESS, MailR.GuildMailSent)
	EVENT_MANAGER:RegisterForEvent("MailR_GuildMailSentUnsuccessfully", EVENT_MAIL_SEND_FAILED, MailR.GuildMailFailSent)
	EVENT_MANAGER:RegisterForEvent("MailR_AttachmentAdded", EVENT_MAIL_ATTACHMENT_ADDED, MailR.AttachmentAdded)
	EVENT_MANAGER:RegisterForEvent("MailR_AttachmentRemoved", EVENT_MAIL_ATTACHMENT_REMOVED, MailR.AttachmentRemoved)
	EVENT_MANAGER:RegisterForEvent("MailR_CODChanged", EVENT_MAIL_COD_CHANGED, MailR.CODChanged)
	EVENT_MANAGER:RegisterForEvent("MailR_AttachmentMoneyChanged", EVENT_MAIL_ATTACHED_MONEY_CHANGED, MailR.AttachmentMoneyChanged)

	SLASH_COMMANDS["/mailr"] = MailR.FilterDisplay

	-- Donation Button
	MailR.DonateButton = CreateControlFromVirtual('MailR_Donate', ZO_MailInbox, 'ZO_DefaultButton')
	MailR.DonateButton:SetWidth(200)
	MailR.DonateButton:SetText("Donate To MailR")
	MailR.DonateButton:SetHandler('OnClicked', MailR.Donate)
	MailR.DonateButton:SetHidden(true)

	MailR.mailboxActive = false
	MailR.ClearCurrentSendMessage()
	MailR.SavedMail = ZO_SavedVars:New("SV_MailR_SavedMail", 1, nil, MailR.SavedMail_defaults)
	if MailR.SavedMail.display == nil then
		MailR.SavedMail.display = "all"
	end
	-- we have to do this because if we tell ZO_SavedVars our version changed it will delete everything
	-- check for messags as well as version because of version 1.0 conflict with ZOS
	if MailR.SavedMail.messages ~= nil or MailR.SavedMail.mailr_version ~= MailR.SAVED_MAIL_VERSION then
		MailR.ConvertSavedMail()
	end
	math.randomseed(GetTimeStamp())

	lang = GetCVar("Language.2"):upper()
	local replySettingStr = MailR.localeStringMap[lang]["Reply To Message"]
	local forwardSettingStr = MailR.localeStringMap[lang]["Forward Message"]
	local mailSaveStr = MailR.localeStringMap[lang]["Save Mail"]
	ZO_CreateStringId("SI_BINDING_NAME_MAIL_REPLY", replySettingStr)
	ZO_CreateStringId("SI_BINDING_NAME_MAIL_FORWARD", forwardSettingStr)
	ZO_CreateStringId("SI_BINDING_NAME_MAIL_SAVE", mailSaveStr)

	local originalSendToHandler = ZO_MailSendToField:GetHandler("OnTextChanged")
	ZO_MailSendToField:SetHandler("OnTextChanged", function(...) originalSendToHandler(...) MailR.UpdateSendTo() end)
  local originalSubjectHandler = ZO_MailSendSubjectField:GetHandler("OnTextChanged")
  ZO_MailSendSubjectField:SetHandler("OnTextChanged", function(...) originalSubjectHandler(...) MailR.UpdateSendSubject() end)
	ZO_MailSendBodyField:SetHandler("OnTextChanged", function(...) MailR.UpdateSendBody() end)
	local handlerFunc = ZO_ChatWindowMail:GetHandler("OnClicked")
	ZO_ChatWindowMail:SetHandler("OnClicked", function(...) MailR.HideGuildies() handlerFunc(...) end)

	MailR.OverloadMailInbox()
	MailR.OverloadMailSend()
	MailR.UpdateKeybindInfo()
	MailR.GuildThrottleTimer = ZO_TimerBar:New(ThrottleTimer)

	local panelData = {
		type = "panel",
		name = "MailR",
		displayName = "|cFFFFFF MailR",
		author = "Sharlikran, Pills, Ravalox Darkshire, Calia1120",
		version = "2.5.00",  --self.codeVersion,
		slashCommand = "/mailer",
		registerForRefresh = true,
		--registerForDefaults = true,
	}
	LAM2:RegisterAddonPanel("MailR_Panel", panelData)
	local optionsData = {
		 [1] = {
			  type = "checkbox",
			  name = "Guild Mail Enabled",
			  tooltip = "Check to Enable Guild Mail, Uncheck to Disable",
			  getFunc = function() return MailR.SavedMail.guildMailVisible end,
			  setFunc = function(value) MailR.SavedMail.guildMailVisible = value end,
		 },
		 [2] = {
		 	type = "slider",
            name = "Guild Mail Throttle",
            tooltip = "Time between sending messages to guildies",
            min = 1,
            max = 10,
            step = 1,
            getFunc = function() return MailR.SavedMail.throttle_time end,
            setFunc = function(value) MailR.SavedMail.throttle_time = value end,
            default = 1,
         },
		 [3] = {
			  type = "checkbox",
			  name = "Show Donation Button",
			  tooltip = "Check to show the donation button, Uncheck to not show it.",
			  getFunc = function() return MailR.SavedMail.show_donation end,
			  setFunc = function(value) MailR.SavedMail.show_donation = value end,
		 },
	}
	LAM2:RegisterOptionControls("MailR_Panel", optionsData)
end
EVENT_MANAGER:RegisterForEvent("MailR_Init", EVENT_ADD_ON_LOADED , MailR.Init)