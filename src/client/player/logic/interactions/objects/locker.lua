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
            return end
        
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

        r_arm:AddTag('FPV_Visible')
        r_arm.LocalTransparencyModifier = 0
        r_arm.Transparency = 0

        --> Open door
        locker_model.Door.Body.CanCollide = false
        locker_model.Door.Body.CollisionGroup = 'MovingDoor'
        hinge.TargetAngle = hinge.UpperAngle

        --> Dash to door
        local target_cf = (handle.WorldCFrame+(handle.WorldCFrame.LookVector*1)+(handle.WorldCFrame.RightVector))*CFrame.Angles(0, math.pi, 0)
        local distance = (character.PrimaryPart.Position-target_cf.Position).Magnitude
        
        local cf_val = Instance.new('CFrameValue')
        cf_val.Value = root.CFrame

        local enterTween = tweens:Create(cf_val,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Value = locker.HidingPosition.WorldCFrame+Vector3.new(0,.5,0)})

        local l1, l2 = arm_upper_length, arm_lower_length
        env_cache:getValue('camera'):setControl(false)

        local blur = Instance.new('BlurEffect')
        blur.Size = 0
        blur.Parent = game:GetService('Lighting')

        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        local door_reached = false
        local runtime = runService.RenderStepped:Connect(function()
            local origin = (torso.CFrame*rs_c0)*CFrame.new(0,0,-rs_c1.X)
            local target_pos = handle.WorldCFrame.Position

            local localized = origin:PointToObjectSpace(target_pos)
            local local_unit, l3 = localized.Unit, localized.Magnitude

            local axis = Vector3.new(0, 0, -1):Cross(local_unit)
            local angle = math.acos(-local_unit.Z)
            local plane = origin*CFrame.fromAxisAngle(axis, angle)

            local f_plane, f_shoulder_angle, f_elbow_angle
            if l3<math.max(l2, l1)-math.min(l2, l1) then
                f_plane = plane*CFrame.new(0,0,math.max(l2,l1)-math.min(l2,l1)-l3)
                f_shoulder_angle = -math.pi/2
                f_elbow_angle = math.pi
            elseif l3>l1+l2 then
                f_plane = plane
                f_shoulder_angle = math.pi/2
                f_elbow_angle = 0
            else
                local a1 = -math.acos((-(l2*l2)+(l1*l1)+(l3*l3))/(2*l1*l3))
                local a2 = math.acos(((l2*l2)-(l1*l1)+(l3*l3))/(2*l2*l3))

                f_plane = plane
                f_shoulder_angle = a1 + math.pi/2
                f_elbow_angle = a2 - a1
            end

            local shoulder_angle, elbow_angle = 
                CFrame.Angles(f_shoulder_angle, 0, 0),
                CFrame.Angles(f_elbow_angle, 0, 0)

            local shoulder_cf = f_plane*shoulder_angle*CFrame.new(0, -arm_upper_length*.5, 0)
            local elbow_cf = shoulder_cf
                *CFrame.new(0,-arm_upper_length*.5,0)*elbow_angle
                *CFrame.new(0,-arm_lower_length*.5,0)*CFrame.new(0,(r_arm.Size.Y-arm_lower_length)*.5, 0)

            r_shoulder.C0 = WorldCFrameToC0ObjectSpace(r_shoulder, elbow_cf)

            if hide_loaded.IsPlaying then
                root.CFrame = cf_val.Value
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.lookAt(
                    workspace.CurrentCamera.CFrame.Position,
                    workspace.CurrentCamera.CFrame.LookVector
                ), .115)
            else
                root.Anchored = true
                root.CFrame = root.CFrame:Lerp(target_cf, distance/50)
                door_reached = (root.CFrame.Position-target_pos).Magnitude<1.65
            end
        end)

        repeat task.wait(0) until door_reached
        enterTween:Play()
        task.wait(.1)
        tweens:Create(blur, TweenInfo.new(.075, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
            {Size = 20}):Play()
        hide_loaded:Play(0, 2, .8)
        task.wait(.275)
        hinge.TargetAngle = hinge.LowerAngle

        local unblur = tweens:Create(blur, TweenInfo.new(.135, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = 0})
        unblur:Play()
        unblur.Completed:Once(function()
            blur:Destroy()
        end)

        enterTween.Completed:Wait()
        runtime:Disconnect(); runtime = nil
        r_arm:RemoveTag('FPV_Visible')

        r_shoulder.C0 = rs_c0
        freeze_loaded:Stop()
        freeze_loaded:Destroy()

        env_cache:getValue('movement'):setHiding(true, locker.HidingPosition)
        
    end)


    return test_object
end