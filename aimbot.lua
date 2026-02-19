--[[
    LOCK-ON PARA MURDER MYSTERY
    VERSÃO PARA EXECUTOR (Sem erros de compilação)
]]

-- Não usar local no escopo global do executor
_G.LockOnEnabled = false
_G.CurrentTarget = nil
_G.MurderChar = nil

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Função para encontrar o murder
function FindMurder()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local billboard = head:FindFirstChild("BillboardGui")
            if billboard then
                local nameTag = billboard:FindFirstChild("Name")
                if nameTag and nameTag.TextColor3 == Color3.new(1, 0, 0) then
                    return plr.Character
                end
            end
        end
    end
    return nil
end

-- Criar UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 60)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Cantos arredondados
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = mainFrame

-- Borda
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(80, 80, 90)
frameStroke.Thickness = 1
frameStroke.Parent = mainFrame

-- Botão de toggle
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 80, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0.5, -20)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggleButton.Text = "LOCK"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = toggleButton

-- Texto de status
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0, 80, 0, 40)
statusText.Position = UDim2.new(0, 100, 0.5, -20)
statusText.BackgroundTransparency = 1
statusText.Text = "OFF"
statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
statusText.Font = Enum.Font.GothamBold
statusText.TextSize = 16
statusText.Parent = mainFrame

-- Círculo de mira
local aimCircle = Instance.new("ImageLabel")
aimCircle.Name = "AimCircle"
aimCircle.Size = UDim2.new(0, 300, 0, 300)
aimCircle.Position = UDim2.new(0.5, -150, 0.5, -150)
aimCircle.BackgroundTransparency = 1
aimCircle.Image = "rbxassetid://2666670010"
aimCircle.ImageColor3 = Color3.fromRGB(255, 0, 0)
aimCircle.ImageTransparency = 0.7
aimCircle.Visible = false
aimCircle.Parent = screenGui

-- Função do botão
toggleButton.MouseButton1Click:Connect(function()
    _G.LockOnEnabled = not _G.LockOnEnabled
    aimCircle.Visible = _G.LockOnEnabled
    
    if _G.LockOnEnabled then
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusText.Text = "ON"
        statusText.TextColor3 = Color3.fromRGB(80, 255, 80)
        _G.MurderChar = FindMurder()
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        statusText.Text = "OFF"
        statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
        _G.CurrentTarget = nil
    end
end)

-- Hover effect
toggleButton.MouseEnter:Connect(function()
    TweenService:Create(toggleButton, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 85, 0, 43)
    }):Play()
end)

toggleButton.MouseLeave:Connect(function()
    TweenService:Create(toggleButton, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 80, 0, 40)
    }):Play()
end)

-- Função para verificar se alvo está na tela
function IsTargetInCircle(headPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
    if not onScreen then return false end
    
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    
    return distance <= 150
end

-- Loop principal
local frameCount = 0
RunService.RenderStepped:Connect(function()
    if not _G.LockOnEnabled then return end
    
    frameCount = frameCount + 1
    
    -- Atualizar murder a cada 3 frames (menos lag)
    if frameCount % 3 == 0 then
        if not _G.MurderChar or not _G.MurderChar.Parent then
            _G.MurderChar = FindMurder()
        end
    end
    
    -- Se tem murder, verificar se está no círculo
    if _G.MurderChar then
        local head = _G.MurderChar:FindFirstChild("Head")
        if head and IsTargetInCircle(head.Position) then
            _G.CurrentTarget = _G.MurderChar
            
            -- Mudar cor do círculo quando travar
            aimCircle.ImageColor3 = Color3.fromRGB(0, 255, 0)
        else
            _G.CurrentTarget = nil
            aimCircle.ImageColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
    
    -- Mover câmera para o alvo
    if _G.CurrentTarget then
        local head = _G.CurrentTarget:FindFirstChild("Head")
        if head then
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.15)
        end
    end
end)

-- Detectar quando murder morre
workspace.DescendantRemoving:Connect(function(desc)
    if desc == _G.MurderChar then
        _G.MurderChar = nil
        _G.CurrentTarget = nil
    end
end)

print("✅ Lock-On carregado! Pressione o botão LOCK para ativar.")        end
    end
    return nil
end

-- Criar UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockOnUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Botão
local button = Instance.new("TextButton")
button.Name = "LockButton"
button.Size = UDim2.new(0, 50, 0, 50)
button.Position = UDim2.new(0, 10, 0.5, -25)
button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
button.Text = "L"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.BorderSizePixel = 0
button.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(1, 0)
buttonCorner.Parent = button

