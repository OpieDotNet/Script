--[[
    Lock-On Camera System
    Script único completo com UI profissional e lógica de targeting
    Coloque em StarterGui como LocalScript
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- CONSTANTES CONFIGURÁVEIS
local CONFIG = {
    CIRCLE_RADIUS = 120,           -- Raio do círculo em pixels
    SMOOTHING = 0.1,               -- Suavização da câmera (0-1, menor = mais suave)
    MAX_DISTANCE = 100,             -- Distância máxima do alvo em studs (opcional)
    CHECK_LOS = true,               -- Verificar linha de visão via Raycast
    DEBUG_MODE = false               -- Mostrar informações de debug
}

-- ESTADO DO SISTEMA
local lockOnActive = false
local currentTarget = nil
local connection = nil
local targetFilter = "Dummy"  -- Valor padrão

-- CRIAR UI PRINCIPAL
local function createUI()
    -- ScreenGui principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LockOnSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Frame principal com sombra
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Sombra (usando ImageLabel para efeito de sombra suave)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"  -- Sombra radial
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = mainFrame
    
    -- Cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Borda
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 90)
    stroke.Thickness = 1.5
    stroke.Parent = mainFrame
    
    -- Layout interno
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.Parent = mainFrame
    
    -- List layout para organizar verticalmente
    local listLayout = Instance.new("UIListLayout")
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = mainFrame
    
    -- TÍTULO
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "LOCK-ON SYSTEM"
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = mainFrame
    
    -- STATUS INDICATOR
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, 0, 0, 30)
    statusFrame.BackgroundTransparency = 1
    statusFrame.LayoutOrder = 2
    statusFrame.Parent = mainFrame
    
    local statusIcon = Instance.new("Frame")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(0, 12, 0, 12)
    statusIcon.Position = UDim2.new(0, 0, 0.5, -6)
    statusIcon.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    statusIcon.BorderSizePixel = 0
    statusIcon.Parent = statusFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = statusIcon
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -20, 1, 0)
    statusText.Position = UDim2.new(0, 20, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "INATIVO"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 16
    statusText.Parent = statusFrame
    
    -- FILTER INPUT
    local filterLabel = Instance.new("TextLabel")
    filterLabel.Size = UDim2.new(1, 0, 0, 20)
    filterLabel.BackgroundTransparency = 1
    filterLabel.Text = "Filtro de Alvo:"
    filterLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    filterLabel.TextXAlignment = Enum.TextXAlignment.Left
    filterLabel.Font = Enum.Font.Gotham
    filterLabel.TextSize = 14
    filterLabel.LayoutOrder = 3
    filterLabel.Parent = mainFrame
    
    local filterBox = Instance.new("TextBox")
    filterBox.Name = "FilterBox"
    filterBox.Size = UDim2.new(1, 0, 0, 35)
    filterBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    filterBox.PlaceholderText = "Ex: Dummy, Boss, Enemy"
    filterBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    filterBox.Text = targetFilter
    filterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    filterBox.Font = Enum.Font.Gotham
    filterBox.TextSize = 14
    filterBox.ClearTextOnFocus = false
    filterBox.LayoutOrder = 4
    filterBox.Parent = mainFrame
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = filterBox
    
    -- BOTÃO TOGGLE LOCK-ON
    local lockButton = Instance.new("TextButton")
    lockButton.Name = "LockButton"
    lockButton.Size = UDim2.new(1, 0, 0, 45)
    lockButton.BackgroundColor3 = Color3.fromRGB(66, 135, 245)
    lockButton.Text = "ATIVAR LOCK-ON"
    lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockButton.Font = Enum.Font.GothamBold
    lockButton.TextSize = 16
    lockButton.LayoutOrder = 5
    lockButton.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = lockButton
    
    -- CÍRCULO CENTRAL (invisível inicialmente)
    local centerCircle = Instance.new("ImageLabel")
    centerCircle.Name = "CenterCircle"
    centerCircle.Size = UDim2.new(0, CONFIG.CIRCLE_RADIUS * 2, 0, CONFIG.CIRCLE_RADIUS * 2)
    centerCircle.Position = UDim2.new(0.5, -CONFIG.CIRCLE_RADIUS, 0.5, -CONFIG.CIRCLE_RADIUS)
    centerCircle.BackgroundTransparency = 1
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
