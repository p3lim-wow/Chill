local spells = {
	'Dash',
	GetSpellInfo(50213), -- tiger's fury
	'Berserk',
	'Rebirth',
}

-- MAJIK!
local addon = CreateFrame('Frame', 'Chill', UIParent)

local marke = [=[Interface\AddOns\Chill\marke.ttf]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

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
	frame.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

	frame.text = frame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	frame.text:SetPoint('CENTER')

	return frame
end

function addon:StartCooldown(name, start, duration)
	local index, slot = 20
	for frame in next, self.frames do
		if(frame.name and frame.name == name) then
			slot = nil
			return
		elseif(not frame.duration and frame.index < index) then
			index, slot = frame.index, frame
		end
	end

	if(slot) then
		slot.name = name
		slot.duration = start - GetTime() + duration
		slot.icon:SetTexture(GetSpellTexture(name))
		slot:Show()
	end
end

-- this function acts very "jumpy", need to fix it
function addon:StopCooldown(old)
	for frame in next, self.frames do
		if((frame.index > old.index) and frame.duration) then
			old.name, old.duration = frame.name, frame.duration
			old.icon:SetTexture(frame.icon:GetTexture())
			old = frame
		end
	end

	old.name, old.duration = nil, nil
	old:Hide()
end

function addon:CheckCooldown()
	for index, name in next, spells do
		local start, duration, enabled = GetSpellCooldown(name)

		if(enabled == 1 and duration > 1.5) then
			self:StartCooldown(name, start, duration)
		elseif(enabled == 1) then
			for frame in next, self.frames do
				if(frame.name and frame.name == name) then
					self:StopCooldown(frame)
				end
			end
		end
	end
end

addon:RegisterEvent('PLAYER_LOGIN')
addon:SetScript('OnEvent', function(self, event)
	self:SetHeight(24)
	self:SetWidth(#spells * (self:GetHeight() + 3))
	self:SetPoint('BOTTOM', 0, 90)
	self.frames = {}

	local index = 1
	for k in next, spells do
		local frame = self:CreateCooldown()
		frame:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', (index - 1) * (self:GetHeight() + 3), 0)
		frame.index = index

		self.frames[frame] = true
		index = index + 1
	end

	self:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	self:SetScript('OnEvent', self.CheckCooldown)
	self:CheckCooldown()
end)
