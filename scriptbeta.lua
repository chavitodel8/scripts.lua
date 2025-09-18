local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
print("Jugador local detectado: " .. player.Name)

-- Esperar a que el personaje y el Humanoid estén listos
local character = player.Character
if not character then
	print("Esperando personaje...")
	character = player.CharacterAdded:Wait()
end
local humanoid = character:WaitForChild("Humanoid", 15)
if not humanoid then
	warn("Error: Humanoid no encontrado")
	return
end
print("Personaje y Humanoid cargados")

-- Variables para controlar los modos
local infiniteJumpEnabled = false
local seeThroughEnabled = false
local speedEnabled = false
local flyEnabled = false
local highlights = {}
local defaultWalkSpeed = humanoid.WalkSpeed -- Velocidad base (típicamente 16)
local speedValue = 50 -- Valor inicial del slider (1-100)
local bodyVelocity = nil -- Para el modo de vuelo
local teleportPoint = nil -- Para almacenar el punto de teletransporte

-- Configura la potencia del salto
humanoid.JumpPower = 50
print("JumpPower configurado a: " .. humanoid.JumpPower)

-- Crear el ScreenGui
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true -- Evita que la interfaz sea cortada por barras de navegación en móviles
gui.Parent = player:WaitForChild("PlayerGui", 15)
if not gui.Parent then
	warn("Error: PlayerGui no encontrado")
	return
end
gui.Name = "ControlGui"
print("ScreenGui creado en PlayerGui")

-- Burbuja flotante (ImageButton)
local bubbleButton = Instance.new("ImageButton")
bubbleButton.Size = UDim2.new(0, 60, 0, 60)
bubbleButton.Position = UDim2.new(0.9, -70, 0.9, -70) -- Esquina inferior derecha
bubbleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
bubbleButton.BackgroundTransparency = 0.3
bubbleButton.Image = "rbxassetid://0" -- Sin imagen, solo color
bubbleButton.BorderSizePixel = 0
bubbleButton.Parent = gui

-- Bordes redondeados para la burbuja
local bubbleCorner = Instance.new("UICorner")
bubbleCorner.CornerRadius = UDim.new(0.5, 0) -- Círculo perfecto
bubbleCorner.Parent = bubbleButton

-- Icono en la burbuja
local bubbleLabel = Instance.new("TextLabel")
bubbleLabel.Size = UDim2.new(1, 0, 1, 0)
bubbleLabel.BackgroundTransparency = 1
bubbleLabel.Text = "+"
bubbleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bubbleLabel.TextSize = 40
bubbleLabel.Font = Enum.Font.GothamBold
bubbleLabel.Parent = bubbleButton
print("Burbuja flotante creada")

-- Panel con botones
local panelFrame = Instance.new("Frame")
panelFrame.Size = UDim2.new(0, 220, 0, 350) -- Aumentado para nuevos botones
panelFrame.Position = UDim2.new(0, 10, 0.5, -175) -- A la izquierda, centrado verticalmente
panelFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panelFrame.BackgroundTransparency = 0.2
panelFrame.BorderSizePixel = 0
panelFrame.Visible = false
panelFrame.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panelFrame
print("Panel creado")

-- Hacer el panel arrastrable desde cualquier punto
local draggingPanel = false
local panelDragStart = Vector2.new(0, 0)
local panelStartPos = nil
local function startPanelDrag(input)
	draggingPanel = true
	panelDragStart = input.Position
	panelStartPos = panelFrame.Position
end
local function endPanelDrag()
	draggingPanel = false
end
local function updatePanel(input)
	if draggingPanel and panelStartPos then
		local delta = input.Position - panelDragStart
		local newX = math.clamp(panelStartPos.X.Offset + delta.X, 0, gui.AbsoluteSize.X - panelFrame.Size.X.Offset)
		local newY = math.clamp(panelStartPos.Y.Offset + delta.Y, 0, gui.AbsoluteSize.Y - panelFrame.Size.Y.Offset)
		panelFrame.Position = UDim2.new(0, newX, 0, newY)
	end
