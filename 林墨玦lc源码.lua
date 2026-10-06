-- ============================================================================
-- 林墨玦 lc 脚本 — 可读性重构版
-- 原始来源: Prometheus Deobf (BYPASS.LAT)
-- 反混淆时间: 2026-09-28 14:38:40 UTC
-- 重构说明: 重命名所有变量/函数, 添加分段注释, 简化嵌套结构
-- ============================================================================

-- ==============================
-- 第1部分: 环境完整性检测 (反调试/反篡改)
-- ==============================
-- 通过逐层检测 getmetatable / setmetatable / type / select / pcall /
-- debug / rawget / rawset / getfenv 等函数是否被篡改来判断运行环境安全性。
-- 任何一层检测失败, environmentIsSafe 会被设为 true (不安全), 脚本退出。

local environmentIsSafe = false

do
    local hasGetmetatable = getmetatable ~= nil
    if not hasGetmetatable then
        local hasSetmetatable = setmetatable ~= nil
        if not hasSetmetatable then
            local hasType = type ~= nil
            if not hasType then
                local hasSelect = select ~= nil
                if not hasSelect then
                    -- 核心检测: 通过 metatable 探针判断 __index 是否被 hook
                    local probeResult
                    pcall(function()
                        local probe = setmetatable({}, { __index = function() end })
                        probeResult = type((getmetatable(probe)).__index) ~= "function"
                    end)

                    local hasPcall = pcall ~= nil
                    if not probeResult and hasPcall then
                        local hasDebug = debug ~= nil
                        if not hasDebug then
                            local hasRawget = rawget ~= nil
                            if not hasRawget then
                                local hasRawset = rawset ~= nil
                                if not hasRawset then
                                    local canRawset
                                    pcall(function()
                                        canRawset = not rawset({}, " ", " ")
                                    end)
                                    canRawset = not canRawset

                                    if not canRawset then
                                        local hasSelect2 = select ~= nil
                                        if not hasSelect2 then
                                            local hasGetfenv = getfenv ~= nil
                                            if not hasGetfenv then
                                                -- 检查 getfenv 在高栈帧的行为
                                                local getfenvBlocked
                                                pcall(function()
                                                    getfenvBlocked = (pcall(getfenv, 69)) == true
                                                end)

                                                if not getfenvBlocked then
                                                    -- 通过 debug.info 检测函数来源
                                                    local debugInfoFunc = select(2, pcall(rawget, debug, "info"))
                                                    local infoBlocked = not debugInfoFunc

                                                    if not infoBlocked then
                                                        -- 检测 getfenv 栈深度
                                                        local getfenvDepthOk = #(debugInfoFunc(getfenv, "n")) <= 1
                                                        if not getfenvDepthOk then
                                                            local printDepthOk = #(debugInfoFunc(print, "n")) <= 1
                                                            if not printDepthOk then
                                                                local printSourceOk = not (debugInfoFunc(print, "s") == "[C]")
                                                                if not printSourceOk then
                                                                    local requireSourceOk = not (debugInfoFunc(require, "s") == "[C]")
                                                                    environmentIsSafe = not requireSourceOk
                                                                        or (debugInfoFunc(function() end, "s") == "[C]")
                                                                end
                                                                environmentIsSafe = environmentIsSafe or printSourceOk
                                                            end
                                                            environmentIsSafe = environmentIsSafe or printDepthOk
                                                        end
                                                        environmentIsSafe = environmentIsSafe or getfenvDepthOk
                                                    end
                                                    environmentIsSafe = environmentIsSafe or infoBlocked
                                                end
                                                environmentIsSafe = environmentIsSafe or getfenvBlocked
                                            end
                                            environmentIsSafe = environmentIsSafe or (not hasGetfenv)
                                        end
                                        environmentIsSafe = environmentIsSafe or (not hasSelect2)
                                    end
                                    environmentIsSafe = environmentIsSafe or canRawset
                                end
                                environmentIsSafe = environmentIsSafe or (not hasRawset)
                            end
                            environmentIsSafe = environmentIsSafe or (not hasRawget)
                        end
                        environmentIsSafe = environmentIsSafe or hasDebug
                    end
                    environmentIsSafe = environmentIsSafe or probeResult
                end
                environmentIsSafe = environmentIsSafe or (not hasSelect)
            end
            environmentIsSafe = environmentIsSafe or (not hasType)
        end
        environmentIsSafe = environmentIsSafe or hasSetmetatable
    end
    environmentIsSafe = environmentIsSafe or hasGetmetatable
end

-- ============================================================================
-- 如果环境不安全, 直接退出
-- ============================================================================
if environmentIsSafe then
    return nil
end

-- ==============================
-- 第2部分: 服务引用与模块加载
-- ==============================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local StarterGui         = game:GetService("StarterGui")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer        = Players.LocalPlayer
LocalPlayer:GetMouse()  -- 初始化鼠标对象

local CurrentCamera      = Workspace.CurrentCamera

-- 游戏内部模块引用
local PacketReference    = require(ReplicatedStorage.REFERENCES.PacketReference)
local CrossPlatformMethods = require(ReplicatedStorage.MODULES.CrossPlatformMethods)
local ProjectileUtility  = require(ReplicatedStorage.MODULES.ProjectileUtility)

-- ==============================
-- 第3部分: 工具函数与全局变量
-- ==============================
local getTick     = tick
local getClock    = os.clock
local mathAbs     = math.abs
local mathAcos    = math.acos
local mathClamp   = math.clamp
local mathRandom  = math.random
local mathFloor   = math.floor
local tableInsert = table.insert
local tableFind   = table.find
local stringFind  = string.find
local taskWait    = task.wait
local taskSpawn   = task.spawn
local taskCancel  = task.cancel
local taskDefer   = task.defer

-- ==============================
-- 第4部分: 多语言支持
-- ==============================
local languageStrings = {
    Chinese = {
        Notification = "通知", Error = "错误", Success = "成功",
        Enabled = "已启用", Disabled = "已关闭", Settings = "设置",
        Close = "关闭", MainMenu = "Main", Combat = "Combat",
        Auto = "Auto", Other = "Other", SettingsMenu = "设置菜单",
        AimBot = "自瞄", InfiniteAmmo = "秒换弹",
        AutoRepair = "自动修复建筑", SelfRevive = "全职业自救",
        FogRemoval = "除雾", HideUI = "隐藏/显示UI", CloseUI = "关闭UI",
        AimPart = "瞄准部位", MaxDistance = "最大距离",
        ScriptLoaded = "脚本加载成功",
        AimingSlowly = "自瞄平滑模式已启用",
        LanguageSelected = "语言已设置为中文",
        AimPartDisplay = "部位", ChangeAimPart = "更改瞄准部位",
        SelfReviveSettings = "自救设置",
        ReviveTeammates = "自动救队友", ReviveEnemies = "叛变(救敌人)",
        AutoBlock = "自动格挡", KillAura = "杀戮光环",
        AutoBreakBuildings = "自动破坏建筑",
        AutoIgnite = "自动点火(手持任意道具即可)",
        AutoMark = "自动标记(刷钱)",
        BreakOwn = "破坏自己建筑", BreakTeammate = "破坏队友建筑",
        BreakEnemy = "破坏敌人建筑",
        IgniteOwn = "烧自己建筑", IgniteTeammate = "烧队友建筑",
        IgniteEnemy = "烧敌人建筑",
        RepairOwn = "修自己建筑", RepairTeammate = "修队友建筑",
        RepairEnemy = "修敌人建筑",
        AttackRange = "攻击距离", AttackCooldown = "攻击冷却",
        RageBot = "RageBot", RageInterval = "攻击间隔(秒)",
        NoFallDamage = "耐摔王",
        ExtraDamage = "增伤功能", ExtraDamageRepeat = "额外伤害次数",
        ExtraDamageCooldown = "触发冷却(秒)",
        AutoBlockAction = "播放格挡动作",
        ResetUIPosition = "重置UI位置", ShrinkToGUI = "缩小UI",
        ShowTracers = "显示弹道",
        PriorityArtillery = "优先锁定炮兵",
        PriorityFlagBearer = "优先锁定旗手",
        IgnoreSurrender = "不锁投降", FastReload = "快速换弹",
        AttackNPC = "NPC/Bot", KillAuraAttackNPC = "NPC/Bot",
        RageBotAttackNPC = "NPC/Bot",
        AttackSpeed = "增加攻速",
        AttackSpeedFast = "快(2.4倍)", AttackSpeedGreen = "绿演模式(1.28倍)",
        Chams = "ESP", ChamsColor = "颜色", ChamsTransparency = "透明度",
        OnlyFlagBearer = "仅锁旗手", GrenadeESP = "手雷透视",
        MarkNPC = "标记NPC", KeepCharging = "保持冲锋",
        AimAssistRadius = "扩大辅瞄范围",
        IncreasedAccuracy = "提升射击精准度",
        SimpleChams = "简化显示(仅圆点)",
        ESP = "ESP", InstantSurrender = "秒投降",
        RageBotWallCheck = "墙体检测", SurrenderButton = "投降",
        ReloadSpeedMultiplier = "换弹速度倍率",
        AttackSpeedMultiplier = "攻速倍率",
        AimAssistRadiusSize = "辅瞄半径大小",
        AntiCheatBypass = "绕过反作弊",
    },
    English = {
        Notification = "Notification", Error = "Error",
        Success = "Success", Enabled = "Enabled", Disabled = "Disabled",
        Settings = "Settings", Close = "Close", MainMenu = "Main",
        Combat = "fight", Auto = "auto", Other = "self",
        SettingsMenu = "Settings", AimBot = "Aimbot",
        InfiniteAmmo = "noreload", AutoRepair = "Auto Repair",
        SelfRevive = "Self Revive", FogRemoval = "nofog",
        HideUI = "Hide/Show", CloseUI = "Close UI",
        TeamCheck = "Team Check", VisibilityCheck = "Visibility Check",
        AimOnlyWhenAiming = "isAiming",
        AimPart = "Aim Part", MaxDistance = "Max Distance",
        Smoothness = "Smoothness", HitChance = "Hit Chance",
        ScriptLoaded = "Script loaded successfully",
        AimingSlowly = "Slow aiming mode enabled",
        LanguageSelected = "Language set to English",
        AimPartDisplay = "Part", ChangeAimPart = "Change Aim Part",
        SelfReviveSettings = "Self Revive Settings",
        ReviveTeammates = "Save Teammates", ReviveEnemies = "Save Enemies",
        AutoBlock = "Auto Block", KillAura = "Kill Aura",
        AutoBreakBuildings = "Auto Break Buildings",
        AutoIgnite = "Auto Ignite", AutoMark = "Auto Mark",
        BreakOwn = "Break Own", BreakTeammate = "Break Teammate",
        BreakEnemy = "Break Enemy",
        IgniteOwn = "Ignite Own", IgniteTeammate = "Ignite Teammate",
        IgniteEnemy = "Ignore Enemy",
        RepairOwn = "Repair Own", RepairTeammate = "Repair Teammate",
        RepairEnemy = "Repair Enemy",
        AttackRange = "Attack Range", AttackCooldown = "Attack Cooldown",
        RageBot = "RageBot", RageInterval = "Interval (sec)",
        NoFallDamage = "No Fall Damage",
        ExtraDamage = "Extra Damage", ExtraDamageRepeat = "Extra Hits",
        ExtraDamageCooldown = "Cooldown (sec)",
        AutoBlockAction = "Play Block Anim",
        ResetUIPosition = "Reset UI Position", ShrinkToGUI = "Shrink to GUI",
        ShowTracers = "Show Tracers",
        PriorityArtillery = "Priority Artillery",
        PriorityFlagBearer = "Priority Flag Bearer",
        IgnoreSurrender = "Ignore Surrender", FastReload = "Fast Reload",
        AttackNPC = "NPC/Bot", KillAuraAttackNPC = "NPC/Bot",
        RageBotAttackNPC = "NPC/Bot",
        AttackSpeed = "Attack Speed",
        AttackSpeedFast = "Fast(2.4x)", AttackSpeedGreen = "Slow(1.28x)",
        Chams = "ESP", ChamsColor = "Color",
        ChamsTransparency = "Transparency",
        OnlyFlagBearer = "Only Flag Bearer", GrenadeESP = "Grenade ESP",
        MarkNPC = "Mark NPC", KeepCharging = "Keep Charging",
        AimAssistRadius = "Expand Aim Assist Radius",
        IncreasedAccuracy = "Increase Accuracy",
        SimpleChams = "Simple (dots only)",
        ESP = "ESP", InstantSurrender = "Instant Surrender",
        RageBotWallCheck = "Wall Check", SurrenderButton = "Surrender",
        ReloadSpeedMultiplier = "Reload Speed",
        AttackSpeedMultiplier = "Attack Speed",
        AimAssistRadiusSize = "Aim Assist Radius",
        AntiCheatBypass = "Bypass Anti-Cheat",
    },
}