-- Círculo
local circle = Instance.new("ImageLabel")
circle.Name = "TargetCircle"
circle.Size = UDim2.new(0, CIRCLE_RADIUS * 2, 0, CIRCLE_RADIUS * 2)
circle.Position = UDim2.new(0.5, -CIRCLE_RADIUS, 0.5, -CIRCLE_RADIUS)
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://2666670010"
circle.ImageColor3 = Color3.fromRGB(255, 50, 50)
circle.ImageTransparency = 0.6
circle.Visible = false
circle.Parent = screenGui

-- Animação do botão
button.MouseEnter:Connect(function()
    if not lockOnActive then
        TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 55, 0, 55)
        }):Play()
    end
end)

button.MouseLeave:Connect(function()
    if not lockOnActive then
        TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 50, 0, 50)
        }):Play()
    end
end)

-- Clique no botão
button.MouseButton1Click:Connect(function()
    lockOnActive = not lockOnActive
    circle.Visible = lockOnActive
    
    if lockOnActive then
        button.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
        button.Text = "✓"
        murderChar = findMurder()
    else
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        button.Text = "L"
        currentTarget = nil
    end
end)

-- Verificar se alvo está na tela
local function isTargetOnScreen(headPos)
    local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
    if not onScreen then return false end
    
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    
    return distance <= CIRCLE_RADIUS
end

-- Loop principal
RunService.RenderStepped:Connect(function()
    if not lockOnActive then return end
    
    frameCounter = frameCounter + 1
    if frameCounter % UPDATE_RATE ~= 0 then
        if currentTarget then
            local head = currentTarget:FindFirstChild("Head")
            if head then
                local targetCF = CFrame.lookAt(camera.CFrame.Position, head.Position)
                camera.CFrame = camera.CFrame:Lerp(targetCF, SMOOTHING)
            end
        end
        return
    end
    
    -- Atualizar murder se necessário
    if not murderChar or not murderChar.Parent then
        murderChar = findMurder()
    end
    
    if murderChar then
        local head = murderChar:FindFirstChild("Head")
        if head and isTargetOnScreen(head.Position) then
            currentTarget = murderChar
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end)

print("Lock-On carregado com sucesso!")    centerCircle.BackgroundTransparency = 1
    centerCircle.Image = "rbxassetid://2666670010"  -- Círculo vazado
    centerCircle.ImageColor3 = Color3.fromRGB(255, 255, 255)
    centerCircle.ImageTransparency = 0.5
    centerCircle.Visible = false
    centerCircle.Parent = screenGui
    
    -- Borda do círculo
    local circleStroke = Instance.new("UIStroke")
    circleStroke.Color = Color3.fromRGB(100, 200, 255)
    circleStroke.Thickness = 2
    circleStroke.Transparency = 0.3
    circleStroke.Parent = centerCircle
    
    -- Aspect Ratio Constraint para responsividade
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 1
    aspectRatio.Parent = centerCircle
    
    -- UIScale para responsividade
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = screenGui
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    return {
        screenGui = screenGui,
        mainFrame = mainFrame,
        lockButton = lockButton,
        filterBox = filterBox,
        centerCircle = centerCircle,
        statusIcon = statusIcon,
        statusText = statusText
    }
end

-- ANIMAÇÕES DO BOTÃO
local function setupButtonAnimations(button, uiElements)
    -- Hover
    button.MouseEnter:Connect(function()
        if not lockOnActive then
            local hoverTween = TweenService:Create(button, 
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(100, 160, 255), Size = UDim2.new(1, 0, 0, 48)}
            )
            hoverTween:Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not lockOnActive then
            local leaveTween = TweenService:Create(button, 
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(66, 135, 245), Size = UDim2.new(1, 0, 0, 45)}
            )
            leaveTween:Play()
        end
    end)
    
    -- Click
    button.MouseButton1Click:Connect(function()
        lockOnActive = not lockOnActive
        
        -- Atualizar UI
        uiElements.centerCircle.Visible = lockOnActive
        
        if lockOnActive then
            -- Ativar
            button.Text = "DESATIVAR LOCK-ON"
            uiElements.statusText.Text = "ATIVO"
            uiElements.statusIcon.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
            
            TweenService:Create(button, 
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}
            ):Play()
            
            -- Iniciar targeting
            startTargeting()
        else
            -- Desativar
            button.Text = "ATIVAR LOCK-ON"
            uiElements.statusText.Text = "INATIVO"
            uiElements.statusIcon.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            currentTarget = nil
            
            TweenService:Create(button, 
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(66, 135, 245), Size = UDim2.new(1, 0, 0, 45)}
            ):Play()
            
            -- Parar targeting
            stopTargeting()
        end
    end)