end

panelFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		startPanelDrag(input)
	end
end)
panelFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		updatePanel(input)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and draggingPanel then
		endPanelDrag()
	end
end)

-- Botón para salto infinito
local jumpButton = Instance.new("TextButton")
jumpButton.Size = UDim2.new(0, 180, 0, 40)
jumpButton.Position = UDim2.new(0, 20, 0, 20)
jumpButton.Text = "Salto Infinito: OFF"
jumpButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
jumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpButton.Font = Enum.Font.Gotham
jumpButton.TextSize = 16
jumpButton.Parent = panelFrame

local jumpCorner = Instance.new("UICorner")
jumpCorner.CornerRadius = UDim.new(0, 8)
jumpCorner.Parent = jumpButton
print("Botón de salto creado")

-- Botón para ver a través
local seeThroughButton = Instance.new("TextButton")
seeThroughButton.Size = UDim2.new(0, 180, 0, 40)
seeThroughButton.Position = UDim2.new(0, 20, 0, 70)
seeThroughButton.Text = "Ver a Través: OFF"
seeThroughButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
seeThroughButton.TextColor3 = Color3.fromRGB(255, 255, 255)
seeThroughButton.Font = Enum.Font.Gotham
seeThroughButton.TextSize = 16
seeThroughButton.Parent = panelFrame

local seeThroughCorner = Instance.new("UICorner")
seeThroughCorner.CornerRadius = UDim.new(0, 8)
seeThroughCorner.Parent = seeThroughButton
print("Botón de ver a través creado")

-- Botón para correr rápido
local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 180, 0, 40)
speedButton.Position = UDim2.new(0, 20, 0, 120)
speedButton.Text = "Correr Rápido: OFF"
speedButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.Font = Enum.Font.Gotham
speedButton.TextSize = 16
speedButton.Parent = panelFrame

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 8)
speedCorner.Parent = speedButton
print("Botón de correr rápido creado")

-- Botón para volar
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0, 180, 0, 40)
flyButton.Position = UDim2.new(0, 20, 0, 170)
flyButton.Text = "Volar: OFF"
flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.Gotham
flyButton.TextSize = 16
flyButton.Parent = panelFrame

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyButton
print("Botón de volar creado")

-- Botón para agregar punto de teletransporte
local setTeleportButton = Instance.new("TextButton")
setTeleportButton.Size = UDim2.new(0, 180, 0, 40)
setTeleportButton.Position = UDim2.new(0, 20, 0, 220)
setTeleportButton.Text = "Agregar Punto TP"
setTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
setTeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
setTeleportButton.Font = Enum.Font.Gotham
setTeleportButton.TextSize = 16
setTeleportButton.Parent = panelFrame

local setTeleportCorner = Instance.new("UICorner")
setTeleportCorner.CornerRadius = UDim.new(0, 8)
setTeleportCorner.Parent = setTeleportButton
print("Botón de agregar punto TP creado")

-- Botón para teletransportarse
local doTeleportButton = Instance.new("TextButton")
doTeleportButton.Size = UDim2.new(0, 180, 0, 40)
doTeleportButton.Position = UDim2.new(0, 20, 0, 270)
doTeleportButton.Text = "Hacer TP"
doTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
doTeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
doTeleportButton.Font = Enum.Font.Gotham
doTeleportButton.TextSize = 16
doTeleportButton.Parent = panelFrame

local doTeleportCorner = Instance.new("UICorner")
doTeleportCorner.CornerRadius = UDim.new(0, 8)
doTeleportCorner.Parent = doTeleportButton
print("Botón de hacer TP creado")