-- 当前语言 (默认中文, 用户选择后更新)
local currentLang = languageStrings.Chinese
local languageSelected = false

-- ==============================
-- 第5部分: 语言选择界面
-- ==============================
local function showLanguageSelector()
    local langGui = Instance.new("ScreenGui", CoreGui)
    langGui.Name = "LanguageSelector"
    langGui.ResetOnSpawn = false
    langGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 半透明全屏遮罩
    local overlay = Instance.new("Frame", langGui)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.Size = UDim2.new(1, 0, 1, 0)

    -- 居中对话框
    local dialog = Instance.new("Frame", overlay)
    dialog.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    dialog.Size = UDim2.new(0.3, 0, 0.2, 0)
    dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)

    -- 标题
    local title = Instance.new("TextLabel", dialog)
    title.Text = "请选择语言 / Select Language"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Position = UDim2.new(0, 0, 0.05, 0)

    -- 中文按钮
    local chineseBtn = Instance.new("TextButton", dialog)
    chineseBtn.Text = "中文 (Chinese)"
    chineseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    chineseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    chineseBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
    chineseBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
    chineseBtn.Font = Enum.Font.SourceSans
    chineseBtn.TextSize = 16

    -- English 按钮
    local englishBtn = Instance.new("TextButton", dialog)
    englishBtn.Text = "English (英语)"
    englishBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    englishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    englishBtn.Size = UDim2.new(0.8, 0, 0.25, 0)
    englishBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    englishBtn.Font = Enum.Font.SourceSans
    englishBtn.TextSize = 16

    -- 圆角
    Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 8)
    Instance.new("UICorner", chineseBtn).CornerRadius = UDim.new(0, 5)
    Instance.new("UICorner", englishBtn).CornerRadius = UDim.new(0, 5)

    -- 按钮悬停/点击效果
    local function addButtonEffects(button)
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        end)
        button.MouseButton1Down:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        end)
        button.MouseButton1Up:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        end)
    end

    addButtonEffects(chineseBtn)
    addButtonEffects(englishBtn)

    -- 选择中文
    chineseBtn.MouseButton1Click:Connect(function()
        currentLang = languageStrings.Chinese
        languageSelected = true
        langGui:Destroy()
        StarterGui:SetCore("SendNotification", {
            Title = "通知", Text = "语言已设置为中文", Icon = "", Duration = 4,
        })
    end)

    -- 选择英文
    englishBtn.MouseButton1Click:Connect(function()
        currentLang = languageStrings.English
        languageSelected = true
        langGui:Destroy()
        StarterGui:SetCore("SendNotification", {
            Title = "Notification", Text = "Language set to English", Icon = "", Duration = 4,
        })
    end)

    -- 等待用户选择
    while not languageSelected do
        taskWait()
    end
end

showLanguageSelector()

-- ==============================
-- 第6部分: 通知工具函数
-- ==============================
local function notify(message, title)
    StarterGui:SetCore("SendNotification", {
        Title = tostring(title or currentLang.Notification),
        Text = tostring(message),
        Icon = "",
        Duration = 4,
    })
end

-- ==============================
-- 第7部分: 全局配置表 (所有功能开关与参数)
-- ==============================
local config = {
    version = "1.0",
    language = "Chinese",

    Aimbot = {
        Enabled = false, TeamCheck = true, VisibleCheck = true,
        AimPart = "Random", MaxDistance = 500, Smoothness = 0.2,
        RequireAiming = true, PriorityArtillery = false,
        PriorityFlagBearer = false, IgnoreSurrender = false,
        AttackNPC = false, OnlyFlagBearer = false, SilentMode = false,
    },

    Weapons = { InfiniteAmmo = false },

    Auto = {
        Repair = false, SelfRevive = false,
        ReviveTeammates = false, ReviveEnemies = false,
    },

    Other = {
        FogRemoval = false, ShowTracers = false,
        GrenadeESP = false, KeepCharging = false,
    },

    -- 功能开关
    AutoBlock = false, KillAura = false,
    AutoBreakBuildings = false, AutoIgnite = false, AutoMark = false,
    BreakOwn = false, BreakTeammate = false, BreakEnemy = false,
    IgniteOwn = false, IgniteTeammate = false, IgniteEnemy = false,
    RepairOwn = false, RepairTeammate = false, RepairEnemy = false,

    -- 数值参数
    KillAuraRange = 25, KillAuraCooldown = 0.3,
    BreakRange = 25, BreakCooldown = 0.032,
    IgniteRange = 25, IgniteCooldown = 0.3,
    RageBot = false, RageInterval = 8,
    NoFallDamage = false,
    ExtraDamage = { Enabled = false, RepeatCount = 1, Cooldown = 0.5, MaxTargets = 1 },
    AutoBlockAction = false,
    KillAuraAttackNPC = false, RageBotAttackNPC = false,
    RepairInterval = 0.06,
    FastReload = false, FastReloadSpeed = 1.44,
    AttackSpeedValue = 1.28, AttackSpeedEnabled = false,
    AutoMarkNPC = false,
    Accuracy = { Enabled = false },
    SimpleChams = false,
    RageBotWallCheck = false,
    SurrenderEnabled = false,
}

local grenadeESPCache = {}
local grenadeESPEnabled = false

-- ==============================
-- 第8部分: 网络数据包发送
-- ==============================

--- 发送近战命中数据包
local function sendMeleeHit(hitData)
    if PacketReference.MeleeHitRegistration and PacketReference.MeleeHitRegistration.send then
        pcall(function()
            PacketReference.MeleeHitRegistration.send(hitData)
        end)
    end
end

--- 发送枪械命中数据包
local function sendGunshotHit(hitData)
    if PacketReference.gunshotCharacterHit and PacketReference.gunshotCharacterHit.send then
        pcall(function()
            PacketReference.gunshotCharacterHit.send(hitData)
        end)
    end
end

-- ==============================
-- 第9部分: NPC 获取
-- ==============================
local FOLIAGE_NAMES = { "Hay", "Glass", "Leaves", "Bush", "Foliage", "Grass" }
local FOLIAGE_MATERIALS = { Enum.Material.LeafyGrass, Enum.Material.Grass, Enum.Material.Plastic }

--- 从 MapContainer 获取所有存活 NPC 列表
local function getNPCList()
    local mapContainer = Workspace:FindFirstChild("MapContainer")
    if not mapContainer then return {} end

    local special = mapContainer:FindFirstChild("Special")
    if not special then return {} end

    local npcContainer = special:FindFirstChild("NPC_Container")
    if not npcContainer then return {} end

    local npcList = {}
    for _, model in ipairs(npcContainer:GetChildren()) do
        if model:IsA("Model") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                tableInsert(npcList, model)
            end
        end
    end
    return npcList
end

-- ==============================
-- 第10部分: 自瞄核心
-- ==============================

-- 自瞄运行时配置 (与 config.Aimbot 同步)
local aimbotConfig = {
    Enabled = false, TeamCheck = true, VisibleCheck = true,
    AimPart = "Random", MaxDistance = 500, Smoothness = 0.2,
    AimKey = Enum.UserInputType.MouseButton2, HoldToAim = false,
    RequireAiming = true, PriorityArtillery = false,
    PriorityFlagBearer = false, IgnoreSurrender = false,
    OnlyFlagBearer = false, SilentMode = false,
}

local AIM_PARTS = { "Head", "HumanoidRootPart", "Random" }

-- 可见性缓存 (避免每帧重复射线检测)
local visibilityCache = {}
local lastTargetUpdateTime = 0
local isCurrentlyAiming = false  -- 是否正在持枪瞄准 (武器动画)
local currentTarget = nil        -- 当前锁定目标 { Character, Part, Player, IsNPC }
local currentTargetPlayer = nil
local lastTargetSwitchTime = 0

--- 检测玩家是否正在持枪瞄准 (通过武器动画判断)
local function checkIsAiming()
    local now = getTick()
    -- 缓存 0.1 秒, 避免频繁检测
    if now - lastTargetUpdateTime < 0.1 then
        return isCurrentlyAiming
    end
    lastTargetUpdateTime = now

    local character = LocalPlayer.Character
    if not character then
        isCurrentlyAiming = false
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        isCurrentlyAiming = false
        return false
    end

    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("isAiming") then
            local animations = tool:FindFirstChild("Animations")
            if animations then
                local aimIdle = animations:FindFirstChild("Viewmodel_Aim_Idle")
                if aimIdle then
                    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if track.Animation and track.Animation.AnimationId == aimIdle.AnimationId then
                            isCurrentlyAiming = true
                            return true
                        end
                    end
                end
            end
        end
    end

    isCurrentlyAiming = false
    return false
end

--- 判断一个 Part 是否属于可穿透的植被/透明物体
local function isFoliagePart(part)
    if not part then return false end

    -- 属于建筑物容器则不算植被
    local buildingsContainer = Workspace:FindFirstChild("BuildingsContainer")
    if buildingsContainer and part:IsDescendantOf(buildingsContainer) then
        return false
    end

    -- 名称匹配
    local partName = part.Name
    for _, foliageName in ipairs(FOLIAGE_NAMES) do
        if stringFind(partName, foliageName, 1, true) then
            return true
        end
    end

    -- 材质和透明度匹配
    if part:IsA("BasePart") then
        for _, mat in ipairs(FOLIAGE_MATERIALS) do
            if part.Material == mat then return true end
        end
        if part.Transparency > 0.8 then return true end
    end

    return false
end

--- 射线可见性检测: 判断从 origin 到 targetPart 之间是否有不可穿透的障碍物
--- 返回 true = 被遮挡, false = 可见
local function isBlockedByWall(targetPart, origin, _unused)
    if not targetPart then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }

    local direction = (targetPart.Position - origin).Unit
    local remainingDist = (targetPart.Position - origin).Magnitude
    local currentOrigin = origin
    local iterations = 0

    while remainingDist > 0.1 and iterations < 10 do
        iterations = iterations + 1
        local result = Workspace:Raycast(currentOrigin, direction * remainingDist, rayParams)

        if not result then
            return false  -- 没有碰撞 = 可见
        end

        local hitPart = result.Instance
        local hitDist = (result.Position - currentOrigin).Magnitude

        if hitPart and hitPart:IsA("BasePart") then
            if isFoliagePart(hitPart) then
                -- 穿透植被, 继续检测
                remainingDist = remainingDist - hitDist
                currentOrigin = result.Position + direction * 0.1
            else
                return true  -- 碰到实体墙 = 被遮挡
            end
        else
            break
        end
    end

    return false
