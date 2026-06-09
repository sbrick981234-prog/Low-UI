--[[
    ██╗      ██████╗ ██╗    ██╗      ██╗   ██╗██╗
    ██║     ██╔═══██╗██║    ██║      ██║   ██║██║
    ██║     ██║   ██║██║ █╗ ██║      ██║   ██║██║
    ██║     ██║   ██║██║███╗██║      ██║   ██║██║
    ███████╗╚██████╔╝╚███╔███╔╝      ╚██████╔╝██║
    ╚══════╝ ╚═════╝  ╚══╝╚══╝        ╚═════╝ ╚═╝
    Low-UI v2.0
]]

local LowUI = {}
LowUI.__index = LowUI

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────
-- THEME
-- ─────────────────────────────────────────────
local T = {
	BG          = Color3.fromRGB(10,  10,  10),
	Surface     = Color3.fromRGB(20,  20,  20),
	SurfaceHov  = Color3.fromRGB(30,  30,  30),
	Border      = Color3.fromRGB(45,  45,  45),
	Accent      = Color3.fromRGB(255, 255, 255),
	AccentDim   = Color3.fromRGB(190, 190, 190),
	Muted       = Color3.fromRGB(90,  90,  90),
	TextPri     = Color3.fromRGB(255, 255, 255),
	TextSec     = Color3.fromRGB(155, 155, 155),
	TogOff      = Color3.fromRGB(50,  50,  50),
	TogOn       = Color3.fromRGB(230, 230, 230),
	SliderTrack = Color3.fromRGB(38,  38,  38),
	SliderFill  = Color3.fromRGB(210, 210, 210),
	TabLine     = Color3.fromRGB(255, 255, 255),
	DropBG      = Color3.fromRGB(16,  16,  16),
}

-- ─────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
	TweenService:Create(obj,
		TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
		props):Play()
end

local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k,v in pairs(props or {}) do o[k]=v end
	if parent then o.Parent = parent end
	return o
end

local function corner(r, parent)
	return new("UICorner", {CornerRadius = UDim.new(0, r)}, parent)
end

local function stroke(c, th, parent)
	return new("UIStroke", {Color=c, Thickness=th, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, parent)
end

-- ─────────────────────────────────────────────
-- DRAGGABLE
-- ─────────────────────────────────────────────
local function makeDraggable(frame, handle)
	local drag, dragIn, startMouse, startFrame
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = true
			startMouse = inp.Position
			startFrame = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then drag = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then dragIn = inp end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp == dragIn and drag then
			local d = inp.Position - startMouse
			frame.Position = UDim2.new(
				startFrame.X.Scale, startFrame.X.Offset + d.X,
				startFrame.Y.Scale, startFrame.Y.Offset + d.Y)
		end
	end)
end

