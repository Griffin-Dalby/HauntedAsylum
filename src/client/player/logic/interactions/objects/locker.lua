--[[

    Locker Client Object

    Griffin Dalby
    2025.10.08

    This module will provide metadata for the locker objects.

--]]

--]] Services
local tweens = game:GetService('TweenService')
local runService = game:GetService('RunService')
local inputService = game:GetService('UserInputService')
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local interactable = require(replicatedStorage.Shared.Interactable)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Cache
local env_cache = cache.findCache('env')

--> Networking
local mechanics = networking.getChannel('mechanics')

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
            range = 15
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
        local hide_anim = Instance.new('Animation')
        hide_anim.AnimationId = 'rbxassetid://90622686444573'

        local animator = character:FindFirstChildOfClass('Humanoid'):FindFirstChildOfClass('Animator')
        local hide_loaded = animator:LoadAnimation(hide_anim)

        local locker_model = locker.Parent.Parent :: Model
        local hinge = locker_model.Frame.HingeWall.Hinge :: HingeConstraint
        local handle = locker_model['Door']['Body']['HandleAttachment'] :: Attachment

        --> Open door
        locker_model.Door.Body.CanCollide = false
        locker_model.Door.Body.CollisionGroup = 'MovingDoor'
        hinge.TargetAngle = hinge.UpperAngle

        --> Calculate target position and orientation
        local final_pos = locker.HidingPosition.WorldCFrame.Position + Vector3.new(0, 2, 0)
        
        local locker_forward = locker.HidingPosition.WorldCFrame.LookVector
        local locker_yaw = math.atan2(-locker_forward.X, -locker_forward.Z)
        
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
        local enterTween = tweens:Create(cf_val,
            TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Value = final_cf})
        
        cf_val:GetPropertyChangedSignal('Value'):Connect(function()
            workspace.CurrentCamera.CFrame = cf_val.Value
        end)

        local movement_c, camera_c = env_cache:getValue('movement', 'camera')

        movement_c:setSprint(false)
        movement_c:setCrouch(false)
        movement_c.is_hiding = true

        camera_c:setControl(false)

        local blur = Instance.new('BlurEffect')
        blur.Size = 0
        blur.Parent = game:GetService('Lighting')

        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        root.Anchored = true

        local move_speed = 18
        local close_threshold = 0.95
        local door_reached = false

        --> Move to approach position (outside door, facing handle)
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

        --> Enter the locker
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

        task.wait(.6)
        movement_c:setHiding(true, locker.HidingPosition)

        --> Wait for exit input
        local input_conn
        input_conn = inputService.InputBegan:Connect(function(key, gp)
            if gp or key.UserInputState~=Enum.UserInputState.Begin then return end
            if not table.find({Enum.KeyCode.Space,Enum.KeyCode.ButtonA}, key.KeyCode) then return end

            input_conn:Disconnect()
            input_conn = nil
            
            --> Disable hiding and open door
            movement_c:setHiding(false, locker.HidingPosition)
            hinge.TargetAngle = hinge.UpperAngle
            
            --> Blur and setup exit
            local exit_blur = Instance.new('BlurEffect')
            exit_blur.Size = 0
            exit_blur.Parent = game:GetService('Lighting')
            
            tweens:Create(exit_blur, TweenInfo.new(.075, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Size = 20}):Play()
            
            workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
            
            task.wait(0.15)
            
            --> Play exit animation
            local exit_anim = Instance.new('Animation')
            exit_anim.AnimationId = 'rbxassetid://90622686444573'
            local exit_loaded = animator:LoadAnimation(exit_anim)
            exit_loaded:Play(0, 2, -0.8)
            mechanics.hiding:with()
                :intent('exit_locker')
                :fire()
            
            --> Tween camera back out to approach position
            local exit_cf_val = Instance.new('CFrameValue')
            exit_cf_val.Value = final_cf
            
            local exitTween = tweens:Create(exit_cf_val,
                TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Value = approach_cf})
            
            exit_cf_val:GetPropertyChangedSignal('Value'):Connect(function()
                workspace.CurrentCamera.CFrame = exit_cf_val.Value
            end)
            
            exitTween:Play()
            
            task.wait(0.3)
            hinge.TargetAngle = hinge.LowerAngle

            --> Unblur
            local exit_unblur = tweens:Create(exit_blur, TweenInfo.new(.135, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
            exit_unblur:Play()
            exit_unblur.Completed:Once(function() exit_blur:Destroy() end)
            
            exitTween.Completed:Wait()
            
            -- Position player where the camera ended (at approach position)
            local final_exit_cf = exit_cf_val.Value
            local _, yaw, _ = final_exit_cf:ToOrientation()

            root.CFrame = CFrame.new(final_exit_cf.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, yaw, 0)
            
            exit_cf_val:Destroy()
            exit_loaded:Stop()
            exit_loaded:Destroy()
            
            --> Restore player control
            root.Anchored = false
            locker_model.Door.Body.CanCollide = true
            
            -- Store the camera's final orientation before switching
            local final_cam_cf = workspace.CurrentCamera.CFrame

            local pitch = math.deg(math.asin(-final_cam_cf.LookVector.Y))
            local yaw = math.deg(math.atan2(-final_cam_cf.LookVector.X, -final_cam_cf.LookVector.Z))

            camera_c.camera_angles = Vector2.new(-pitch, yaw)
            camera_c:setControl(true)
            movement_c.is_hiding = false
            test_prompt:enable()
        end)

    end)


    return test_object
end