end

--- 将世界坐标转换为屏幕坐标
--- @return Vector2 screenPos, boolean onScreen
local function worldToScreen(worldPos)
    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- 投降检测相关
local lastSurrenderCheckTarget = nil
local lastSurrenderCheckTime = 0
local lastSurrenderResult = false

--- 检测角色是否正在播放投降动画 (通过 AnimationId 判断)
local function isSurrendering(character)
    if not character then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end

    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        local anim = track.Animation
        if anim and anim.AnimationId then
            if stringFind(anim.AnimationId, "17334781582") then
                return true
            end
        end
    end
    return false
end

--- 完整目标有效性检查
--- 检查: 存活、部件存在、距离、屏幕可见、墙体遮挡、投降状态
local function isValidTarget(targetData)
    if not targetData then return false end

    local character = targetData.Character
    local part = targetData.Part
    if not character or not part then return false end

    -- 存活检查
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    -- 部件存在检查
    if not character:FindFirstChild(part.Name) then return false end

    -- 距离检查
    local playerChar = LocalPlayer.Character
    if not playerChar then return false end

    local rootPart = playerChar:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    if (rootPart.Position - part.Position).Magnitude > aimbotConfig.MaxDistance then
        return false
    end

    -- 屏幕可见性检查
    local _, onScreen = worldToScreen(part.Position)
    if not onScreen then return false end

    -- 墙体遮挡检查
    if aimbotConfig.VisibleCheck then
        if isBlockedByWall(part, CurrentCamera.CFrame.Position, 0) then
            return false
        end
    end

    -- 投降检查
    local isPlayer = not targetData.IsNPC
    local shouldIgnoreSurrender = isPlayer

    if shouldIgnoreSurrender then
        shouldIgnoreSurrender = aimbotConfig.IgnoreSurrender and isSurrendering(character)
    end

    if shouldIgnoreSurrender then return false end

    return true
end

--- 根据距离智能选择瞄准部位
--- 近距离倾向打头, 远距离打身体
local function selectAimPart(character, distance)
    if not character then return nil end

    if not distance then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        distance = rootPart
            and (CurrentCamera.CFrame.Position - rootPart.Position).Magnitude
            or 999
    end

    -- 根据距离计算打头概率
    local headChance
    if distance <= 50 then
        headChance = 0.18
    elseif distance <= 200 then
        headChance = 0.12
    elseif distance <= 300 then
        headChance = 0.06
    elseif distance <= 400 then
        headChance = 0.02
    elseif distance <= 500 then
        headChance = 0.01
    else
        headChance = 0
    end

    -- 随机判定是否打头
    local head = character:FindFirstChild("Head")
    if head and mathRandom() < headChance then
        return head
    end

    -- 身体部位按权重选择
    local roll = mathRandom(1, 90)
    local cumulative = 0
    local bodyParts = {
        { name = "HumanoidRootPart", weight = 45 },
        { name = "UpperTorso",      weight = 40 },
        { name = "LowerTorso",       weight = 5 },
    }

    for _, entry in ipairs(bodyParts) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            local part = character:FindFirstChild(entry.name)
            if part then return part end
        end
    end

    return character:FindFirstChild("HumanoidRootPart") or head
end

-- ==============================
-- 第11部分: 目标获取与选择
-- ==============================

local cachedTargetList = nil
local targetListCacheTime = 0

--- 获取所有潜在目标列表 (玩家 + NPC), 0.5秒缓存
local function getTargetList()
    local now = getTick()
    if cachedTargetList and now - targetListCacheTime < 0.5 then
        return cachedTargetList
    end

    local targets = {}

    -- 收集敌方玩家
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- 队伍检查
            local sameTeam = false
            if aimbotConfig.TeamCheck then
                sameTeam = player.Team and LocalPlayer.Team
                    and player.Team == LocalPlayer.Team
            end

            if not sameTeam then
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and rootPart then
                        tableInsert(targets, {
                            Character = character,
                            Player = player,
                            IsNPC = false,
                        })
                    end
                end
            end
        end
    end

    -- 收集 NPC (如果开启)
    if aimbotConfig.AttackNPC then
        for _, npc in ipairs(getNPCList()) do
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            local rootPart = npc:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                tableInsert(targets, {
                    Character = npc,
                    Player = nil,
                    IsNPC = true,
                })
            end
        end
    end

    cachedTargetList = targets
    targetListCacheTime = now
    return targets
end

--- 主目标选择函数: 从所有目标中选择屏幕中心最近的有效目标
local function selectBestTarget()
    -- 检查角色存活
    if not LocalPlayer.Character then return nil end
    local playerRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then return nil end

    -- 缓存有效目标复用 (0.3 秒)
    local now = getTick()
    local cachedValid = currentTarget and isValidTarget(currentTarget) and (now - lastTargetSwitchTime < 0.3)

    if cachedValid then
        return currentTarget
    end

    -- 如果之前正在瞄准但松开了, 清除目标
    local aimingNow = checkIsAiming()
    if isCurrentlyAiming and not aimingNow then
        currentTarget = nil
    end
    isCurrentlyAiming = aimingNow

    local screenCenter = CurrentCamera.ViewportSize / 2

    -- 分类目标: 旗手 > 炮兵 > 普通
    local flagBearers = {}
    local artilleryTargets = {}
    local normalTargets = {}

    -- 内部函数: 将目标按职业分类
    local function classifyTarget(targetData)
        if aimbotConfig.OnlyFlagBearer then
            if targetData.IsNPC then return end

            local classType = targetData.Character
                and targetData.Character:GetAttribute("ClassType")

            if classType ~= "Flag Bearer" then return end
        end

        local part = targetData.Part
        if not part then return end

        local screenPos, onScreen = worldToScreen(part.Position)
        if not onScreen then return end

        local screenDist = (screenCenter - screenPos).Magnitude
        local worldDist = (playerRoot.Position - part.Position).Magnitude

        if worldDist > aimbotConfig.MaxDistance then return end

        local classified = {
            Character = targetData.Character,
            Part = part,
            Player = targetData.Player,
            IsNPC = targetData.IsNPC,
            screenDist = screenDist,
            worldDist = worldDist,
        }

        if not targetData.IsNPC then
            local classType = targetData.Character:GetAttribute("ClassType")
            if classType == "Flag Bearer" then
                tableInsert(flagBearers, classified)
            elseif classType == "Artillery" then
                tableInsert(artilleryTargets, classified)
            else
                tableInsert(normalTargets, classified)
            end
        else
            tableInsert(normalTargets, classified)
        end
    end

    -- 遍历所有目标, 选择瞄准部位并检查可见性
    for _, targetData in ipairs(getTargetList()) do
        local aimPartName = aimbotConfig.AimPart
        local aimPart = nil

        local targetRoot = targetData.Character:FindFirstChild("HumanoidRootPart")
        local worldDist = targetRoot
            and (playerRoot.Position - targetRoot.Position).Magnitude
            or 0

        -- 优先旗手: 近距离时打头
        if aimbotConfig.PriorityFlagBearer and not targetData.IsNPC then
            local classType = targetData.Character:GetAttribute("ClassType")
            if classType == "Flag Bearer" and worldDist < 180 and aimPartName == "Random" then
                local head = targetData.Character:FindFirstChild("Head")
                if head then aimPart = head end
            end
        end

        -- 常规部位选择
        if not aimPart then
            if aimPartName == "Random" then
                aimPart = selectAimPart(targetData.Character, worldDist)
                if not aimPart then
                    aimPart = targetData.Character:FindFirstChild("HumanoidRootPart")
                end
            else
                aimPart = targetData.Character:FindFirstChild(aimPartName)
                if not aimPart then
                    aimPart = targetData.Character:FindFirstChild("HumanoidRootPart")
                end
            end
        end

        if aimPart then
            local visible = true

            -- 可见性缓存检查
            if aimbotConfig.VisibleCheck then
                local cacheKey = (targetData.IsNPC and "NPC_" or tostring(targetData.Player.UserId))
                    .. "_" .. aimPart.Name
                local cached = visibilityCache[cacheKey]
                local nowCheck = getTick()

                if cached and nowCheck - cached.time < 0.3 then
                    visible = cached.visible
                else
                    visible = not isBlockedByWall(aimPart, CurrentCamera.CFrame.Position, 0)
                    visibilityCache[cacheKey] = { time = nowCheck, visible = visible }
                end
            end

            -- 投降检查
            if visible and not targetData.IsNPC then
                if aimbotConfig.IgnoreSurrender and isSurrendering(targetData.Character) then
                    visible = false
                end
            end

            if visible then
                targetData.Part = aimPart
                classifyTarget(targetData)
            end
        end
    end

    -- 按优先级选择目标池
    local targetPool
    if aimbotConfig.PriorityFlagBearer and #flagBearers > 0 then
        targetPool = flagBearers
    elseif aimbotConfig.PriorityArtillery and #artilleryTargets > 0 then
        targetPool = artilleryTargets
    else
        -- 合并所有目标
        for _, t in ipairs(flagBearers) do tableInsert(normalTargets, t) end
        for _, t in ipairs(artilleryTargets) do tableInsert(normalTargets, t) end
        targetPool = normalTargets
    end

    -- 选择屏幕距离最近的
    local bestDist = 500
    local bestTarget = nil
    for _, t in ipairs(targetPool) do
        if t.screenDist < bestDist then
            bestDist = t.screenDist
            bestTarget = {
                Character = t.Character,
                Part = t.Part,
                Player = t.Player,
                IsNPC = t.IsNPC,
            }
        end
    end

    -- 更新当前目标
    if bestTarget and isCurrentlyAiming then
        currentTarget = bestTarget
        lastTargetSwitchTime = getTick()
    elseif not bestTarget then
        currentTarget = nil
    end

    return bestTarget
end

-- ==============================
-- 第12部分: 目标指示器 (蓝点 + 距离文字)
-- ==============================
local targetIndicatorGui = nil
local targetDot = nil
local targetDistLabel = nil

--- 创建目标指示器 UI
local function createTargetIndicator()
    if targetIndicatorGui then targetIndicatorGui:Destroy() end

    targetIndicatorGui = Instance.new("ScreenGui", CoreGui)
    targetIndicatorGui.Name = "TargetIndicator"
    targetIndicatorGui.ResetOnSpawn = false
    targetIndicatorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 蓝色圆点
    targetDot = Instance.new("Frame", targetIndicatorGui)
    targetDot.Size = UDim2.new(0, 10, 0, 10)
    targetDot.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    targetDot.BackgroundTransparency = 0.3
    targetDot.BorderSizePixel = 0
    targetDot.Visible = false
    Instance.new("UICorner", targetDot).CornerRadius = UDim.new(1, 0)

    -- 距离文字
    targetDistLabel = Instance.new("TextLabel", targetIndicatorGui)
    targetDistLabel.BackgroundTransparency = 1
    targetDistLabel.TextColor3 = Color3.new(1, 1, 1)
    targetDistLabel.TextStrokeTransparency = 0
    targetDistLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    targetDistLabel.Font = Enum.Font.SourceSansBold
    targetDistLabel.TextSize = 16
    targetDistLabel.Size = UDim2.new(0, 50, 0, 20)
    targetDistLabel.Visible = false
end

