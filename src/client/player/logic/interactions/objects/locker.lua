--[[

    Locker Client Object

    Griffin Dalby
    2025.10.08

    This module will provide metadata for the locker objects.

--]]

--]] Services
local tweens = game:GetService('TweenService')
local runService = game:GetService('RunService')
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local interactable = require(replicatedStorage.Shared.Interactable)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local env_cache = cache.findCache('env')

--]] Settings
local arm_upper_length = 1
local arm_lower_length = 1

--]] Constants
local players = game:GetService('Players')
local player = players.LocalPlayer

--]] Variables
--]] Functions
function WorldCFrameToC0ObjectSpace(motor6DJoint,worldCFrame)
	local part0 = motor6DJoint.Part0
	local stored_c1 = motor6DJoint.C1

	return part0.CFrame:inverse() * worldCFrame * stored_c1
end

--]] Locker

return function ()
    local test_object = interactable.newObject{
        object_id = 'locker',
        object_name = 'Locker',
        authorized = true,

        prompt_defs = {
            interact_gui = 'basic', --> See interactions.promptUis.basic
            interact_bind = { desktop = Enum.KeyCode.E, console = Enum.KeyCode.ButtonX },
            authorized = true,
            range = 45
        },

        instance = {workspace.environment.locker, {}},
    }

    local test_prompt = test_object:newPrompt{
        prompt_id = 'hide',
        action = 'Hide',
        cooldown = 1,

    }
    test_prompt.triggered:connect(function(_self, locker)
        test_prompt:disable()

        --> Index Character
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local root = humanoid.RootPart
        local torso = character:FindFirstChild('Torso')     :: Part
        local r_arm = character:FindFirstChild('Right Arm') :: Part

        local r_shoulder = torso['Right Shoulder'] :: Motor6D
        local rs_c0, rs_c1 = r_shoulder.C0, r_shoulder.C1

        if not r_arm then
            error(`[{script.Name}] Failed to find Right Arm to Open Locker!`)
            return 
        end
        
        --> Setup arm
        local freeze_anim = Instance.new('Animation')
        freeze_anim.AnimationId = 'rbxassetid://73497473931517'

        local hide_anim = Instance.new('Animation')
        hide_anim.AnimationId = 'rbxassetid://90622686444573'

        local animator = character:FindFirstChildOfClass('Humanoid'):FindFirstChildOfClass('Animator')
        local hide_loaded = animator:LoadAnimation(hide_anim)
        local freeze_loaded = animator:LoadAnimation(freeze_anim)
        freeze_loaded:Play()

        --> Arm IK behavior
        local locker_model = locker.Parent.Parent :: Model
        local hinge = locker_model.Frame.HingeWall.Hinge :: HingeConstraint
        local handle = locker_model['Door']['Body']['HandleAttachment'] :: Attachment

        --> Open door
        locker_model.Door.Body.CanCollide = false
        locker_model.Door.Body.CollisionGroup = 'MovingDoor'
        hinge.TargetAngle = hinge.UpperAngle

        --> Calculate target position and orientation
        -- Position where camera will end up (inside locker)
        local final_pos = locker.HidingPosition.WorldCFrame.Position + Vector3.new(0, 2, 0)
        
        -- Calculate locker's forward direction (where you'll be looking when hidden)
        local locker_forward = locker.HidingPosition.WorldCFrame.LookVector
        local locker_yaw = math.atan2(-locker_forward.X, -locker_forward.Z)
        
        -- Final camera orientation (looking straight ahead into locker)
        local final_cf = CFrame.new(final_pos) * CFrame.Angles(0, locker_yaw, 0)
        
        -- Initial approach target (facing the handle from outside)
        local handle_look_pos = handle.WorldCFrame.Position
        local approach_offset = (handle.WorldCFrame.LookVector*2.5) + (handle.WorldCFrame.RightVector*0.5) + (handle.WorldCFrame.UpVector*2)
        local approach_pos = handle_look_pos + approach_offset
        local approach_cf = CFrame.new(approach_pos, handle_look_pos)

        --> Setup camera tween
        local cf_val = Instance.new('CFrameValue')
        cf_val.Value = workspace.CurrentCamera.CFrame

        -- Tween goes from approach position to final hiding position
        -- This creates the "entering" motion
        local enterTween = tweens:Create(cf_val,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Value = final_cf})
        
        cf_val:GetPropertyChangedSignal('Value'):Connect(function()
            workspace.CurrentCamera.CFrame = cf_val.Value
        end)

        env_cache:getValue('camera'):setControl(false)

        local blur = Instance.new('BlurEffect')
        blur.Size = 0
        blur.Parent = game:GetService('Lighting')

        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        root.Anchored = true

        local move_speed = 18
        local close_threshold = 0.95
        local door_reached = false

        --> Phase 1: Move to approach position (outside door, facing handle)
        local to_door_runtime
        to_door_runtime = runService.RenderStepped:Connect(function(dt)
            if not hide_loaded.IsPlaying and not door_reached then
                local camPos = workspace.CurrentCamera.CFrame.Position
                local currDist = (camPos - approach_pos).Magnitude

                local alpha = math.min(move_speed * dt / math.max(currDist, 0.1), 0.95)
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(approach_cf, alpha)

                local newDist = (workspace.CurrentCamera.CFrame.Position - approach_pos).Magnitude
                if newDist <= close_threshold then
                    door_reached = true
                end
            end
        end)

        repeat task.wait() until door_reached
        if to_door_runtime then
            to_door_runtime:Disconnect()
            to_door_runtime = nil
        end

        --> Phase 2: Enter the locker
        -- Set camera to exact approach position before tweening
        workspace.CurrentCamera.CFrame = approach_cf
        cf_val.Value = approach_cf
        
        enterTween:Play()

        task.wait(0.15)
        tweens:Create(blur, TweenInfo.new(.075, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Size = 20}):Play()

        hide_loaded:Play(0, 2, .8)

        task.wait(.15)
        hinge.TargetAngle = hinge.LowerAngle

        local unblur = tweens:Create(blur, TweenInfo.new(.135, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
        unblur:Play()
        unblur.Completed:Once(function() blur:Destroy() end)

        enterTween.Completed:Wait()
        
        -- Ensure camera is at exact final position
        workspace.CurrentCamera.CFrame = final_cf
        cf_val:Destroy()

        --> Phase 3: Switch to constrained hiding mode
        freeze_loaded:Stop()
        freeze_loaded:Destroy()

        task.wait(.6)
        env_cache:getValue('movement'):setHiding(true, locker.HidingPosition)

    end)


    return test_object
end