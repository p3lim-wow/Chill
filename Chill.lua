--[[

	Copyright (c) 2009-2010 Adrian L Lange <adrianlund@gmail.com>
	All rights reserved.

	You're allowed to use this addon, free of monetary charge,
	but you are not allowed to modify, alter, or redistribute
	this addon without express, written permission of the author.

--]]

local addonName = ...

local Chill = CreateFrame('Frame', nil, UIParent)

local ACTIVE = {spell = {}, item = {}}
local BUTTONS = {}
local BACKDROP = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function SlashCommand(str)
	local type, id = str:match('|H(%w+):(%d+)')

	if(ChillDB[type]) then
		id = tonumber(id)

		if(not ChillDB[type][id]) then
			ChillDB[type][id] = true
			print('|cffff8080Chill:|r Added', str, 'to the list')
		else
			ChillDB[type][id] = nil
			print('|cffff8080Chill:|r Removed', str, 'from the list')
		end
	else
		print('|cffff8080Chill:|r Please link a spell or item to watch!')
	end
end

local function UpdatePositions()
	local visible = 0
	for index = 1, #BUTTONS do
		local button = BUTTONS[index]
		if(button:IsShown()) then
			local gap = visible > 0 and 6 or 0
			button:ClearAllPoints()
			button:SetPoint('LEFT', visible * (24 + gap), 0)

			visible = visible + 1
		end
	end

	Chill:SetWidth(visible * (24 + 6) - 6)
end

local function UpdateCooldown(button, elapsed)
	button.duration = button.duration - elapsed

	if(button.duration < 0) then
		button:Hide()
		ACTIVE[button.type][button.id] = nil
		return UpdatePositions()
	end

	if(button.duration > 5 and button.duration < 60) then
		button.count:SetFormattedText('%d', button.duration)
	elseif(button.duration < 5) then
		button.count:SetFormattedText('|cffff0000%.1f|r', button.duration)
	else
		button.count:SetText()
	end
end

local function CreateButton()
	local button = CreateFrame('Frame', nil, Chill)
	button:SetSize(24, 24)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
	button:SetScript('OnUpdate', UpdateCooldown)

	local icon = button:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon = icon

	local count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal') -- XXX: replace font
	count:SetPoint('CENTER')
	button.count = count

	table.insert(BUTTONS, button)
	return button
end

local function GetButton()
	for index, button in pairs(BUTTONS) do
		if(not button:IsShown()) then
			return button
		end
	end

	return CreateButton()
end

local function UpdateButton(type, id, start, duration, texture)
	local button = ACTIVE[type][id]
	if(not button) then
		button = GetButton()
		button.icon:SetTexture(texture)
		button.duration = start - GetTime() + duration
		button.type = type
		button.id = id
		button:Show()

		ACTIVE[type][id] = button
		UpdatePositions()
	else
		button.duration = start - GetTime() + duration
	end
end

function Chill:BAG_UPDATE_COOLDOWN()
	for item in pairs(ChillDB.item) do
		local start, duration, enabled = GetItemCooldown(item)
		if(enabled == 1 and duration > 30) then
			UpdateButton('item', item, start, duration, GetItemIcon(item))
		end
	end
end

function Chill:SPELL_UPDATE_COOLDOWN()
	for spell in pairs(ChillDB.spell) do
		local button = ACTIVE.spell[spell]
		local start, duration, enabled = GetSpellCooldown(spell)

		if((enabled == 1 and duration > 1.5) or (button and button.start ~= start)) then
			local __, __, texture = GetSpellInfo(spell)
			UpdateButton('spell', spell, start, duration, texture)
		end
	end
end

Chill:RegisterEvent('ADDON_LOADED')
Chill:SetScript('OnEvent', function(self, event, name)
	if(name ~= addonName) then return end
	ChillDB = ChillDB or ACTIVE

	SLASH_Chill1 = '/chill'
	SlashCmdList[name] = SlashCommand

	self:SetHeight(24)
	self:SetPoint('BOTTOM', 0, 90)

	self:BAG_UPDATE_COOLDOWN()
	self:SPELL_UPDATE_COOLDOWN()
	self:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	self:RegisterEvent('BAG_UPDATE_COOLDOWN')

	self:UnregisterEvent(event)
	self:SetScript('OnEvent', function(self, event, ...) self[event](self) end)
end)