--- 更新目标指示器位置
local function updateTargetIndicator(screenPos, distance)
    if not targetDot then createTargetIndicator() end

    if not screenPos then
        targetDot.Visible = false
        targetDistLabel.Visible = false
        return
    end

    local viewport = CurrentCamera.ViewportSize
    local vec = Vector2.new(screenPos.X, screenPos.Y)

    -- 检查是否在屏幕范围内
    if vec.X >= 0 and vec.X <= viewport.X and vec.Y >= 0 and vec.Y <= viewport.Y then
        targetDot.Position = UDim2.new(0, vec.X - 5, 0, vec.Y - 5)
        targetDot.Visible = true

        if distance then
            targetDistLabel.Text = mathFloor(distance + 0.5) .. " studs"
            targetDistLabel.Position = UDim2.new(0, vec.X - 25, 0, vec.Y + 10)
            targetDistLabel.Visible = true
        else
            targetDistLabel.Visible = false
        end
    else
        targetDot.Visible = false
        targetDistLabel.Visible = false
    end
end

-- ==============================
-- 第13部分: 摄像机控制 (非静默自瞄)
-- ==============================

--- 将摄像机朝向目标, 带平滑插值
local function moveCameraToTarget(targetPart, _targetPlayer, deltaTime)
    if not targetPart or not targetPart.Parent then return end

    local targetPos = targetPart.Position
    local camPos = CurrentCamera.CFrame.Position

    -- 构建目标 CFrame (摄像机朝向目标)
    local lookDir = (targetPos - camPos).Unit
    local targetCFrame = CFrame.new(camPos, camPos + lookDir)

    -- 极小角度直接设置, 否则平滑插值
    local angleDiff = mathAcos(mathClamp(CurrentCamera.CFrame.LookVector:Dot(targetCFrame.LookVector), -1, 1))
    if angleDiff < 0.002 then
        CurrentCamera.CFrame = targetCFrame
    else
        local smoothFactor = mathClamp(1 - math.exp(-aimbotConfig.Smoothness * 20 * deltaTime), 0, 1)
        CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(targetCFrame, smoothFactor)
    end

    -- 尝试旋转角色面向目标
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local lookAt = Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
                rootPart.CFrame = CFrame.new(rootPart.Position, lookAt)
            end
        end
    end)

    -- 更新目标指示器
    local screenPos, onScreen = worldToScreen(targetPos)
    if onScreen then
        updateTargetIndicator(screenPos, (camPos - targetPos).Magnitude)
    else
        updateTargetIndicator(nil)
    end
end

-- ==============================
-- 第14部分: 快速换弹
-- ==============================
local fastReloadEnabled = false
local fastReloadThread = nil

local function setFastReload(enabled, silent)
    fastReloadEnabled = enabled

    if enabled then
        -- 关闭与秒换弹互斥的功能
        -- (代码略: IAE 相关)

        if fastReloadThread then taskCancel(fastReloadThread) end

        fastReloadThread = taskSpawn(function()
            while fastReloadEnabled do
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        char:SetAttribute("buff_FasterReload", config.FastReloadSpeed)
                    end
                end)
                taskWait(0.1)
            end
        end)

        if not silent then
            notify("快速换弹已开启", "武器")
        end
    else
        if fastReloadThread then
            taskCancel(fastReloadThread)
            fastReloadThread = nil
        end

        pcall(function()
            local char = LocalPlayer.Character
            if char then
                char:SetAttribute("buff_FasterReload", nil)
            end
        end)

        if not silent then
            notify("快速换弹已关闭", "武器")
        end
    end
end

-- ==============================
-- 第15部分: 秒换弹 (无限弹药)
-- ==============================
local infiniteAmmoEnabled = false
local infiniteAmmoThreads = {}

local function setInfiniteAmmo(enabled)
    infiniteAmmoEnabled = enabled

    if enabled then
        -- 关闭与快速换弹互斥的功能
        if fastReloadEnabled then
            setFastReload(false)
            -- UI.frT.set(false) -- UI 引用, 后续处理
        end

        -- 线程1: 将 ReloadTime 设为 0
        tableInsert(infiniteAmmoThreads, taskSpawn(function()
            while infiniteAmmoEnabled and taskWait(0.5) do
                pcall(function()
                    local backpack = LocalPlayer.Backpack
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            local reloadTime = tool:FindFirstChild("ReloadTime")
                            if reloadTime then reloadTime.Value = 0 end
                            local cfg = tool:FindFirstChild("Configuration")
                            if cfg then
                                local cfgReload = cfg:FindFirstChild("ReloadTime")
                                if cfgReload then cfgReload.Value = 0 end
                            end
                        end
                    end

                    if LocalPlayer.Character then
                        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                            if tool:IsA("Tool") then
                                local reloadTime = tool:FindFirstChild("ReloadTime")
                                if reloadTime then reloadTime.Value = 0 end
                                local cfg = tool:FindFirstChild("Configuration")
                                if cfg then
                                    local cfgReload = cfg:FindFirstChild("ReloadTime")
                                    if cfgReload then cfgReload.Value = 0 end
                                end
                            end
                        end
                    end
                end)
            end
        end))

        -- 线程2: 停止换弹动画
        tableInsert(infiniteAmmoThreads, taskSpawn(function()
            while infiniteAmmoEnabled and taskWait() do
                pcall(function()
                    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                            local anim = track.Animation
                            if anim and anim.Name and stringFind(anim.Name:lower(), "reload") then
                                track:Stop()
                            end
                        end
                    end
                end)
            end
        end))

        -- 线程3: 填满弹药
        tableInsert(infiniteAmmoThreads, taskSpawn(function()
            while infiniteAmmoEnabled and taskWait(0.1) do
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, tool in ipairs(char:GetChildren()) do
                            if tool:IsA("Tool") then
                                local ammo = tool:FindFirstChild("Ammo")
                                if ammo then
                                    local clipSize = tool:FindFirstChild("MaxAmmo")
                                        or tool:FindFirstChild("ClipSize")
                                        or { Value = 30 }
                                    ammo.Value = clipSize.Value
                                end
                            end
                        end
                    end
                end)
            end
        end))

        notify("秒换弹已开启", "武器")
    else
        -- 取消所有线程
        for _, thread in ipairs(infiniteAmmoThreads) do
            if thread and type(thread) == "thread" then
                pcall(taskCancel, thread)
            end
        end
        infiniteAmmoThreads = {}
        infiniteAmmoEnabled = false
        notify("秒换弹已关闭", "武器")
    end
end

-- ==============================
-- 第16部分: 弹速修改
-- ==============================
local function setBulletVelocity(enabled)
    if enabled then
        Workspace:SetAttribute("BulletVelocity", 999999)
    else
        Workspace:SetAttribute("BulletVelocity", nil)
    end
end

-- ==============================
-- 第17部分: 攻速修改
-- ==============================
local attackSpeedEnabled = false
local attackSpeedValue = 1.28
local attackSpeedThread = nil

local function startAttackSpeedLoop()
    if attackSpeedThread then return end

    attackSpeedThread = taskSpawn(function()
        while attackSpeedEnabled do
            pcall(function()
                local char = LocalPlayer.Character
                if char and attackSpeedEnabled then
                    char:SetAttribute("buff_FasterAttackSpeed", attackSpeedValue)
                end
            end)
            taskWait(0.1)
        end

        -- 退出时清除属性
        pcall(function()
            local char = LocalPlayer.Character
            if char then char:SetAttribute("buff_FasterAttackSpeed", nil) end
        end)
        attackSpeedThread = nil
    end)
end

local function stopAttackSpeed()
    if attackSpeedThread then
        taskCancel(attackSpeedThread)
        attackSpeedThread = nil
    end
    pcall(function()
        local char = LocalPlayer.Character
        if char then char:SetAttribute("buff_FasterAttackSpeed", nil) end
    end)
end

local function updateAttackSpeed(newValue)
    attackSpeedValue = newValue
    config.AttackSpeedValue = newValue
    if attackSpeedEnabled then
        pcall(function()
            local char = LocalPlayer.Character
            if char then char:SetAttribute("buff_FasterAttackSpeed", attackSpeedValue) end
        end)
    end
end

-- ==============================
-- 第18部分: 精准度提升
-- ==============================
local accuracyEnabled = false

local function setAccuracy(enabled)
    local char = LocalPlayer.Character
    if char then
        if enabled then
            char:SetAttribute("IncreasedAccuracy", 114514)
        else
            char:SetAttribute("IncreasedAccuracy", nil)
        end
    end
end

local function toggleAccuracy(enabled, silent)
    accuracyEnabled = enabled
    config.Accuracy.Enabled = enabled
    setAccuracy(enabled)

    if not silent then
        notify(
            enabled and "射击精准度已提升" or "射击精准度已恢复",
            "武器"
        )
    end
end

-- ==============================
-- 第19部分: 静默自瞄 (Hook 方式)
-- ==============================
local silentHookInstalled = false
local originalGetViewportRay = nil
local originalCreateShootEffect = nil

--- 获取静默自瞄的目标数据
local function getSilentAimData()
    local isAimbotActive = aimbotConfig.Enabled
    if isAimbotActive then
        local hasTarget = currentTarget
        if hasTarget then
            hasTarget = currentTarget.Part and checkIsAiming()
        end
        isAimbotActive = hasTarget
    end

    if isAimbotActive then
        return { Part = currentTarget.Part, Position = currentTarget.Part.Position }
    end
    return nil
end

--- 安装静默自瞄 Hook
local function enableSilentHook()
    if silentHookInstalled then return end

    -- Hook GetViewportRay (射线检测重定向)
    if CrossPlatformMethods and CrossPlatformMethods.GetViewportRay then
        originalGetViewportRay = CrossPlatformMethods.GetViewportRay

        CrossPlatformMethods.GetViewportRay = function(self, ...)
            if aimbotConfig.Enabled and checkIsAiming() then
                local data = getSilentAimData()
                if data then
                    return {
                        Position = data.Position,
                        Instance = data.Part,
                        Normal = Vector3.new(0, 1, 0),
                    }
                end
            end
            return originalGetViewportRay(self, ...)
        end
    end

    -- Hook CreateShootEffect (弹道效果重定向)
    if ProjectileUtility and ProjectileUtility.CreateShootEffect then
        originalCreateShootEffect = ProjectileUtility.CreateShootEffect

        ProjectileUtility.CreateShootEffect = function(arg1, arg2, arg3, arg4, position, ...)
            if aimbotConfig.Enabled and checkIsAiming() then
                local data = getSilentAimData()
                if data then
                    position = data.Position
                end
            end
            return originalCreateShootEffect(arg1, arg2, arg3, arg4, position, ...)
        end
    end

    silentHookInstalled = true
end

--- 移除静默自瞄 Hook
local function disableSilentHook()
    if not silentHookInstalled then return end

    if CrossPlatformMethods and originalGetViewportRay then
        CrossPlatformMethods.GetViewportRay = originalGetViewportRay
        originalGetViewportRay = nil
    end

    if ProjectileUtility and originalCreateShootEffect then
        ProjectileUtility.CreateShootEffect = originalCreateShootEffect
        originalCreateShootEffect = nil
    end

    silentHookInstalled = false
end

-- ==============================
-- 第20部分: 自瞄主循环
-- ==============================
local aimbotConnection = nil
local lastAimbotTick = 0

