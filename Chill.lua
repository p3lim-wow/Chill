--[[

	Copyright (c) 2009 Adrian L Lange <adrianlund@gmail.com>
	All rights reserved.

	You're allowed to use this addon, free of monetary charge,
	but you are not allowed to modify, alter, or redistribute
	this addon without express, written permission of the author.

--]]

local addon = CreateFrame('Frame', 'Chill', UIParent)
local marke = [=[Interface\AddOns\Chill\marke.ttf]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local function slashCommand(str)
	local type, id, _ , name = string.match(str, '|H(%w+):(%w+)(.*)|h%[(.+)%]|h') -- todo: clean up

	if(str and type) then
		id = tonumber(id)

		if(not ChillDB[type][id]) then
			table.insert(ChillDB[type], id, name)
			print('|cffff8080Chill:|r Added', str, 'to the list')
		else
			ChillDB[type][id] = nil
			print('|cffff8080Chill:|r Removed', str, 'from the list')
		end

		addon:CreateFrames()
	else
		print('|cffff8080Chill:|r Please link a spell/item to watch!')
	end
end

local function onUpdate(frame, elapsed)
	frame.duration = frame.duration - elapsed

	if(frame.duration <= 0) then
		return addon:StopCooldown(frame, frame.name)
	end

	if(frame.duration > 5 and frame.duration < 60) then
		frame.text:SetFormattedText('%d', frame.duration)
	elseif(frame.duration < 5) then
		frame.text:SetFormattedText('|cffff0000%.1f|r', frame.duration)
	else
		frame.text:SetText()
	end
end

function addon:CreateFrames()
	for k in next, ChillDB.spell do
		if(not self.frames['spell:'..k]) then
			local frame = self:CreateCooldown()
			frame:SetPoint('BOTTOMLEFT', self, (self.index - 1) * (self:GetHeight() + 3), 0)
			frame.index = self.index

			self.frames['spell:'..k] = frame
			self.index = self.index + 1
		end
	end

	for k in next, ChillDB.item do
		if(not self.frames['item:'..k]) then
			local frame = self:CreateCooldown()
			frame:SetPoint('BOTTOMLEFT', self, (self.index - 1) * (self:GetHeight() + 3), 0)
			frame.index = self.index

			self.frames['item:'..k] = frame
			self.index = self.index + 1
		end
	end
end

function addon:CreateCooldown()
	local frame = CreateFrame('Frame', nil, self)
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0)
	frame:SetHeight(self:GetHeight())
	frame:SetWidth(self:GetHeight())
	frame:SetScript('OnUpdate', onUpdate)
	frame:Hide()

	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetAllPoints(frame)
	frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	frame.text = frame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	frame.text:SetPoint('CENTER')

	return frame
end

function addon:StartCooldown(name, texture, start, duration)
	local index, slot = 20
	for id, frame in next, self.frames do
		if(frame.name and frame.name == name) then
			slot = nil
			return
		elseif(not frame.duration and frame.index < index) then
			index, slot = frame.index, frame
		end
	end

	slot.name = name
	slot.duration = start - GetTime() + duration
	slot.icon:SetTexture(texture)
	slot:Show()

	self.active = self.active + 1
	self:SetWidth(self.active > 0 and ((self.active * (self:GetHeight() + 3)) - 3) or self:GetHeight())
end

function addon:StopCooldown(old)
	for id, frame in next, self.frames do
		if((frame.index > old.index) and frame.duration) then
			old.name, old.duration = frame.name, frame.duration
			old.icon:SetTexture(frame.icon:GetTexture())
			old = frame
		end
	end

	self.active = self.active - 1
	self:SetWidth(self.active > 0 and ((self.active * (self:GetHeight() + 3)) - 3) or self:GetHeight())
	old.name, old.duration = nil, nil
	old:Hide()
end

function addon:SPELL_UPDATE_COOLDOWN()
	for id, name in next, ChillDB.spell do
		local start, duration, enabled = GetSpellCooldown(name)

		if(enabled == 1 and duration > 1.5) then
			self:StartCooldown(name, GetSpellTexture(name), start, duration)
		elseif(enabled == 1) then
			for id, frame in next, self.frames do
				if(frame.name and frame.name == name) then
					self:StopCooldown(frame)
				end
			end
		end
	end
end

function addon:BAG_UPDATE_COOLDOWN()
	for id, name in next, ChillDB.item do
		local start, duration, enabled = GetItemCooldown(id)

		if(enabled == 1) then
			self:StartCooldown(name, GetItemIcon(id), start, duration)
		end
	end
end

addon:RegisterEvent('ADDON_LOADED')
addon:SetScript('OnEvent', function(self, event, name)
	if(name ~= self:GetName()) then return end
	ChillDB = ChillDB or {spell = {}, item = {}}

	SLASH_Chill1 = '/chill'
	SlashCmdList[name] = slashCommand

	self.index = 1
	self.active = 0
	self.frames = {}
	self:SetHeight(24)
	self:SetWidth(self.active > 0 and ((self.active * (self:GetHeight() + 3)) - 3) or self:GetHeight())
	self:SetPoint('BOTTOM', 0, 90)

	self:CreateFrames()
	self:BAG_UPDATE_COOLDOWN()
	self:SPELL_UPDATE_COOLDOWN()
	self:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	self:RegisterEvent('BAG_UPDATE_COOLDOWN')
	self:UnregisterEvent(event)
	self:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end)
end)