-- Slider para velocidad
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0, 180, 0, 20)
sliderFrame.Position = UDim2.new(0, 20, 0, 320)
sliderFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
sliderFrame.BorderSizePixel = 0
sliderFrame.Parent = panelFrame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 5)
sliderCorner.Parent = sliderFrame

local sliderHandle = Instance.new("TextButton")
sliderHandle.Size = UDim2.new(0, 20, 1, 0)
sliderHandle.Position = UDim2.new((speedValue - 1) / 100, 0, 0, 0)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderHandle.Text = ""
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderFrame

local sliderHandleCorner = Instance.new("UICorner")
sliderHandleCorner.CornerRadius = UDim.new(0, 5)
sliderHandleCorner.Parent = sliderHandle

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(0, 180, 0, 20)
sliderLabel.Position = UDim2.new(0, 20, 0, 345)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "Velocidad: " .. speedValue
sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextSize = 14
sliderLabel.Parent = panelFrame
print("Slider creado")

-- Función para actualizar la velocidad (para correr y volar)
local function updateSpeed()
	if speedEnabled and humanoid and not flyEnabled then
		humanoid.WalkSpeed = defaultWalkSpeed + (speedValue * 1) -- 16 a 116
		print("Velocidad de carrera actualizada a: " .. humanoid.WalkSpeed)
	elseif flyEnabled and humanoid then
		if bodyVelocity then
			print("Velocidad de vuelo configurada para valor: " .. speedValue)
		end
	else
		humanoid.WalkSpeed = defaultWalkSpeed
		print("Velocidad restaurada a: " .. defaultWalkSpeed)
	end
	sliderLabel.Text = "Velocidad: " .. speedValue
end

-- Manejar el arrastre del slider (PC y móvil)
local draggingSlider = false
local function startSliderDrag()
	draggingSlider = true
end
local function endSliderDrag()
	draggingSlider = false
end
local function updateSlider(input)
	if draggingSlider then
		local inputPos = input.Position.X
		local framePos = sliderFrame.AbsolutePosition.X
		local frameSize = sliderFrame.AbsoluteSize.X
		local relativePos = math.clamp((inputPos - framePos) / frameSize, 0, 1)
		speedValue = math.floor(relativePos * 99) + 1 -- 1 a 100
		sliderHandle.Position = UDim2.new(relativePos, 0, 0, 0)
		updateSpeed()
	end
end

sliderHandle.MouseButton1Down:Connect(startSliderDrag)
sliderHandle.TouchTap:Connect(startSliderDrag) -- Soporte para toque en móvil
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endSliderDrag()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		updateSlider(input)
	end
end)

-- Hacer la burbuja arrastrable (PC y móvil)
local draggingBubble = false
local bubbleDragStart = Vector2.new(0, 0)
local bubbleStartPos = bubbleButton.Position
local function startBubbleDrag()
	draggingBubble = true
	bubbleDragStart = UserInputService:GetMouseLocation() or UserInputService:GetTouchPosition()
	bubbleStartPos = bubbleButton.Position
end
local function endBubbleDrag()
	draggingBubble = false
end
local function updateBubble(input)
	if draggingBubble then
		local inputPos = input.Position or input.Position
		local delta = inputPos - bubbleDragStart
		bubbleButton.Position = UDim2.new(
			bubbleStartPos.X.Scale,
			bubbleStartPos.X.Offset + delta.X,
			bubbleStartPos.Y.Scale,
			bubbleStartPos.Y.Offset + delta.Y
		)
	end
end

bubbleButton.MouseButton1Down:Connect(startBubbleDrag)
bubbleButton.TouchTap:Connect(startBubbleDrag) -- Soporte para toque en móvil
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endBubbleDrag()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		updateBubble(input)
	end
end)

-- Mostrar/ocultar el panel al presionar la burbuja
bubbleButton.MouseButton1Click:Connect(function()
	panelFrame.Visible = not panelFrame.Visible
	print("Panel " .. (panelFrame.Visible and "mostrado" or "oculto"))
end)
bubbleButton.TouchTap:Connect(function()
	panelFrame.Visible = not panelFrame.Visible
	print("Panel " .. (panelFrame.Visible and "mostrado" or "oculto"))
end)