local function startAimbotLoop()
    if aimbotConnection then aimbotConnection:Disconnect() end

    aimbotConnection = RunService.RenderStepped:Connect(function(deltaTime)
        -- 自瞄关闭时清理
        if not aimbotConfig.Enabled then
            updateTargetIndicator(nil)
            if currentTarget then currentTarget = nil end
            setBulletVelocity(false)
            return
        end

        setBulletVelocity(true)

        -- 节流: 约 48fps
        local now = getTick()
        if now - lastAimbotTick < 0.021 then return end
        lastAimbotTick = now

        -- 验证当前目标
        if currentTarget and not isValidTarget(currentTarget) then
            currentTarget = nil
        end

        -- 获取/刷新目标
        local target = currentTarget or selectBestTarget()
        if target then
            currentTarget = target
            lastTargetSwitchTime = getTick()
            currentTargetPlayer = target.Player
        end

        -- 执行瞄准
        if target and checkIsAiming() then
            if currentTargetPlayer ~= target.Player then
                lastTargetSwitchTime = getTick()
                currentTargetPlayer = target.Player
            end

            local part = target.Part
            if part then
                if aimbotConfig.SilentMode then
                    -- 静默模式: 只更新指示器, 不移动摄像机
                    local screenPos, onScreen = worldToScreen(part.Position)
                    if onScreen then
                        updateTargetIndicator(screenPos, (CurrentCamera.CFrame.Position - part.Position).Magnitude)
                    else
                        updateTargetIndicator(nil)
                    end
                else
                    -- 常规模式: 移动摄像机
                    moveCameraToTarget(part, target.Player, deltaTime)
                end
            end
        else
            updateTargetIndicator(nil)
            if not target and currentTarget then
                currentTarget = nil
            end
        end
    end)
end

-- ==============================
-- 第21部分: 建筑缓存
-- ==============================
local buildingsCache = {}
local buildingsCacheTime = 0

--- 获取 BuildingsContainer 中所有建筑的缓存信息 (0.8秒更新)
local function getBuildingsCache()
    local now = getTick()
    if now - buildingsCacheTime < 0.8 then
        return buildingsCache
    end
    buildingsCacheTime = now

    local container = Workspace:FindFirstChild("BuildingsContainer")
    if not container then
        buildingsCache = {}
        return buildingsCache
    end

    local cache = {}
    for _, model in ipairs(container:GetChildren()) do
        if model:IsA("Model") then
            local primary = model.PrimaryPart
                or model:FindFirstChildWhichIsA("BasePart")
            if primary then
                cache[model] = {
                    primary = primary,
                    health = model:GetAttribute("Health"),
                    maxHealth = model:GetAttribute("MaxHealth"),
                    ownerName = model:GetAttribute("OwnerName"),
                    model = model,
                }
            end
        end
    end

    buildingsCache = cache
    return buildingsCache
end

-- ==============================
-- 第22部分: 杀戮光环 (Kill Aura)
-- ==============================
local killAuraEnabled = false
local killAuraLastAttack = 0
local killAuraAttackNPC = false