-- ═════════════════════════════════════════════
-- WINDOW
-- ═════════════════════════════════════════════
function LowUI.new(cfg)
	cfg = cfg or {}
	local self     = setmetatable({}, LowUI)
	self.Title     = cfg.Title   or "Low-UI"
	self.Keybind   = cfg.Keybind or Enum.KeyCode.RightShift
	self.Visible   = true
	self._tabs     = {}
	self._active   = nil
	self._toastY   = 0          -- running offset for stacked toasts

	-- ScreenGui
	local gui = new("ScreenGui", {
		Name = "LowUI",
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	}, LocalPlayer:WaitForChild("PlayerGui"))
	self._gui = gui

	-- Main frame
	local main = new("Frame", {
		Name             = "Main",
		Size             = UDim2.fromOffset(560, 400),
		Position         = UDim2.new(0.5,-280, 0.5,-200),
		BackgroundColor3 = T.BG,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
	}, gui)
	corner(8, main)
	stroke(T.Border, 1, main)
	self._main = main

	-- Shadow
	new("ImageLabel", {
		Name="Shadow", Size=UDim2.new(1,50,1,50), Position=UDim2.new(0,-25,0,-25),
		BackgroundTransparency=1, Image="rbxassetid://6015897843",
		ImageColor3=Color3.new(0,0,0), ImageTransparency=0.5,
		ScaleType=Enum.ScaleType.Slice, SliceCenter=Rect.new(49,49,450,450),
		ZIndex=-1,
	}, main)

	-- ── TITLE BAR ──────────────────────────────
	local tbar = new("Frame", {
		Name="TitleBar", Size=UDim2.new(1,0,0,44),
		BackgroundColor3=T.Surface, BorderSizePixel=0, ZIndex=2,
	}, main)
	corner(8, tbar)
	-- patch bottom of titlebar corners
	new("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),
		BackgroundColor3=T.Surface,BorderSizePixel=0,ZIndex=2},tbar)
	-- bottom divider
	new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=3},tbar)

	-- Title text
	new("TextLabel",{
		Size=UDim2.new(1,-100,1,0), Position=UDim2.fromOffset(16,0),
		BackgroundTransparency=1, Text=self.Title,
		Font=Enum.Font.GothamBold, TextSize=13,
		TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
	},tbar)

	-- Keybind hint
	self._kbHint = new("TextLabel",{
		Size=UDim2.fromOffset(110,44), Position=UDim2.new(1,-150,0,0),
		BackgroundTransparency=1,
		Text="["..self.Keybind.Name.."]",
		Font=Enum.Font.Gotham, TextSize=10,
		TextColor3=T.Muted, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=3,
	},tbar)

	-- Close button
	local closeBtn = new("TextButton",{
		Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-36,0.5,-13),
		BackgroundColor3=T.SurfaceHov, BorderSizePixel=0,
		Text="✕", Font=Enum.Font.GothamBold, TextSize=11,
		TextColor3=T.TextSec, ZIndex=4, AutoButtonColor=false,
	},tbar)
	corner(5, closeBtn)
	closeBtn.MouseButton1Click:Connect(function() self:Toggle() end)
	closeBtn.MouseEnter:Connect(function() tw(closeBtn,{BackgroundColor3=Color3.fromRGB(55,55,55)}) end)
	closeBtn.MouseLeave:Connect(function() tw(closeBtn,{BackgroundColor3=T.SurfaceHov}) end)

	makeDraggable(main, tbar)

	-- ── TAB BAR ────────────────────────────────
	local tabBar = new("Frame",{
		Name="TabBar", Size=UDim2.new(1,0,0,36),
		Position=UDim2.new(0,0,0,44),
		BackgroundColor3=T.BG, BorderSizePixel=0,
	},main)
	-- bottom divider
	new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=T.Border,BorderSizePixel=0},tabBar)

	local tabScroll = new("ScrollingFrame",{
		Size=UDim2.new(1,0,1,0),
		BackgroundTransparency=1, BorderSizePixel=0,
		ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.X,
		ScrollingDirection=Enum.ScrollingDirection.X,
	},tabBar)
	local tabLayout = new("UIListLayout",{
		FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,0),
	},tabScroll)
	new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},tabScroll)
	self._tabScroll = tabScroll

	-- ── CONTENT ────────────────────────────────
	local content = new("Frame",{
		Name="Content",
		Size=UDim2.new(1,0,1,-80),
		Position=UDim2.new(0,0,0,80),
		BackgroundColor3=T.BG, BorderSizePixel=0,
		ClipsDescendants=true,
	},main)
	self._content = content

	-- Keybind
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == self.Keybind then self:Toggle() end
	end)

	-- Auto settings tab
	self:_makeSettingsTab()

	return self
end