-- Función para manejar el vuelo
local function updateFly()
	if flyEnabled and humanoid and character then
		if not bodyVelocity then
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
			humanoid.PlatformStand = true
			print("Modo de vuelo iniciado")
		end
		local moveDirection = Vector3.new(0, 0, 0)
		local camera = Workspace.CurrentCamera
		local flySpeed = speedValue * 0.5 -- Escalar de 0.5 a 50

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDirection = moveDirection + camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDirection = moveDirection - camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDirection = moveDirection + camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDirection = moveDirection - camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDirection = moveDirection + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			moveDirection = moveDirection - Vector3.new(0, 1, 0)
		end

		bodyVelocity.Velocity = moveDirection * flySpeed
	elseif bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = speedEnabled and (defaultWalkSpeed + (speedValue * 1)) or defaultWalkSpeed
		print("Modo de vuelo desactivado")
	end
end

-- Función para salto infinito
local function onJumpRequest()
	if infiniteJumpEnabled and humanoid and not flyEnabled then
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		print("Salto infinito ejecutado")
	end
end

-- Función para alternar salto infinito
local function toggleInfiniteJump()
	infiniteJumpEnabled = not infiniteJumpEnabled
	jumpButton.Text = "Salto Infinito: " .. (infiniteJumpEnabled and "ON" or "OFF")
	jumpButton.BackgroundColor3 = infiniteJumpEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
	print("Salto infinito: " .. (infiniteJumpEnabled and "Activado" or "Desactivado"))
end

-- Función para agregar Highlight a un personaje o NPC
local function addHighlight(model)
	if model and model ~= player.Character and model:FindFirstChildOfClass("Humanoid") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "SeeThroughHighlight"
		highlight.FillTransparency = 0.2
		highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.Adornee = model
		highlight.Parent = model
		highlights[model] = highlight
		print("Highlight añadido a: " .. model.Name)
	else
		print("No se añadió Highlight: modelo inválido o es el jugador local")
	end
end

-- Función para remover Highlights
local function removeHighlights()
	for model, highlight in pairs(highlights) do
		if highlight then
			highlight:Destroy()
			print("Highlight removido de: " .. model.Name)
		end
	end
	highlights = {}
end