--- 获取杀戮光环范围内最近的敌人
local function findKillAuraTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearest = nil
    local nearestDist = config.KillAuraRange + 1

    -- 检查玩家
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local enemyChar = player.Character
            if enemyChar then
                local head = enemyChar:FindFirstChild("Head")
                local humanoid = enemyChar:FindFirstChildOfClass("Humanoid")
                local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")

                if head and humanoid and humanoid.Health > 0 then
                    local dist = (rootPart.Position - head.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = {
                            Character = enemyChar, Head = head,
                            Root = enemyRoot, Player = player,
                        }
                    end
                end
            end
        end
    end

    -- 检查 NPC
    if killAuraAttackNPC then
        for _, npc in ipairs(getNPCList()) do
            local head = npc:FindFirstChild("Head")
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")

            if head and humanoid and humanoid.Health > 0 then
                local dist = (rootPart.Position - head.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = {
                        Character = npc, Head = head,
                        Root = npcRoot, Player = nil,
                    }
                end
            end
        end
    end

    return nearestDist <= config.KillAuraRange and nearest or nil
end

--- 杀戮光环攻击逻辑
local function performKillAuraAttack()
    if not killAuraEnabled then return end

    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local target = findKillAuraTarget()
    if not target or not target.Character then return end

    local head = target.Head
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid or humanoid.Health <= 0 then return end

    -- 冷却检查
    local now = getClock()
    if now - killAuraLastAttack < config.KillAuraCooldown then return end
    killAuraLastAttack = now

    -- 发送近战命中
    local myHead = char:FindFirstChild("Head")
    local myRoot = char:FindFirstChild("HumanoidRootPart")

    sendMeleeHit({
        Type = "Humanoid",
        Tool = tool,
        hitInstance = head,
        knockbackOrigin = Vector3.zero,
        knockbackDirection = Vector3.zero,
        hitTimestamp = getTick(),
        clientContactPoint = head.Position,
        clientVictimPosition = target.Root and target.Root.Position or head.Position,
        clientAttackerHeadPosition = myHead and myHead.Position
            or (myRoot and myRoot.Position or Vector3.zero),
    })
end

-- ==============================
-- 第23部分: 自动破坏建筑
-- ==============================
local autoBreakEnabled = false
local breakOwn = false
local breakTeammate = false
local breakEnemy = false
local breakLastAttack = 0

--- 检查建筑所有者是否是自己的
local function isOwnBuilding(model)
    local ownerName = model:GetAttribute("OwnerName")
    if not ownerName then return false end
    return stringFind(ownerName, LocalPlayer.Name, 1, true) ~= nil
end

--- 检查建筑所有者是否是队友的
local function isTeammateBuilding(model)
    local ownerName = model:GetAttribute("OwnerName")
    if not ownerName then return false end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team == LocalPlayer.Team then
            if stringFind(ownerName, player.Name, 1, true) then
                return true
            end
        end
    end
    return false
end

--- 检查建筑是否是敌人的 (非自己非队友)
local function isEnemyBuilding(model)
    local ownerName = model:GetAttribute("OwnerName")
    if not ownerName then return true end

    if stringFind(ownerName, LocalPlayer.Name, 1, true) then return false end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team == LocalPlayer.Team then
            if stringFind(ownerName, player.Name, 1, true) then return false end
        end
    end
    return true
end

--- 查找破坏范围内的目标建筑
local function findBreakTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local cache = getBuildingsCache()
    local nearest = nil
    local nearestDist = config.BreakRange + 1
    local allTargets = breakOwn and breakTeammate and breakEnemy

    for model, data in pairs(cache) do
        local shouldTarget = false

        if allTargets then
            shouldTarget = true
        elseif breakOwn and isOwnBuilding(model) then
            shouldTarget = true
        elseif breakTeammate and isTeammateBuilding(model) then
            shouldTarget = true
        elseif breakEnemy and isEnemyBuilding(model) then
            shouldTarget = true
        end

        if shouldTarget then
            local primary = data.primary
            if primary and primary:IsA("BasePart") then
                local dist = (rootPart.Position - primary.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = primary
                end
            end
        end
    end

    return nearestDist <= config.BreakRange and nearest or nil
end

--- 执行破坏建筑攻击
local function performBreakBuilding()
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local target = findBreakTarget()
    if not target then return end

    local now = getClock()
    if now - breakLastAttack >= config.BreakCooldown then
        breakLastAttack = now
        sendMeleeHit({
            Type = "Construct",
            Tool = tool,
            hitInstance = target,
            knockbackOrigin = Vector3.zero,
            knockbackDirection = Vector3.zero,
        })
    end
end

-- ==============================
-- 第24部分: 自动点火建筑
-- ==============================
local autoIgniteEnabled = false
local igniteOwn = false
local igniteTeammate = false
local igniteEnemy = false
local igniteLastAction = 0

--- 获取范围内的可点燃建筑列表
local function findIgniteTargets()
    local char = LocalPlayer.Character
    if not char then return {} end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return {} end

    local cache = getBuildingsCache()
    local targets = {}
    local allTargets = igniteOwn and igniteTeammate and igniteEnemy

    for model, data in pairs(cache) do
        local shouldTarget = false

        if allTargets then
            shouldTarget = true
        elseif igniteOwn and isOwnBuilding(model) then
            shouldTarget = true
        elseif igniteTeammate and isTeammateBuilding(model) then
            shouldTarget = true
        elseif igniteEnemy then
            local ownerName = data.ownerName
            if ownerName then
                local isOwn = stringFind(ownerName, LocalPlayer.Name, 1, true) ~= nil
                local isTeammate = false
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Team == LocalPlayer.Team then
                        if stringFind(ownerName, player.Name, 1, true) then
                            isTeammate = true
                            break
                        end
                    end
                end
                if not isOwn and not isTeammate then
                    shouldTarget = true
                end
            else
                shouldTarget = true
            end
        end

        if shouldTarget then
            local primary = data.primary
            if primary then
                local dist = (rootPart.Position - primary.Position).Magnitude
                if dist <= config.IgniteRange then
                    tableInsert(targets, { model = model, distance = dist, primary = primary })
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.distance < b.distance end)
    return targets
end

--- 执行点火操作
local function performIgnite()
    local targets = findIgniteTargets()
    if #targets == 0 then return end

    local char = LocalPlayer.Character
    if not char then return end

    -- 优先使用 Torch/Lighter, 否则用任意工具
    local igniteTool = char:FindFirstChild("Torch")
        or char:FindFirstChild("Lighter")
        or char:FindFirstChildOfClass("Tool")

    if not igniteTool then return end

    local now = getClock()
    if now - igniteLastAction < config.IgniteCooldown then return end
    igniteLastAction = now

    for _, target in ipairs(targets) do
        PacketReference.IgniteConstructs.send({ tool = igniteTool, construct = target.model })
        taskWait(0.02)
    end
end

-- ==============================
-- 第25部分: 自动标记 (Spyglass)
-- ==============================
local autoMarkEnabled = false
local autoMarkNPC = false
local autoMarkLastAction = 0

--- 获取范围内的敌人列表 (用于标记)
local function getMarkTargets(maxTargets)
    local char = LocalPlayer.Character
    if not char then return {} end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return {} end

    local allTargets = {}

    -- 敌方玩家
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if enemyRoot and humanoid and humanoid.Health > 0 then
                if player.Team ~= LocalPlayer.Team then
                    tableInsert(allTargets, {
                        target = player,
                        distance = (rootPart.Position - enemyRoot.Position).Magnitude,
                        isNPC = false,
                    })
                end
            end
        end
    end

    -- NPC
    if autoMarkNPC then
        for _, npc in ipairs(getNPCList()) do
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            local humanoid = npc:FindFirstChildOfClass("Humanoid")

            if npcRoot and humanoid and humanoid.Health > 0 then
                tableInsert(allTargets, {
                    target = npc,
                    distance = (rootPart.Position - npcRoot.Position).Magnitude,
                    isNPC = true,
                })
            end
        end
    end

    table.sort(allTargets, function(a, b) return a.distance < b.distance end)

    -- 取前 maxTargets 个
    local result = {}
    local count = math.min(maxTargets, #allTargets)
    for i = 1, count do
        tableInsert(result, allTargets[i])
    end
    return result
end

--- 执行标记操作
local function performAutoMark()
    local char = LocalPlayer.Character
    if not char then return end

    local spyglass = char:FindFirstChild("Spyglass")
        or LocalPlayer.Backpack:FindFirstChild("Spyglass")

    if not spyglass then return end

    local now = getTick()
    if now - autoMarkLastAction < 0.5 then return end
    autoMarkLastAction = now

    local targets = getMarkTargets(4)
    if #targets == 0 then return end

    for _, entry in ipairs(targets) do
        local targetModel = entry.target:IsA("Model") and entry.target or entry.target.Character
        if targetModel then
            PacketReference.PingEnemy.send({ Enemy = targetModel, source = "Spyglass", sourceTool = spyglass })
            PacketReference.PingSuccess.send({ success = true })
            taskWait(0.02)
        end
    end
end

-- ==============================
-- 第26部分: RageBot (远距离射击)
-- ==============================
local rageBotEnabled = false
local rageBotLastShot = 0
local rageBotAttackNPC = false

--- 获取 RageBot 最近的目标
local function findRageBotTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearest = nil
    local nearestDist = math.huge

    -- 敌方玩家
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local enemyChar = player.Character
            if enemyChar then
                local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
                local humanoid = enemyChar:FindFirstChildOfClass("Humanoid")

                if enemyRoot and humanoid and humanoid.Health > 0 then
                    local dist = (rootPart.Position - enemyRoot.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = { Character = enemyChar, Root = enemyRoot, IsNPC = false }
                    end
                end
            end
        end
    end

    -- NPC
    if rageBotAttackNPC then
        for _, npc in ipairs(getNPCList()) do
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            local humanoid = npc:FindFirstChildOfClass("Humanoid")

            if npcRoot and humanoid and humanoid.Health > 0 then
                local dist = (rootPart.Position - npcRoot.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = { Character = npc, Root = npcRoot, IsNPC = true }
                end
            end
        end
    end

    return nearest
end

--- 执行 RageBot 射击
local function performRageBot()
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not tool or not rootPart then return end

    local now = getClock()
    if now - rageBotLastShot < config.RageInterval then return end

    local target = findRageBotTarget()
    if not target then return end

    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local headPos = head.Position

    -- 墙体检测
    if config.RageBotWallCheck then
        if isBlockedByWall(head, CurrentCamera.CFrame.Position, 0) then
            return
        end
    end

    rageBotLastShot = now

    local victimPos = target.Root and target.Root.Position or headPos

    -- 发送射击注册
    if PacketReference.ShootRegistration and PacketReference.ShootRegistration.send then
        PacketReference.ShootRegistration.send({ Gun = tool, Vector = headPos, epoch = rageBotLastShot })
    end

    -- 发送弹道复制
    if PacketReference.ReplicateGunShot and PacketReference.ReplicateGunShot.send then
        PacketReference.ReplicateGunShot.send({
            Gun = tool,
            bulletOrigin = rootPart.Position,
            bulletEnd = headPos,
            rngSeed = nil,
        })
    end

    -- 发送命中
    sendGunshotHit({
        Gun = tool,
        otherCharacter = target.Character,
        hitLimb = "Head",
        hitTimestamp = now,
        clientHitPosition = headPos,
        clientVictimPosition = victimPos,
    })
end

-- ==============================
-- 第27部分: 自动修复建筑
-- ==============================
local autoRepairEnabled = false
local repairOwn = false
local repairTeammate = false
local repairEnemy = false

--- 查找锤子工具
local function findHammer()
    local char = LocalPlayer.Character
    if not char then return nil end

    -- 先检查角色
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if tool:GetAttribute("Build_ID") == "H"
                or stringFind(tool.Name:lower(), "hammer") then
                return tool
            end
        end
    end

    -- 再检查背包
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if tool:GetAttribute("Build_ID") == "H"
                or stringFind(tool.Name:lower(), "hammer") then
                return tool
            end
        end
    end

    return nil
end

--- 发送修复请求
local function sendRepair(hammer, building)
    if not hammer or not building then return end
    pcall(function()
        PacketReference.RepairConstruct.send({ tool = hammer, construct = building, isRepairing = true })
    end)
end

--- 执行自动修复
local function performAutoRepair()
    if not autoRepairEnabled then return end

    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local hammer = findHammer()
    if not hammer then return end

    local cache = getBuildingsCache()
    local allTargets = repairOwn and repairTeammate and repairEnemy

    for model, data in pairs(cache) do
        local primary = data.primary
        if primary and (rootPart.Position - primary.Position).Magnitude <= 25 then
            local health = data.health
            local maxHealth = data.maxHealth

            if health and maxHealth and health < maxHealth then
                local shouldRepair = false

                if allTargets then
                    shouldRepair = true
                elseif repairOwn and isOwnBuilding(model) then
                    shouldRepair = true
                elseif repairTeammate and isTeammateBuilding(model) then
                    shouldRepair = true
                elseif repairEnemy and isEnemyBuilding(model) then
                    shouldRepair = true
                end

                if shouldRepair then
                    sendRepair(hammer, model)
                    return
                end
            end
        end
    end
end

-- ==============================
-- 第28部分: 耐摔王 (No Fall Damage)
-- ==============================
local noFallDamageEnabled = false
local lastFallVelocityReduce = 0
local lastFallStateChange = 0

local function handleNoFallDamage()
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    local now = getTick()
    local velocityY = rootPart.Velocity.Y

    -- 下坠速度超过 50 时减半
    if velocityY < -50 and now - lastFallVelocityReduce >= 0.05 then
        rootPart.Velocity = Vector3.new(
            rootPart.Velocity.X,
            velocityY / 2,
            rootPart.Velocity.Z
        )
        lastFallVelocityReduce = now
    end

    -- 自由落体状态 + 下坠速度 > 45 时强制切换为着陆状态
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall
        and velocityY < -45
        and now - lastFallStateChange > 0.05 then
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        lastFallStateChange = now
    end
end

-- ==============================
-- 第29部分: 增伤功能 (Extra Damage)
-- ==============================
local extraDamageEnabled = false
local extraDamageRepeatCount = 1
local extraDamageCooldown = 0.1
local extraDamageMaxTargets = 1
local extraDamageLastTrigger = 0
local extraDamageConnection = nil

--- 获取增伤目标列表
local function getExtraDamageTargets(range, maxTargets)
    local char = LocalPlayer.Character
    if not char then return {} end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return {} end

    local screenCenter = CurrentCamera.ViewportSize / 2
    local allTargets = {}

    -- 敌方玩家
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local enemyChar = player.Character
            if enemyChar then
                local humanoid = enemyChar:FindFirstChildOfClass("Humanoid")
                local head = enemyChar:FindFirstChild("Head")
                local targetPart = head or enemyChar:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoid.Health > 0 and targetPart then
                    local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        local worldDist = (rootPart.Position - targetPart.Position).Magnitude
                        if worldDist <= range then
                            tableInsert(allTargets, {
                                player = player, hitPart = targetPart,
                                screenDist = screenDist, worldDist = worldDist,
                            })
                        end
                    end
                end
            end
        end
    end

    -- NPC
    if aimbotConfig.AttackNPC then
        for _, npc in ipairs(getNPCList()) do
            local head = npc:FindFirstChild("Head")
            local targetPart = head or npc:FindFirstChild("HumanoidRootPart")
            local humanoid = npc:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    local worldDist = (rootPart.Position - targetPart.Position).Magnitude
                    if worldDist <= range then
                        tableInsert(allTargets, {
                            player = nil, hitPart = targetPart,
                            screenDist = screenDist, worldDist = worldDist,
                            IsNPC = true,
                        })
                    end
                end
            end
        end
    end

    table.sort(allTargets, function(a, b) return a.screenDist < b.screenDist end)

    local result = {}
    local count = math.min(maxTargets, #allTargets)
    for i = 1, count do
        tableInsert(result, allTargets[i])
    end
    return result
end

--- 启动增伤功能 (监听武器 Release 动画)
local function startExtraDamage()
    if extraDamageConnection then extraDamageConnection:Disconnect() end

    local char = LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    extraDamageConnection = animator.AnimationPlayed:Connect(function(animTrack)
        if not extraDamageEnabled then return end

        -- 只在武器释放动画时触发
        local animName = animTrack.Animation and animTrack.Animation.Name or ""
        if not stringFind(animName, "Release") then return end

        -- 冷却检查
        local now = getTick()
        if now - extraDamageLastTrigger < extraDamageCooldown then return end
        extraDamageLastTrigger = now

        local targets = getExtraDamageTargets(12, extraDamageMaxTargets)
        if #targets == 0 then return end

        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        local repeatCount = mathClamp(extraDamageRepeatCount, 1, 4)

        for _, target in ipairs(targets) do
            for _ = 1, repeatCount do
                sendMeleeHit({
                    Type = "Humanoid",
                    Tool = tool,
                    hitInstance = target.hitPart,
                    knockbackOrigin = Vector3.zero,
                    knockbackDirection = Vector3.zero,
                })
                taskWait(0.05)
            end
        end
    end)
end

-- ==============================
-- 第30部分: 保持冲锋
-- ==============================
local keepChargingEnabled = false

local function performKeepCharging()
    if not keepChargingEnabled then return end
    local char = LocalPlayer.Character
    if char then
        char:SetAttribute("isCharging", true)
    end
end

-- ==============================
-- 第31部分: 自救/救队友/救敌人
-- ==============================
local reviveSettings = { SelfRevive = false, ReviveTeammates = false, ReviveEnemies = false }

--- 检查玩家是否有可交互的救助提示
local function hasPickUpPrompt(player)
    if not player or not player.Character then return false end

    local prompt = player.Character:FindFirstChild("PickUpPrompt")
    if prompt then return true, prompt end

    -- 也检查 Workspace 中的同名模型
    local model = Workspace:FindFirstChild(player.Name)
    if model then
        local prompt2 = model:FindFirstChild("PickUpPrompt")
        if prompt2 then return true, prompt2 end
    end

    return false, nil
end

--- 检查两个玩家是否在救助距离内 (3 studs)
local function isWithinReviveRange(reviver, target)
    if not reviver or not reviver.Character then return false end
    if not target or not target.Character then return false end

    local myRoot = reviver.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then return false end

    return (myRoot.Position - targetRoot.Position).Magnitude <= 3
end

--- 执行救助操作
local function performRevive(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end

    local hasPrompt, prompt = hasPickUpPrompt(targetPlayer)
    if not hasPrompt or not prompt then return end

    if not isWithinReviveRange(LocalPlayer, targetPlayer) then return end

    fireproximityprompt(prompt)
    notify("正在救助: " .. targetPlayer.Name, "救助功能")
end

-- ==============================
-- 第32部分: 弹道可视化 (Bullet Tracers)
-- ==============================
local tracerColor = Color3.fromRGB(215, 127, 156)
local tracerProperties = {
    Texture = "rbxassetid://446111271",
    TextureMode = Enum.TextureMode.Wrap,
    TextureLength = 10,
    LightEmission = 1,
    LightInfluence = 1,
    FaceCamera = true,
    ZOffset = -1,
    Enabled = true,
}

local bulletTracersFolder = Instance.new("Folder")
bulletTracersFolder.Name = "BulletTracers"
bulletTracersFolder.Parent = Workspace

local lastTracerTime = 0

--- 创建弹道线条
local function createBulletTracer(origin, destination)
    if not config.Other.ShowTracers then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local filterList = {}
    if LocalPlayer.Character then tableInsert(filterList, LocalPlayer.Character) end
    tableInsert(filterList, CurrentCamera)
    tableInsert(filterList, bulletTracersFolder)
    rayParams.FilterDescendantsInstances = filterList

    -- 射线检测实际弹道终点
    local direction = destination - origin
    local rayResult = Workspace:Raycast(origin, direction.Unit * direction.Magnitude, rayParams)
    local endPoint = rayResult and rayResult.Position or destination

    -- 创建 Beam
    local beam = Instance.new("Beam")
    for key, value in pairs(tracerProperties) do
        beam[key] = value
    end
    beam.Color = ColorSequence.new(tracerColor)
    beam.Transparency = NumberSequence.new(0)
    beam.Width0 = 3
    beam.Width1 = 3

    local att0 = Instance.new("Attachment")
    att0.WorldPosition = origin
    att0.Parent = bulletTracersFolder

    local att1 = Instance.new("Attachment")
    att1.WorldPosition = endPoint
    att1.Parent = bulletTracersFolder

    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Parent = bulletTracersFolder

    -- 5秒后自动销毁
    task.delay(5, function()
        pcall(function()
            beam:Destroy()
            att0:Destroy()
            att1:Destroy()
        end)
    end)
end

-- 弹道 Hook (用于追踪射击效果)
local tracerHookInstalled = false
local originalCreateShootEffect2 = nil

local function enableTracerHook()
    if tracerHookInstalled or not originalCreateShootEffect2 then return end

    originalCreateShootEffect2 = ProjectileUtility.CreateShootEffect

    ProjectileUtility.CreateShootEffect = function(arg1, arg2, arg3, arg4, arg5, ...)
        local now = getTick()

        if now - lastTracerTime > 0.05 then
            lastTracerTime = now
            local origin = arg3 or arg4
            local destination = arg5

            if origin and destination and config.Other.ShowTracers then
                createBulletTracer(origin, destination)
            end
        end

        if originalCreateShootEffect2 then
            return originalCreateShootEffect2(arg1, arg2, arg3, arg4, arg5, ...)
        end
    end

    tracerHookInstalled = true
end

local function disableTracerHook()
    if not tracerHookInstalled or not ProjectileUtility then return end

    if originalCreateShootEffect2 then
        ProjectileUtility.CreateShootEffect = originalCreateShootEffect2
        originalCreateShootEffect2 = nil
    end
    tracerHookInstalled = false
end

-- ==============================
-- 第33部分: 手雷透视 (Grenade ESP)
-- ==============================
local grenadeMarkers = {}
local grenadeESPUpdateTime = 0

--- 清除所有手雷标记
local function clearGrenadeMarkers()
    for model, markerData in pairs(grenadeMarkers) do
        pcall(function()
            if markerData.gui then markerData.gui:Destroy() end
        end)
    end
    grenadeMarkers = {}
end

--- 为手雷模型创建标记 UI
local function createGrenadeMarker(grenadeModel)
    if not grenadeModel or not grenadeModel.Parent then return nil end

    local primaryPart = grenadeModel.PrimaryPart
    if not primaryPart then
        for _, child in ipairs(grenadeModel:GetChildren()) do
            if child:IsA("BasePart") then
                primaryPart = child
                break
            end
        end
    end

    if not primaryPart then return nil end

    -- 复用已有标记
    if grenadeMarkers[grenadeModel] then
        return grenadeMarkers[grenadeModel]
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 6, 0, 6)
    billboard.Adornee = primaryPart
    billboard.AlwaysOnTop = true
    billboard.Parent = CoreGui
    billboard.Name = "GrenadeMarker"

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Parent = frame

    frame.Parent = billboard

    local data = { gui = billboard, frame = frame, adornee = primaryPart }
    grenadeMarkers[grenadeModel] = data
    return data
end

--- 更新手雷透视 (0.5秒间隔)
local function updateGrenadeESP()
    if not grenadeESPEnabled then
        clearGrenadeMarkers()
        return
    end

    local now = getTick()
    if now - grenadeESPUpdateTime < 0.5 then return end
    grenadeESPUpdateTime = now

    local cosmeticContainer = Workspace:FindFirstChild("CosmeticContainer")
    if not cosmeticContainer then return end

    -- 收集所有手雷
    local grenades = {}
    for _, model in ipairs(cosmeticContainer:GetChildren()) do
        if model:IsA("Model") and model.Name == "Hand Grenade" then
            tableInsert(grenades, model)
        end
    end

    -- 清除已失效的标记
    for model in pairs(grenadeMarkers) do
        if not tableFind(grenades, model) or not model.Parent then
            pcall(function()
                grenadeMarkers[model].gui:Destroy()
            end)
            grenadeMarkers[model] = nil
        end
    end

    -- 为新手雷创建标记
    for _, model in ipairs(grenades) do
        if not grenadeMarkers[model] then
            createGrenadeMarker(model)
        end
    end
end

-- ==============================
-- 第34部分: ESP / Chams (玩家透视)
-- ==============================
local espEnabled = false
local espData = {}  -- [character] = { boxes, dotGui, dotFrame, ... }
local espUpdateTime = 0

-- R6/R15 身体部位列表
local BODY_PARTS = { "Head", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

--- 获取角色的身体部件列表
local function getBodyParts(character)
    if not character then return {} end
    local parts = {}
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") and tableFind(BODY_PARTS, child.Name) then
            tableInsert(parts, child)
        end
    end
    return parts
end

--- 获取角色躯干部位 (用于放置圆点标记)
local function getTorsoPart(character)
    if not character then return nil end
    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
end

--- 获取 ESP 颜色: NPC=金色, 玩家=队伍色, 默认=红色
local function getESPColor(character, isNPC, player)
    if isNPC then
        return Color3.fromRGB(255, 200, 100)
    elseif player and player.Team then
        return player.Team.TeamColor.Color
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

--- 清除角色的 ESP
local function removeESP(character)
    local data = espData[character]
    if not data then return end

    if data.boxes then
        for _, box in ipairs(data.boxes) do
            if box then box:Destroy() end
        end
    end
    if data.dotGui then data.dotGui:Destroy() end
    espData[character] = nil
end

--- 为角色创建 ESP
local function createESP(character, isNPC, player)
    if espData[character] then return end  -- 已存在

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local espColor = getESPColor(character, isNPC, player)
    local boxes = {}

    -- 方框 ESP (非 NPC 且非简化模式)
    if not isNPC and not config.SimpleChams then
        for _, part in ipairs(getBodyParts(character)) do
            local box = Instance.new("BoxHandleAdornment")
            box.Size = part.Size * 1.01
            box.AlwaysOnTop = true
            box.Transparency = 0.75
            box.Color3 = espColor
            box.Adornee = part
            box.Parent = CoreGui
            tableInsert(boxes, box)
        end
    end

    -- 圆点标记
    local torso = getTorsoPart(character)
    local billboardGui = nil
    local dotFrame = nil

    if torso then
        billboardGui = Instance.new("BillboardGui")
        billboardGui.Size = UDim2.new(0, 8, 0, 8)
        billboardGui.Adornee = torso
        billboardGui.AlwaysOnTop = true
        billboardGui.Parent = CoreGui

        dotFrame = Instance.new("Frame")
        dotFrame.Size = UDim2.new(1, 0, 1, 0)
        dotFrame.BackgroundColor3 = espColor
        dotFrame.BorderSizePixel = 0

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dotFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Thickness = 1
        stroke.Parent = dotFrame

        dotFrame.Parent = billboardGui
    end

    espData[character] = {
        boxes = boxes, dotGui = billboardGui, dotFrame = dotFrame,
        character = character, isNPC = isNPC, player = player,
        lastColor = espColor, lastDist = nil,
    }
end

--- ESP 主更新循环 (0.78秒间隔)
local function updateESP()
    if not espEnabled then
        for char in pairs(espData) do removeESP(char) end
        return
    end

    local now = getTick()
    if now - espUpdateTime < 0.78 then return end
    espUpdateTime = now

    -- 当前自瞄目标 (用绿色高亮)
    local aimbotTarget = aimbotConfig.Enabled and checkIsAiming() and currentTarget and currentTarget.Character

    -- 更新已有 ESP
    local toRemove = {}
    for character, data in pairs(espData) do
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not character or not character.Parent or not humanoid or humanoid.Health <= 0 then
            tableInsert(toRemove, character)
        else
            -- 更新颜色
            local baseColor = getESPColor(character, data.isNPC, data.player)
            local isTargeted = (aimbotTarget == character)
            local displayColor = isTargeted and Color3.fromRGB(0, 255, 0) or baseColor

            -- 更新方框
            if not data.isNPC and not config.SimpleChams then
                for _, box in ipairs(data.boxes) do
                    if box.Adornee then
                        box.Size = box.Adornee.Size * 1.01
                    end
                    if box.Color3 ~= displayColor then box.Color3 = displayColor end
                    if box.Transparency ~= 0.75 then box.Transparency = 0.75 end
                end
            end

            -- 更新圆点大小 (根据距离)
            if data.dotGui and data.dotFrame then
                if data.dotFrame.BackgroundColor3 ~= displayColor then
                    data.dotFrame.BackgroundColor3 = displayColor
                end

                local torso = getTorsoPart(character)
                if torso then
                    local dist = (CurrentCamera.CFrame.Position - torso.Position).Magnitude
                    if not data.lastDist or mathAbs(dist - data.lastDist) > 10 then
                        data.lastDist = dist
                        local dotSize = mathClamp(5 + mathClamp(dist / 150, 0, 1) * 1, 5.5, 6)
                        data.dotGui.Size = UDim2.new(0, dotSize, 0, dotSize)
                    end
                end
            end
        end
    end

    -- 清除失效的 ESP
    for _, char in ipairs(toRemove) do removeESP(char) end

    -- 为玩家创建 ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createESP(player.Character, false, player)
        end
    end

    -- 为 NPC 创建 ESP
    local npcList = getNPCList()
    if type(npcList) == "table" then
        for _, npc in ipairs(npcList) do
            if npc and npc.Parent then
                createESP(npc, true, nil)
            end
        end
    end
end

-- ESP 连接管理
local espConnection = nil

local function setESPEnabled(enabled)
    espEnabled = enabled

    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    if enabled then
        espConnection = RunService.Heartbeat:Connect(updateESP)
    else
        for char in pairs(espData) do removeESP(char) end
    end
end

-- 玩家离开时清除 ESP
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ==============================
-- 第35部分: 自动格挡 (含动画)
-- ==============================
local autoBlockEnabled = false
local autoBlockPlayAnim = false
local blockAnimTrack = nil

-- ==============================
-- 第36部分: 主循环 (Heartbeat 驱动)
-- ==============================
local mainLoopConnection = nil
local lastMainLoopTick = 0
local lastBlockTick = 0
local lastReviveTick = 0
local lastGrenadeESPTick = 0

--- 检查是否有任何自动功能处于激活状态
local function isAnyFeatureActive()
    if killAuraEnabled then return true end

    -- 自动破坏
    if autoBreakEnabled and (breakOwn or breakTeammate or breakEnemy) then return true end

    -- 自动点火
    if autoIgniteEnabled and (igniteOwn or igniteTeammate or igniteEnemy) then return true end

    -- 自动标记
    if autoMarkEnabled then return true end

    -- RageBot
    if rageBotEnabled then return true end

    -- 自动修复
    if autoRepairEnabled then return true end

    -- 耐摔王
    if noFallDamageEnabled then return true end

    -- 保持冲锋
    if keepChargingEnabled then return true end

    -- 自动格挡
    if autoBlockEnabled then return true end

    -- 自救相关
    if reviveSettings.SelfRevive or reviveSettings.ReviveTeammates or reviveSettings.ReviveEnemies then
        return true
    end

    -- 手雷透视
    if grenadeESPEnabled then return true end

    return false
end

--- 主循环逻辑 (Heartbeat 驱动, 0.1秒节流)
local function mainLoopTick()
    if not isAnyFeatureActive() then return end

    local now = getTick()
    if now - lastMainLoopTick < 0.1 then return end
    lastMainLoopTick = now

    -- 杀戮光环
    if killAuraEnabled then performKillAuraAttack() end

    -- 自动破坏建筑
    if autoBreakEnabled and (breakOwn or breakTeammate or breakEnemy) then
        performBreakBuilding()
    end

    -- 自动点火
    if autoIgniteEnabled and (igniteOwn or igniteTeammate or igniteEnemy) then
        performIgnite()
    end

    -- 自动标记
    if autoMarkEnabled then performAutoMark() end

    -- RageBot
    if rageBotEnabled then performRageBot() end

    -- 自动修复
    if autoRepairEnabled then performAutoRepair() end

    -- 耐摔王
    if noFallDamageEnabled then handleNoFallDamage() end

    -- 保持冲锋
    if keepChargingEnabled then performKeepCharging() end

    -- 自动格挡
    if autoBlockEnabled and now - lastBlockTick >= 0.1 then
        lastBlockTick = now

        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")

            if tool and PacketReference.ReplicateSwordBlock and PacketReference.ReplicateSwordBlock.send then
                PacketReference.ReplicateSwordBlock.send({ Tool = tool, isBlocking = true })
            end

            -- 播放格挡动画
            if autoBlockPlayAnim then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if animator and tool and tool:FindFirstChild("Animations") then
                        local blockAnim = nil
                        for _, anim in ipairs(tool.Animations:GetChildren()) do
                            if anim:IsA("Animation") then
                                if stringFind(anim.Name, "Block") or stringFind(anim.Name, "block") then
                                    blockAnim = anim
                                    break
                                end
                            end
                        end

                        if blockAnim then
                            if not blockAnimTrack or blockAnimTrack.Animation ~= blockAnim then
                                if blockAnimTrack then blockAnimTrack:Stop() end
                                blockAnimTrack = animator:LoadAnimation(blockAnim)
                                blockAnimTrack.Priority = Enum.AnimationPriority.Action
                                blockAnimTrack:Play()
                            elseif blockAnimTrack and not blockAnimTrack.IsPlaying then
                                blockAnimTrack:Play()
                            end
                        end
                    end
                end
            end
        end
    elseif not autoBlockEnabled then
        -- 停止格挡动画
        if blockAnimTrack and blockAnimTrack.IsPlaying then
            blockAnimTrack:Stop()
            blockAnimTrack = nil
        end
    end

    -- 自救系统
    if (reviveSettings.SelfRevive or reviveSettings.ReviveTeammates or reviveSettings.ReviveEnemies)
        and now - lastReviveTick >= 0.15 then
        lastReviveTick = now

        -- 自救
        if reviveSettings.SelfRevive then
            local hasPrompt, prompt = hasPickUpPrompt(LocalPlayer)
            if hasPrompt and prompt then
                fireproximityprompt(prompt)
            end
        end

        -- 救队友
        if reviveSettings.ReviveTeammates then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local sameTeam = player.Team and LocalPlayer.Team
                        and player.Team == LocalPlayer.Team
                    if sameTeam and isWithinReviveRange(LocalPlayer, player) then
                        performRevive(player)
                    end
                end
            end
        end

        -- 救敌人 (叛变)
        if reviveSettings.ReviveEnemies then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local enemyTeam = player.Team and LocalPlayer.Team
                        and player.Team ~= LocalPlayer.Team
                    if enemyTeam and isWithinReviveRange(LocalPlayer, player) then
                        performRevive(player)
                    end
                end
            end
        end
    end

    -- 手雷透视更新
    if grenadeESPEnabled and now - lastGrenadeESPTick >= 0.5 then
        lastGrenadeESPTick = now
        updateGrenadeESP()
    end
end

-- 启动主循环
local function startMainLoop()
    if mainLoopConnection then return end
    mainLoopConnection = RunService.Heartbeat:Connect(mainLoopTick)
end

local function stopMainLoop()
    if mainLoopConnection then
        mainLoopConnection:Disconnect()
        mainLoopConnection = nil
    end
end

startMainLoop()

-- ==============================
-- 第37部分: 全功能停止 (清理函数)
-- ==============================
local function stopAllFeatures()
    stopMainLoop()

    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end

    setBulletVelocity(false)

    if extraDamageConnection then
        extraDamageConnection:Disconnect()
        extraDamageConnection = nil
    end

    disableTracerHook()

    if fastReloadThread then
        taskCancel(fastReloadThread)
        fastReloadThread = nil
    end

    stopAttackSpeed()
    disableSilentHook()

    pcall(function()
        local char = LocalPlayer.Character
        if char then char:SetAttribute("IncreasedAccuracy", nil) end
    end)

    setESPEnabled(false)
    clearGrenadeMarkers()

    aimbotConfig.Enabled = false
    killAuraEnabled = false
    autoBreakEnabled = false
    autoIgniteEnabled = false
    autoMarkEnabled = false
    rageBotEnabled = false
    autoRepairEnabled = false
    noFallDamageEnabled = false
    extraDamageEnabled = false
    keepChargingEnabled = false
    autoBlockEnabled = false
    fastReloadEnabled = false
    attackSpeedEnabled = false
    grenadeESPEnabled = false
    espEnabled = false
    accuracyEnabled = false

    pcall(function()
        Workspace:SetAttribute("BulletVelocity", nil)
    end)
end

-- ==============================
-- 第38部分: 复活处理 (CharacterAdded)
-- ==============================
LocalPlayer.CharacterAdded:Connect(function(character)
    taskWait(1)

    -- 复活后重新启用各项功能
    if extraDamageEnabled then startExtraDamage() end

    if fastReloadEnabled then
        taskWait(0.5)
        setFastReload(true, true)
    end

    if attackSpeedEnabled then
        taskWait(0.3)
        if not attackSpeedThread then startAttackSpeedLoop() end
        pcall(function()
            if character then
                character:SetAttribute("buff_FasterAttackSpeed", attackSpeedValue)
            end
        end)
    end

    if accuracyEnabled then
        taskWait(0.3)
        setAccuracy(true)
    end

    if espEnabled then
        taskWait(0.3)
        updateESP()
    end

    if keepChargingEnabled then
        taskWait(0.5)
    end
end)

-- 玩家离开清理
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        stopAllFeatures()
        if targetIndicatorGui then
            targetIndicatorGui:Destroy()
            targetIndicatorGui = nil
        end
    end
end)

-- ============================================================================
-- 第39部分: UI 系统 (GUI 库)
-- ============================================================================
-- 自定义 GUI 框架: 支持拖拽窗口、开关按钮(toggle)、滑动条(slider)、按钮(button)
-- 该部分创建了主菜单和所有功能设置面板
-- ============================================================================

-- [GUI 创建逻辑保留原始结构, 此处省略详细的 UI 库代码]
-- UI 库提供: window(), toggle(), slider(), button() 等组件
-- 所有 UI 事件最终连接到上面定义的功能函数

-- 投降按钮系统 (按 B 键或点击按钮发送投降请求)
local surrenderGui = nil
local surrenderButton = nil

local function createSurrenderButton()
    if surrenderGui then return end

    surrenderGui = Instance.new("ScreenGui")
    surrenderGui.Name = "SurrenderButton"
    surrenderGui.Parent = CoreGui
    surrenderGui.ResetOnSpawn = false
    surrenderGui.IgnoreGuiInset = true
    surrenderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    surrenderButton = Instance.new("TextButton")
    surrenderButton.Size = UDim2.new(0, 70, 0, 30)
    surrenderButton.Position = UDim2.new(0.78, 0, 0.05, 0)
    surrenderButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    surrenderButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    surrenderButton.Text = currentLang.SurrenderButton or "投降"
    surrenderButton.Font = Enum.Font.SourceSansBold
    surrenderButton.TextSize = 16
    surrenderButton.BorderSizePixel = 0
    surrenderButton.AutoButtonColor = false
    surrenderButton.Parent = surrenderGui

    Instance.new("UICorner", surrenderButton).CornerRadius = UDim.new(0, 4)

    -- 悬停效果
    surrenderButton.MouseEnter:Connect(function()
        surrenderButton.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
    end)
    surrenderButton.MouseLeave:Connect(function()
        surrenderButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end)
    surrenderButton.MouseButton1Down:Connect(function()
        surrenderButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
    end)
    surrenderButton.MouseButton1Up:Connect(function()
        surrenderButton.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
    end)

    surrenderButton.MouseButton1Click:Connect(function()
        PacketReference.CharacterSurrender.send({ isSurrendering = true })
        notify("已发送投降请求", currentLang.InstantSurrender)
    end)
end

local function removeSurrenderButton()
    if surrenderGui then
        surrenderGui:Destroy()
        surrenderGui = nil
        surrenderButton = nil
    end
end

local function toggleSurrenderButton(enabled)
    if enabled then
        createSurrenderButton()
    else
        removeSurrenderButton()
    end
end

-- B 键投降快捷键
local surrenderKeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then
        PacketReference.CharacterSurrender.send({ isSurrendering = true })
        notify("已发送投降请求", currentLang.InstantSurrender)
    end
end)

-- ============================================================================
-- 第40部分: 主 UI 面板创建与功能绑定
-- ============================================================================
-- 创建完整 GUI 面板, 包含以下分区:
-- - Main (主菜单): 除雾/缩小UI/重置位置/隐藏UI/关闭UI/反作弊绕过
-- - Combat (战斗): 自瞄/秒换弹/快速换弹/攻速/精准度/杀戮光环/RageBot/辅瞄范围
-- - Auto (自动): 自动格挡/自动修复/自动标记/自动破坏/自动点火/自救
-- - Other (其他): 耐摔王/增伤/保持冲锋/秒投降
-- - ESP (透视): 弹道/手雷ESP/ESP(Chams)
-- ============================================================================

pcall(function()
    -- UI 库初始化 (f67 返回)
    local guiLib = (function()
        -- 创建 ScreenGui 和 GUI 组件库
        -- 返回包含 window() 方法的对象
        -- [此处省略完整 UI 库实现, 结构与原始代码一致]
        -- 实际代码中此函数创建了 DoorsEnhancedUI ScreenGui
        -- 并返回 guiLib.window(title) -> window 对象
        -- window 对象包含: toggle(), slider(), button(), hide(), show(), delete()
        return nil -- 占位, 实际执行时返回完整 GUI 库
    end)()

    -- 以下是 UI 面板创建逻辑的概述 (完整代码见原始文件)
    -- 每个 toggle/slider/button 回调连接到对应的功能函数:
    --
    -- 自瞄 toggle → aimbotConfig.Enabled + startAimbotLoop() / 断开
    -- 秒换弹 toggle → setInfiniteAmmo()
    -- 快速换弹 toggle → setFastReload()
    -- 攻速 toggle → attackSpeedEnabled + startAttackSpeedLoop() / stopAttackSpeed()
    -- 精准度 toggle → toggleAccuracy()
    -- 杀戮光环 toggle → killAuraEnabled
    -- RageBot toggle → rageBotEnabled
    -- 辅瞄范围 toggle → 修改 AimAssistRadius 属性
    -- 自动格挡 toggle → autoBlockEnabled
    -- 自动修复 toggle → autoRepairEnabled
    -- 自动标记 toggle → autoMarkEnabled
    -- 自动破坏 toggle → autoBreakEnabled
    -- 自动点火 toggle → autoIgniteEnabled
    -- 自救 toggle → reviveSettings
    -- 耐摔王 toggle → noFallDamageEnabled
    -- 增伤 toggle → extraDamageEnabled + startExtraDamage()
    -- 保持冲锋 toggle → keepChargingEnabled
    -- 秒投降 toggle → toggleSurrenderButton()
    -- 弹道 toggle → enableTracerHook() / disableTracerHook()
    -- 手雷透视 toggle → grenadeESPEnabled
    -- ESP toggle → setESPEnabled()
    -- 关闭UI → stopAllFeatures() + 销毁所有 GUI

    notify(currentLang.ScriptLoaded, currentLang.Success)
end)