-- ═════════════════════════════════════════════
-- TOGGLE
-- ═════════════════════════════════════════════
function LowUI:Toggle()
	self.Visible = not self.Visible
	if self.Visible then
		self._main.Visible = true
		self._main.Size = UDim2.fromOffset(560, 0)
		tw(self._main, {Size=UDim2.fromOffset(560,400)}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	else
		tw(self._main, {Size=UDim2.fromOffset(560,0)}, 0.16)
		task.delay(0.18, function()
			if not self.Visible then self._main.Visible = false end
		end)
	end
end

-- ═════════════════════════════════════════════
-- ADD TAB  →  returns tabAPI
-- ═════════════════════════════════════════════
function LowUI:AddTab(cfg)
	cfg = cfg or {}
	local name = cfg.Name or ("Tab "..#self._tabs+1)

	-- ── Tab button ──────────────────────────
	local btn = new("TextButton",{
		Size             = UDim2.fromOffset(0, 36),
		AutomaticSize    = Enum.AutomaticSize.X,
		BackgroundColor3 = T.BG,
		BorderSizePixel  = 0,
		Text             = "",
		AutoButtonColor  = false,
		LayoutOrder      = #self._tabs + 1,
		ZIndex           = 2,
	}, self._tabScroll)

	new("UIPadding",{
		PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
	}, btn)

	local btnInner = new("Frame",{
		Size=UDim2.new(1,0,1,0),
		BackgroundTransparency=1,
	}, btn)
	new("UIListLayout",{
		FillDirection=Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder,
	}, btnInner)

	local btnLabel = new("TextLabel",{
		Size             = UDim2.fromOffset(0,36),
		AutomaticSize    = Enum.AutomaticSize.X,
		BackgroundTransparency=1,
		Text             = name,
		Font             = Enum.Font.GothamMedium,
		TextSize         = 12,
		TextColor3       = T.Muted,
		TextXAlignment   = Enum.TextXAlignment.Center,
		LayoutOrder      = 1, ZIndex=3,
	}, btnInner)

	-- active underline
	local line = new("Frame",{
		Size=UDim2.new(1,-28,0,2),
		Position=UDim2.new(0,14,1,-2),
		BackgroundColor3=T.TabLine,
		BorderSizePixel=0,
		BackgroundTransparency=1,
		ZIndex=3,
	}, btn)

	-- ── Page (ScrollingFrame) ────────────────
	local page = new("ScrollingFrame",{
		Name             = name.."_Page",
		Size             = UDim2.new(1,0,1,0),
		BackgroundTransparency=1,
		BorderSizePixel  = 0,
		ScrollBarThickness=3,
		ScrollBarImageColor3=T.Border,
		CanvasSize       = UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.Y,
		Visible          = false,
		ZIndex           = 1,
	}, self._content)

	local pageLayout = new("UIListLayout",{
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,6),
	}, page)
	new("UIPadding",{
		PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12),
		PaddingTop=UDim.new(0,10),  PaddingBottom=UDim.new(0,10),
	}, page)

	local tdata = { btn=btn, label=btnLabel, line=line, page=page, order=#self._tabs+1 }
	table.insert(self._tabs, tdata)

	local function activate()
		-- deactivate old
		if self._active then
			local p = self._active
			tw(p.label, {TextColor3=T.Muted})
			tw(p.line,  {BackgroundTransparency=1})
			p.page.Visible = false
		end
		self._active = tdata
		tw(btnLabel, {TextColor3=T.TextPri})
		tw(line,     {BackgroundTransparency=0})
		page.Visible = true
	end

	btn.MouseButton1Click:Connect(activate)
	btn.MouseEnter:Connect(function()
		if self._active ~= tdata then tw(btnLabel,{TextColor3=T.TextSec}) end
	end)
	btn.MouseLeave:Connect(function()
		if self._active ~= tdata then tw(btnLabel,{TextColor3=T.Muted}) end
	end)

	if #self._tabs == 1 then activate() end

	-- ─────────────────────────────────────────
	-- TAB API
	-- ─────────────────────────────────────────
	local api = {}
	local elemOrder = 0
	local function nextOrder() elemOrder = elemOrder + 1; return elemOrder end

	-- make base row frame
	local function baseRow(h)
		local r = new("Frame",{
			Size             = UDim2.new(1,0,0,h),
			BackgroundColor3 = T.Surface,
			BorderSizePixel  = 0,
			LayoutOrder      = nextOrder(),
		}, page)
		corner(6, r)
		stroke(T.Border, 1, r)
		return r
	end

	-- ── SECTION ──────────────────────────────
	function api:AddSection(sName)
		local lbl = new("TextLabel",{
			Size=UDim2.new(1,0,0,20),
			BackgroundTransparency=1,
			Text=(sName or ""):upper(),
			Font=Enum.Font.GothamBold, TextSize=9,
			TextColor3=T.Muted, TextXAlignment=Enum.TextXAlignment.Left,
			LayoutOrder=nextOrder(),
		}, page)
		new("UIPadding",{PaddingLeft=UDim.new(0,4)},lbl)
		new("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
			BackgroundColor3=T.Border,BorderSizePixel=0},lbl)
	end

	-- ── BUTTON ───────────────────────────────
	function api:AddButton(c)
		c = c or {}
		local r = baseRow(c.Desc and 50 or 40)
		local yName = c.Desc and 8 or 11

		new("TextLabel",{
			Size=UDim2.new(1,-50,0,18), Position=UDim2.fromOffset(14,yName),
			BackgroundTransparency=1, Text=c.Name or "Button",
			Font=Enum.Font.GothamMedium, TextSize=12,
			TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
		},r)
		if c.Desc then
			new("TextLabel",{
				Size=UDim2.new(1,-50,0,14), Position=UDim2.fromOffset(14,28),
				BackgroundTransparency=1, Text=c.Desc,
				Font=Enum.Font.Gotham, TextSize=10,
				TextColor3=T.Muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
			},r)
		end
		-- arrow
		new("TextLabel",{
			Size=UDim2.fromOffset(16,16), Position=UDim2.new(1,-28,0.5,-8),
			BackgroundTransparency=1, Text="›",
			Font=Enum.Font.GothamBold, TextSize=18,
			TextColor3=T.Muted, ZIndex=2,
		},r)

		local hit = new("TextButton",{
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
			Text="", ZIndex=3,
		},r)
		hit.MouseEnter:Connect(function() tw(r,{BackgroundColor3=T.SurfaceHov}) end)
		hit.MouseLeave:Connect(function() tw(r,{BackgroundColor3=T.Surface}) end)
		hit.MouseButton1Click:Connect(function()
			tw(r,{BackgroundColor3=T.Border},0.05)
			task.delay(0.08,function() tw(r,{BackgroundColor3=T.SurfaceHov}) end)
			if c.Callback then c.Callback() end
		end)
	end

	-- ── TOGGLE ───────────────────────────────
	function api:AddToggle(c)
		c = c or {}
		local state = c.Default or false
		local r = baseRow(c.Desc and 50 or 40)
		local yName = c.Desc and 8 or 11

		new("TextLabel",{
			Size=UDim2.new(1,-64,0,18), Position=UDim2.fromOffset(14,yName),
			BackgroundTransparency=1, Text=c.Name or "Toggle",
			Font=Enum.Font.GothamMedium, TextSize=12,
			TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
		},r)
		if c.Desc then
			new("TextLabel",{
				Size=UDim2.new(1,-64,0,14), Position=UDim2.fromOffset(14,28),
				BackgroundTransparency=1, Text=c.Desc,
				Font=Enum.Font.Gotham, TextSize=10,
				TextColor3=T.Muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
			},r)
		end

		local track = new("Frame",{
			Size=UDim2.fromOffset(36,20), Position=UDim2.new(1,-48,0.5,-10),
			BackgroundColor3= state and T.TogOn or T.TogOff, BorderSizePixel=0, ZIndex=2,
		},r)
		corner(10,track)
		local thumb = new("Frame",{
			Size=UDim2.fromOffset(14,14),
			Position= state and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3),
			BackgroundColor3= state and T.BG or T.Muted, BorderSizePixel=0, ZIndex=3,
		},track)
		corner(7,thumb)

		local function upd()
			tw(track,{BackgroundColor3= state and T.TogOn or T.TogOff},0.18)
			tw(thumb,{
				Position= state and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3),
				BackgroundColor3= state and T.BG or T.Muted,
			},0.18)
		end

		local hit = new("TextButton",{
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=4,
		},r)
		hit.MouseEnter:Connect(function() tw(r,{BackgroundColor3=T.SurfaceHov}) end)
		hit.MouseLeave:Connect(function() tw(r,{BackgroundColor3=T.Surface}) end)
		hit.MouseButton1Click:Connect(function()
			state = not state; upd()
			if c.Callback then c.Callback(state) end
		end)

		local obj = {}
		function obj:Set(v) state=v; upd(); if c.Callback then c.Callback(state) end end
		function obj:Get() return state end
		return obj
	end

	-- ── SLIDER ───────────────────────────────
	function api:AddSlider(c)
		c = c or {}
		local mn, mx   = c.Min or 0, c.Max or 100
		local step     = c.Step or 1
		local suffix   = c.Suffix or ""
		local val      = math.clamp(c.Default or mn, mn, mx)
		local dragging = false

		local r = baseRow(60)

		new("TextLabel",{
			Size=UDim2.new(0.6,0,0,18), Position=UDim2.fromOffset(14,9),
			BackgroundTransparency=1, Text=c.Name or "Slider",
			Font=Enum.Font.GothamMedium, TextSize=12,
			TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
		},r)

		local valLbl = new("TextLabel",{
			Size=UDim2.new(0.4,-14,0,18), Position=UDim2.new(0.6,0,0,9),
			BackgroundTransparency=1, Text=tostring(val)..suffix,
			Font=Enum.Font.GothamBold, TextSize=12,
			TextColor3=T.AccentDim, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=2,
		},r)
		new("UIPadding",{PaddingRight=UDim.new(0,14)},valLbl)

		if c.Desc then
			new("TextLabel",{
				Size=UDim2.new(1,-28,0,12), Position=UDim2.fromOffset(14,27),
				BackgroundTransparency=1, Text=c.Desc,
				Font=Enum.Font.Gotham, TextSize=9,
				TextColor3=T.Muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
			},r)
		end

		local track = new("Frame",{
			Size=UDim2.new(1,-28,0,4),
			Position=UDim2.new(0,14,1,-14),
			BackgroundColor3=T.SliderTrack, BorderSizePixel=0, ZIndex=2,
		},r)
		corner(2,track)

		local fill = new("Frame",{
			Size=UDim2.new(0,0,1,0),
			BackgroundColor3=T.SliderFill, BorderSizePixel=0,
		},track)
		corner(2,fill)

		local knob = new("Frame",{
			Size=UDim2.fromOffset(14,14),
			AnchorPoint=Vector2.new(0.5,0.5),
			Position=UDim2.new(0,0,0.5,0),
			BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=3,
		},track)
		corner(7,knob)
		stroke(T.BG,2,knob)

		local function updFill()
			local pct = (val-mn)/(mx-mn)
			fill.Size     = UDim2.new(pct,0,1,0)
			knob.Position = UDim2.new(pct,0,0.5,0)
		end

		local function setFromX(x)
			local w   = track.AbsoluteSize.X
			local pct = math.clamp((x - track.AbsolutePosition.X)/w, 0, 1)
			local raw = mn + (mx-mn)*pct
			val = math.clamp(math.round(raw/step)*step, mn, mx)
			valLbl.Text = tostring(val)..suffix
			updFill()
			if c.Callback then c.Callback(val) end
		end

		local tBtn = new("TextButton",{
			Size=UDim2.new(1,0,1,10), Position=UDim2.new(0,0,0,-5),
			BackgroundTransparency=1, Text="", ZIndex=4,
		},track)
		tBtn.MouseButton1Down:Connect(function() dragging=true; setFromX(UserInputService:GetMouseLocation().X) end)
		UserInputService.InputChanged:Connect(function(inp)
			if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
				setFromX(inp.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
		end)

		task.defer(updFill)

		local obj = {}
		function obj:Set(v) val=math.clamp(v,mn,mx); valLbl.Text=tostring(val)..suffix; updFill(); if c.Callback then c.Callback(val) end end
		function obj:Get() return val end
		return obj
	end

	-- ── VALUE ────────────────────────────────
	function api:AddValue(c)
		c = c or {}
		local suffix = c.Suffix or ""
		local r = baseRow(40)

		new("TextLabel",{
			Size=UDim2.new(0.55,0,1,0), Position=UDim2.fromOffset(14,0),
			BackgroundTransparency=1, Text=c.Name or "Value",
			Font=Enum.Font.GothamMedium, TextSize=12,
			TextColor3=T.TextSec, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
		},r)

		local vLbl = new("TextLabel",{
			Size=UDim2.new(0.45,-14,1,0), Position=UDim2.new(0.55,0,0,0),
			BackgroundTransparency=1, Text=tostring(c.Value or "—")..suffix,
			Font=Enum.Font.GothamBold, TextSize=12,
			TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=2,
		},r)
		new("UIPadding",{PaddingRight=UDim.new(0,14)},vLbl)

		local obj = {}
		function obj:Set(v) vLbl.Text=tostring(v)..suffix end
		function obj:Get() return vLbl.Text end
		return obj
	end

	-- ── DROPDOWN ─────────────────────────────
	function api:AddDropdown(c)
		c = c or {}
		local opts     = c.Options  or {}
		local selected = c.Default  or (opts[1] or "None")
		local open     = false

		-- wrapper (not clipped so panel can overflow)
		local wrap = new("Frame",{
			Size=UDim2.new(1,0,0,40),
			BackgroundTransparency=1,
			ClipsDescendants=false,
			LayoutOrder=nextOrder(),
			ZIndex=5,
		}, page)

		local r = new("Frame",{
			Size=UDim2.new(1,0,0,40),
			BackgroundColor3=T.Surface, BorderSizePixel=0, ZIndex=6,
		}, wrap)
		corner(6,r)
		stroke(T.Border,1,r)

		new("TextLabel",{
			Size=UDim2.new(0.45,0,1,0), Position=UDim2.fromOffset(14,0),
			BackgroundTransparency=1, Text=c.Name or "Dropdown",
			Font=Enum.Font.GothamMedium, TextSize=12,
			TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7,
		},r)

		local selLbl = new("TextLabel",{
			Size=UDim2.new(0.5,-36,1,0), Position=UDim2.new(0.5,0,0,0),
			BackgroundTransparency=1, Text=tostring(selected),
			Font=Enum.Font.Gotham, TextSize=11,
			TextColor3=T.TextSec, TextXAlignment=Enum.TextXAlignment.Right,
			ClipsDescendants=true, ZIndex=7,
		},r)
		new("UIPadding",{PaddingRight=UDim.new(0,4)},selLbl)

		local arrow = new("TextLabel",{
			Size=UDim2.fromOffset(20,40), Position=UDim2.new(1,-24,0,0),
			BackgroundTransparency=1, Text="⌄",
			Font=Enum.Font.GothamBold, TextSize=14,
			TextColor3=T.Muted, ZIndex=7,
		},r)

		-- panel
		local panel = new("Frame",{
			Size=UDim2.new(1,0,0,0),
			Position=UDim2.fromOffset(0,42),
			BackgroundColor3=T.DropBG, BorderSizePixel=0,
			ClipsDescendants=true, Visible=false, ZIndex=20,
		}, wrap)
		corner(6,panel)
		stroke(T.Border,1,panel)

		local pScroll = new("ScrollingFrame",{
			Size=UDim2.new(1,0,1,0),
			BackgroundTransparency=1, BorderSizePixel=0,
			ScrollBarThickness=3, ScrollBarImageColor3=T.Border,
			CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
			ZIndex=21,
		}, panel)
		new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)},pScroll)
		new("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),
			PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)},pScroll)

		local function buildOpts()
			for _,ch in ipairs(pScroll:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			for i,opt in ipairs(opts) do
				local isActive = (selected == opt)
				local ob = new("TextButton",{
					Size=UDim2.new(1,0,0,30),
					BackgroundColor3= isActive and T.SurfaceHov or T.DropBG,
					BorderSizePixel=0, Text="",
					AutoButtonColor=false, LayoutOrder=i, ZIndex=22,
				}, pScroll)
				corner(4,ob)

				local dot = new("Frame",{
					Size=UDim2.fromOffset(6,6), Position=UDim2.fromOffset(10,12),
					BackgroundColor3= isActive and T.Accent or T.Muted,
					BorderSizePixel=0, ZIndex=23,
				},ob)
				corner(3,dot)

				new("TextLabel",{
					Size=UDim2.new(1,-26,1,0), Position=UDim2.fromOffset(24,0),
					BackgroundTransparency=1, Text=tostring(opt),
					Font=Enum.Font.Gotham, TextSize=12,
					TextColor3= isActive and T.TextPri or T.TextSec,
					TextXAlignment=Enum.TextXAlignment.Left, ZIndex=23,
				},ob)

				ob.MouseEnter:Connect(function() tw(ob,{BackgroundColor3=T.SurfaceHov}) end)
				ob.MouseLeave:Connect(function()
					tw(ob,{BackgroundColor3= (selected==opt) and T.SurfaceHov or T.DropBG})
				end)
				ob.MouseButton1Click:Connect(function()
					selected = opt
					selLbl.Text = tostring(selected)
					if c.Callback then c.Callback(selected) end
					-- close
					open = false
					tw(panel,{Size=UDim2.new(1,0,0,0)},0.12)
					task.delay(0.13,function() panel.Visible=false; wrap.Size=UDim2.new(1,0,0,40) end)
					tw(r,{BackgroundColor3=T.Surface})
					buildOpts()
				end)
			end
		end
		buildOpts()

		local function toggleDrop()
			open = not open
			if open then
				local h = math.min(#opts*34+8, 180)
				panel.Visible = true
				wrap.Size = UDim2.new(1,0,0, 40+4+h)
				tw(panel,{Size=UDim2.new(1,0,0,h)},0.15)
				tw(r,{BackgroundColor3=T.SurfaceHov})
			else
				tw(panel,{Size=UDim2.new(1,0,0,0)},0.12)
				task.delay(0.13,function()
					panel.Visible=false; wrap.Size=UDim2.new(1,0,0,40)
				end)
				tw(r,{BackgroundColor3=T.Surface})
			end
		end

		local hit = new("TextButton",{
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=8,
		},r)
		hit.MouseButton1Click:Connect(toggleDrop)
		hit.MouseEnter:Connect(function() if not open then tw(r,{BackgroundColor3=T.SurfaceHov}) end end)
		hit.MouseLeave:Connect(function() if not open then tw(r,{BackgroundColor3=T.Surface}) end end)

		local obj = {}
		function obj:Set(v) selected=v; selLbl.Text=tostring(v); buildOpts() end
		function obj:Get() return selected end
		function obj:SetOptions(o) opts=o; buildOpts() end
		return obj
	end

	return api
end

-- ═════════════════════════════════════════════
-- SETTINGS TAB
-- ═════════════════════════════════════════════
function LowUI:_makeSettingsTab()
	local s = self:AddTab({ Name = "Settings" })
	s:AddSection("Keybind")

	local listening = false
	s:AddButton({
		Name = "Open / Close Key",
		Desc = "Current: "..self.Keybind.Name,
		Callback = function() end,  -- overridden below
	})

	-- patch last added button to do keybind picking
	local lastBtn
	for _,ch in ipairs(self._content:GetChildren()) do
		local last = ch:GetChildren()
		if #last > 0 then
			for _,el in ipairs(ch:GetChildren()) do
				if el:IsA("Frame") then lastBtn = el end
			end
		end
	end

	if lastBtn then
		local hit = lastBtn:FindFirstChildWhichIsA("TextButton", true)
		local descLbl
		for _,d in ipairs(lastBtn:GetDescendants()) do
			if d:IsA("TextLabel") and d.TextSize == 10 then descLbl = d end
		end

		if hit then
			-- disconnect old, add new
			hit.MouseButton1Click:Connect(function()
				if listening then return end
				listening = true
				if descLbl then descLbl.Text = "Press any key..." end
				local conn
				conn = UserInputService.InputBegan:Connect(function(inp, gp)
					if gp then return end
					if inp.UserInputType == Enum.UserInputType.Keyboard then
						self.Keybind = inp.KeyCode
						self._kbHint.Text = "["..inp.KeyCode.Name.."]"
						if descLbl then descLbl.Text = "Current: "..inp.KeyCode.Name end
						listening = false
						conn:Disconnect()
					end
				end)
			end)
		end
	end

	s:AddSection("Info")
	s:AddValue({ Name = "Version", Value = "2.0" })
	s:AddValue({ Name = "Library", Value = "Low-UI" })
end

-- ═════════════════════════════════════════════
-- NOTIFY
-- ═════════════════════════════════════════════
function LowUI:Notify(cfg)
	cfg = cfg or {}
	local title    = cfg.Title    or "Notice"
	local desc     = cfg.Desc     or ""
	local duration = cfg.Duration or 3
	local h        = desc ~= "" and 60 or 44

	local toast = new("Frame",{
		Name             = "Toast",
		Size             = UDim2.fromOffset(260, h),
		-- anchor bottom-right, stacking upward
		AnchorPoint      = Vector2.new(1, 1),
		Position         = UDim2.new(1, -16, 1, -16 - self._toastY),
		BackgroundColor3 = T.Surface,
		BorderSizePixel  = 0,
		ZIndex           = 50,
	}, self._gui)
	corner(7, toast)
	stroke(T.Border, 1, toast)

	-- accent left stripe
	local stripe = new("Frame",{
		Size=UDim2.new(0,3,1,-12), Position=UDim2.fromOffset(0,6),
		BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=51,
	}, toast)
	corner(2, stripe)

	new("TextLabel",{
		Size=UDim2.new(1,-20,0,18), Position=UDim2.fromOffset(14, desc ~= "" and 10 or 13),
		BackgroundTransparency=1, Text=title,
		Font=Enum.Font.GothamBold, TextSize=12,
		TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=52,
	}, toast)

	if desc ~= "" then
		new("TextLabel",{
			Size=UDim2.new(1,-20,0,14), Position=UDim2.fromOffset(14,30),
			BackgroundTransparency=1, Text=desc,
			Font=Enum.Font.Gotham, TextSize=10,
			TextColor3=T.TextSec, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=52,
		}, toast)
	end

	self._toastY = self._toastY + h + 8

	-- slide in from right
	toast.Position = UDim2.new(1, 280, 1, -16 - (self._toastY - h - 8))
	tw(toast, {Position=UDim2.new(1,-16,1,-16-(self._toastY-h-8))}, 0.25, Enum.EasingStyle.Back)

	task.delay(duration, function()
		tw(toast, {Position=UDim2.new(1,280,1,-16-(self._toastY-h-8))}, 0.18)
		task.delay(0.2, function()
			self._toastY = math.max(0, self._toastY - h - 8)
			toast:Destroy()
		end)
	end)
end

-- ═════════════════════════════════════════════
function LowUI:Destroy() self._gui:Destroy() end

return LowUI