-- Función para alternar ver a través
local function toggleSeeThrough()
	seeThroughEnabled = not seeThroughEnabled
	seeThroughButton.Text = "Ver a Través: " .. (seeThroughEnabled and "ON" or "OFF")
	seeThroughButton.BackgroundColor3 = seeThroughEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
	print("Ver a través: " .. (seeThroughEnabled and "Activado" or "Desactivado"))

	if seeThroughEnabled then
		local players = Players:GetPlayers()
		print("Jugadores detectados: " .. #players)
		for _, otherPlayer in pairs(players) do
			if otherPlayer ~= player and otherPlayer.Character then
				addHighlight(otherPlayer.Character)
			end
		end
		for _, model in pairs(Workspace:GetDescendants()) do
			if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and model ~= player.Character then
				addHighlight(model)
			end
		end
	else
		removeHighlights()
	end
end

-- Función para alternar correr rápido
local function toggleSpeed()
	speedEnabled = not speedEnabled
	speedButton.Text = "Correr Rápido: " .. (speedEnabled and "ON" or "OFF")
	speedButton.BackgroundColor3 = speedEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
	print("Correr rápido: " .. (speedEnabled and "Activado" or "Desactivado"))
	updateSpeed()
end

-- Función para alternar volar
local function toggleFly()
	flyEnabled = not flyEnabled
	flyButton.Text = "Volar: " .. (flyEnabled and "ON" or "OFF")
	flyButton.BackgroundColor3 = flyEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
	print("Volar: " .. (flyEnabled and "Activado" or "Desactivado"))
	updateFly()
end

-- Función para guardar punto de teletransporte
local function setTeleportPoint()
	if character and character:FindFirstChild("HumanoidRootPart") then
		teleportPoint = character.HumanoidRootPart.CFrame
		setTeleportButton.Text = "Punto TP Guardado"
		setTeleportButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		wait(2)
		setTeleportButton.Text = "Agregar Punto TP"
		setTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		print("Punto de teletransporte guardado en: " .. tostring(teleportPoint.Position))
	else
		warn("No se pudo guardar el punto: personaje no encontrado")
	end
end

-- Función para teletransportarse
local function doTeleport()
	if teleportPoint and character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = teleportPoint
		print("Teletransportado a: " .. tostring(teleportPoint.Position))
	else
		doTeleportButton.Text = "Sin Punto TP"
		doTeleportButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		wait(2)
		doTeleportButton.Text = "Hacer TP"
		doTeleportButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		print("No se pudo teletransportar: no hay punto guardado o personaje no encontrado")
	end
end

-- Conectar eventos
jumpButton.MouseButton1Click:Connect(toggleInfiniteJump)
jumpButton.TouchTap:Connect(toggleInfiniteJump) -- Soporte para toque en móvil
seeThroughButton.MouseButton1Click:Connect(toggleSeeThrough)
seeThroughButton.TouchTap:Connect(toggleSeeThrough)
speedButton.MouseButton1Click:Connect(toggleSpeed)
speedButton.TouchTap:Connect(toggleSpeed)
flyButton.MouseButton1Click:Connect(toggleFly)
flyButton.TouchTap:Connect(toggleFly)
setTeleportButton.MouseButton1Click:Connect(setTeleportPoint)
setTeleportButton.TouchTap:Connect(setTeleportPoint)
doTeleportButton.MouseButton1Click:Connect(doTeleport)
doTeleportButton.TouchTap:Connect(doTeleport)
UserInputService.JumpRequest:Connect(onJumpRequest)

-- Actualizar vuelo en cada frame
RunService.RenderStepped:Connect(function()
	if flyEnabled then
		updateFly()
	end
end)

-- Manejar jugadores que se unen
Players.PlayerAdded:Connect(function(newPlayer)
	print("Jugador añadido: " .. newPlayer.Name)
	if seeThroughEnabled and newPlayer ~= player then
		newPlayer.CharacterAdded:Connect(function(character)
			addHighlight(character)
		end)
		if newPlayer.Character then
			addHighlight(newPlayer.Character)
		end
	end
end)

-- Manejar jugadores que se van
Players.PlayerRemoving:Connect(function(leavingPlayer)
	print("Jugador removido: " .. leavingPlayer.Name)
	if highlights[leavingPlayer.Character] then
		highlights[leavingPlayer.Character]:Destroy()
		highlights[leavingPlayer.Character] = nil
	end
end)

-- Detectar NPCs existentes al inicio
for _, model in pairs(Workspace:GetDescendants()) do
	if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and model ~= player.Character then
		print("NPC detectado al inicio: " .. model.Name)
		if seeThroughEnabled then
			addHighlight(model)
		end
	end
end

-- Detectar nuevos NPCs añadidos
Workspace.DescendantAdded:Connect(function(descendant)
	if seeThroughEnabled and descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") and descendant ~= player.Character then
		print("Nuevo NPC detectado: " .. descendant.Name)
		addHighlight(descendant)
	end
end)

-- Actualizar velocidad y vuelo al reaparecer
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid", 15)
	defaultWalkSpeed = humanoid.WalkSpeed
	if speedEnabled then
		updateSpeed()
	end
	if flyEnabled then
		updateFly()
	end
	print("Personaje reapareció, velocidad y vuelo actualizados")
end)

print("Script inicializado correctamente")
