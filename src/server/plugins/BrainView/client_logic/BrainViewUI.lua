--[[

    BrainView Debug UI

    Griffin Dalby
    2025.11.06

    This Module will provide functionality for the BrainView UI.

--]]

--]] Services
--]] Modules
--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
function trimDecimal(num: number): string
	local rounded = math.floor(num * 1000 + 0.5) / 1000
	local str = string.format("%.3f", rounded)
	str = str:gsub("0+$", "")
	str = str:gsub("%.$", "")
	str = str:gsub("^0(%.)", "%1")

	return str
end

function canRenderIdx(idx: number, max: number)
    if max >= 400 then
        return idx%100==0
    elseif max >= 200 then
        return idx%50==0
    elseif max >= 100 then
        return idx%25==0
    elseif max >= 50 then
        return idx%10==0
    elseif max >= 20 then
        return idx%5==0
    else return true end
end

function transformLine(line: Frame, pointA: Vector2, pointB: Vector2, thickness: number?)
    assert(line.Parent, `[{script.Name}] Attempt to transform a destroyed line!`)
    local container = line.Parent.Parent :: Frame
    
    local middle = (pointA+pointB)/2
    local diff = pointB-pointA
    local length = diff.Magnitude

    local containerAbsPos = container.AbsolutePosition
    local localMiddle = middle-containerAbsPos

    line.Size = UDim2.new(0, length, 0, thickness or 2)
    line.Position = UDim2.new(0, localMiddle.X, 0, localMiddle.Y)
    line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
end

function drawLine(container: Frame & {Lines: Frame}, pointA: Vector2, pointB: Vector2, thickness: number?, color: Color3)
    local line = Instance.new("Frame")
    line.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Parent = container.Lines
    line.ZIndex = 9996
    line.Transparency = .45

    transformLine(line, pointA, pointB, thickness)

    return line
end

--]] Module
local bvui = {}
bvui.__index = bvui

type self = {}
export type BrainViewUI = typeof(setmetatable({} :: self, bvui))

function bvui.new() : BrainViewUI
    local self = setmetatable({}, bvui)

    --] Initalize Self
    self.ui = script.BrainView:Clone() :: ScreenGui
    self.templates = {}

    self.param_color_cache = {}

    --] Generate Templates
    local function captureTemplate(name: string, a: GuiBase)
        if self.templates[name] then
            warn(debug.traceback(`[{script.Name}] Template w/ name "{name}" already exists!`, 3))
            return end

        self.templates[name] = a
        a.Parent = script
    end

    local main = self.ui.Main
    local params = main.Parameters

    captureTemplate('graph_key', params.Key.Template)
    captureTemplate('graph_dot', params.Graph.Data.Col.Dot)
    captureTemplate('graph_col', params.Graph.Data.Col)

    --] Visualize UI
    self.ui.Parent = game:GetService('Players').LocalPlayer.PlayerGui
    self.ui.Enabled = true

    return self
end

function bvui:renderParameters(param_data: {[number]: {[string]: number}})
    --] Generate Key Colors
    --#region
    local colors = {}
    for param_name: string in pairs(param_data[1]) do
        colors[param_name] = 
            self.param_color_cache[param_name]
            or Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))

        if not self.param_color_cache[param_name] then
            self.param_color_cache[param_name] = colors[param_name]
        end
    end
    --#endregion

    --] Generate Key UI
    --#region
    local ui_params = self.ui.Main.Parameters :: Frame
    local ui_key = ui_params.Key :: Frame

    --> Clear old(?)
    local data_length = #param_data
    for _, key_frame: TextLabel in pairs(ui_key:GetChildren()) do
        if not key_frame:IsA('TextLabel') then continue end
        if not colors[key_frame.Name] then
            key_frame:Destroy(); end

        --> Update
        key_frame.Text = `{key_frame.Name} ({trimDecimal(param_data[data_length][key_frame.Name])})`
    end

    --> Create new
    for param_name: string, color: Color3 in pairs(colors) do
        if ui_key:FindFirstChild(param_name) then continue end

        local new_key = self.templates.graph_key:Clone() :: TextLabel
        new_key.Name = param_name
        new_key.Text = `{param_name} ({trimDecimal(param_data[data_length][param_name])})`
        new_key.TextColor3 = color

        new_key.Parent = ui_key
    end
    --#endregion

    --] Generate Cols
    --#region
    local graph = ui_params.Graph :: Frame

    --> Cleanup
    for _, inst: Frame in pairs(graph.Data:GetChildren()) do
        --> Clear Lines
        if not inst:IsA('Frame') then
            if inst.Name=='Lines' then
                for _, l in pairs(inst:GetChildren()) do
                    inst:Destroy()
                end
            end
            continue
        end
    end

    --> Find Min/Max Values
    local min, max = math.huge, 0
    for _, delta_data in pairs(param_data) do
        for _, value in pairs(delta_data) do
            if value > max then max = value; continue end
            if value < min then min = value; continue end
        end
    end

    --> Pad Visuals
    local padding = (max*.2)
    local axis_y = graph.AxisY :: Frame
    axis_y.Min.Text = trimDecimal(min)
    axis_y.Max.Text = trimDecimal(max+padding)

    --> Draw Cols
    local function drawLines()
        --> Ensure Lines exists
        local lines = graph.Data:FindFirstChild('Lines')
        if not lines then
            lines = Instance.new('Folder', graph.Data)
            lines.Name = 'Lines'
        else
            --> Clean Lines
            for _, line in pairs(graph.Data.Lines:GetChildren()) do
                line:Destroy()
            end
        end

        --> Running Stitch
        local previous_dot = {}

        for _, this_col: Frame in pairs(graph.Data:GetChildren()) do
            if not this_col:IsA('Frame') then continue end
            local delta_id = this_col.LayoutOrder

            for _, this_dot in pairs(this_col:GetChildren()) do
                coroutine.wrap(function() 
                    if not this_dot:IsA('Frame') then return end
                    local param_name = this_dot.Name

                    local this_previous_dot = previous_dot[param_name]
                    if not this_previous_dot then previous_dot[param_name] = this_dot; return end

                    --> Connect lines
                    drawLine(
                        graph.Data,
                        this_previous_dot.AbsolutePosition+this_previous_dot.AbsoluteSize/2,
                        this_dot.AbsolutePosition+this_dot.AbsoluteSize/2,
                        2, colors[param_name]
                    ).Name=`{param_name}.{delta_id-1}-{delta_id}`
                    previous_dot[param_name] = this_dot
                end)()
            end
        end
    end

    for delta_id, delta_data in pairs(param_data) do
        if graph.Data:FindFirstChild(delta_id) then drawLines(); continue end

        local this_col = self.templates.graph_col:Clone() :: Frame
        this_col.LayoutOrder = delta_id
        this_col.Name = delta_id

        local index_t = this_col.Index
        if not canRenderIdx(delta_id, data_length) then 
            index_t:Destroy()
        else
            index_t.Text = tostring(delta_id)
        end

        --> Draw Dots
        for param_name, value in pairs(delta_data) do
            local this_dot = self.templates.graph_dot:Clone() :: Frame
            this_dot.BackgroundColor3 = colors[param_name]
            
            this_dot.Value.Text = trimDecimal(value)
            this_dot.Value.TextColor3 = colors[param_name]

            this_dot.Position = UDim2.new(.5, 0, 1-math.clamp((value-min)/(max-min), 0, 1), 0)
            this_dot.Name = param_name
            this_dot.Parent = this_col
        end

        this_col.Parent = graph.Data
    end

    --> Draw Lines
    drawLines()

    --#endregion

end

return bvui