end

-- VERIFICAR SE ALVO É PERMITIDO
local function isTargetAllowed(target)
    local filter = targetFilter
    
    -- Verificar se é Player
    local character = target
    if target:IsA("Player") then
        character = target.Character
        if not character then return false end
        
        -- Verificar Attribute do servidor
        return character:GetAttribute("IsTarget") == true
    end
    
    -- Verificar por Attribute
    if character:GetAttribute("TargetType") == filter then
        return true
    end
    
    -- Verificar por CollectionService Tag
    if CollectionService:HasTag(character, filter) then
        return true
    end
    
    return false
end

-- ENCONTRAR MELHOR ALVO DENTRO DO CÍRCULO
local function findBestTarget()
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local bestDistance = CONFIG.CIRCLE_RADIUS
    
    -- Procurar por NPCs (Model) e Players
    local allTargets = {}
    
    -- Adicionar NPCs (Model com Humanoid)
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") then
            if isTargetAllowed(model) then
                table.insert(allTargets, model)
            end
        end
    end
    
    -- Adicionar Players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            if isTargetAllowed(plr) then
                table.insert(allTargets, plr.Character)
            end
        end
    end
    
    -- Analisar cada alvo
    for _, target in ipairs(allTargets) do
        local head = target:FindFirstChild("Head")
        if head then
            -- Verificar distância máxima
            if CONFIG.MAX_DISTANCE then
                local distance = (camera.CFrame.Position - head.Position).Magnitude
                if distance > CONFIG.MAX_DISTANCE then
                    continue
                end
            end
            
            -- Verificar linha de visão
            if CONFIG.CHECK_LOS then
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                rayParams.FilterDescendantsInstances = {player.Character, target}
                
                local rayResult = workspace:Raycast(
                    camera.CFrame.Position,
                    (head.Position - camera.CFrame.Position).Unit * CONFIG.MAX_DISTANCE,
                    rayParams
                )
                
                if rayResult then
                    continue  -- Obstruído
                end
            end
            
            -- Converter para posição de tela
            local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                
                if distanceFromCenter < bestDistance then
                    bestDistance = distanceFromCenter
                    bestTarget = target
                end
            end
        end
    end
    
    return bestTarget
end

-- INICIAR TARGETING LOOP
function startTargeting()
    if connection then
        connection:Disconnect()
    end
    
    connection = RunService.RenderStepped:Connect(function()
        if not lockOnActive then return end
        
        -- Atualizar filtro do TextBox
        local ui = getUI()
        if ui and ui.filterBox then
            targetFilter = ui.filterBox.Text
        end
        
        -- Encontrar melhor alvo
        local newTarget = findBestTarget()
        
        if newTarget then
            currentTarget = newTarget
            
            -- Apontar câmera para a cabeça do alvo
            local head = currentTarget:FindFirstChild("Head")
            if head then
                local targetCFrame = CFrame.lookAt(camera.CFrame.Position, head.Position)
                camera.CFrame = camera.CFrame:Lerp(targetCFrame, CONFIG.SMOOTHING)
            end
            
            -- Feedback visual no círculo
            if getUI() and getUI().centerCircle then
                getUI().centerCircle.ImageColor3 = Color3.fromRGB(100, 255, 100)
            end
        else
            currentTarget = nil
            -- Resetar cor do círculo
            if getUI() and getUI().centerCircle then
                getUI().centerCircle.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        
        -- Debug
        if CONFIG.DEBUG_MODE and currentTarget then
            print("Target: ", currentTarget.Name)
        end
    end)
end

function stopTargeting()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    currentTarget = nil
end

-- REFERÊNCIA GLOBAL PARA UI
local uiReference = nil

function getUI()
    return uiReference
end

-- INICIALIZAÇÃO
local function initialize()
    -- Criar UI
    uiReference = createUI()
    
    -- Configurar animações
    setupButtonAnimations(uiReference.lockButton, uiReference)
    
    -- Atualizar filtro quando o texto mudar
    uiReference.filterBox:GetPropertyChangedSignal("Text"):Connect(function()
        targetFilter = uiReference.filterBox.Text
    end)
    
    print("Lock-On System inicializado!")
end

-- Executar
initialize()
