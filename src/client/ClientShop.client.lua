-- A script containing the code to make a shop possible on each client
-- main shop gui 
local shop = script.Parent

local skins = shop:WaitForChild("Skins")
local traps = shop:WaitForChild("Traps")

-- Button gui 
local skinsBtn = shop:WaitForChild("SkinsButton")
local trapsBtn = shop:WaitForChild("TrapsButton")

-- a template for each skin or trap 
local itemTemplate = script:WaitForChild("Template")

local cart = "http://www.roblox.com/asset/?id=13732884875"
local greenTick = "http://www.roblox.com/asset/?id=13055495433"

	-- functions --


skinsBtn.MouseButton1Click:Connect(function()
	traps.Visible = false

	skins.Visible = true
end)

trapsBtn.MouseButton1Click:Connect(function()
	skins.Visible = false

	traps.Visible = true
end)

-- return all the skins and traps available for purchase
local skinsData = game.ReplicatedStorage.Skins:GetChildren()  
local trapsData = game.ReplicatedStorage.Traps:GetChildren()  

function createFrame(name,cost,object,parent,itemType) -- create a frame for a skin or trap 
	local frame = itemTemplate:Clone()
	frame.Name = name
	frame.Title.Text = name
	frame.Cost.Text = cost
	
	local VPFobj = object:Clone() -- viewport frame object
	VPFobj.Parent = frame.ViewportFrame
	
	local cam = Instance.new("Camera")
	cam.Parent = frame.ViewportFrame
	
	if itemType == "Skin" then
		print(itemType)
		-- set camera CFrame to the character's head
		cam.CFrame = CFrame.new(object.Head.Position + (object.Head.CFrame.LookVector*5) + Vector3.new(0,2,0), object.Head.Position)
	elseif itemType == "Trap" then
		-- set camera CFrame to the object
		cam.CFrame = CFrame.new(object.Position + (object.CFrame.LookVector*5) + Vector3.new(0,2,0), object.Position)
	end
	
	frame.ViewportFrame.CurrentCamera = cam
	
	frame.Parent = parent

	return frame
end

-- add items to the shop 
function addSkins(data) -- create frames for every skin
	warn("dry")
	for i, v in pairs(data) do
		local frame = createFrame(v.Name,v.Cost.Value,v,skins.Folder,"Skin")

		if game.Players.LocalPlayer.SkinInventory:FindFirstChild(v.Name) then
			frame.Button.Image = greenTick
			frame.Cost.Text = "Owned"
		end

		if game.Players.LocalPlayer.EquippedSkin.Value == v.Name then
			frame.Cost.Text = "Equipped"
		end

		frame.Button.MouseButton1Click:Connect(function()
			local result = game.ReplicatedStorage.BuyItem:InvokeServer(v.Name,"Skin")


			if result == "bought" then
				-- the purchase was a success
				frame.Button.Image = greenTick
				frame.Cost.Text = "Owned"

			elseif result == "Equipped" then

				-- update the other frames' text 
				for _, object in pairs(skins.Folder:GetChildren()) do
					if object:IsA("Frame") and object:FindFirstChild("Cost") then -- filter the search
						if game.Players.LocalPlayer.SkinInventory:FindFirstChild(object.Name) then
							object.Cost.Text = "Owned"
						end
					end
				end

				-- equip the item 
				frame.Button.Image = greenTick
				frame.Cost.Text = "Equipped"

			end
		end)
	end
end

function addTraps(data) -- create frames for every trap
	for i, v in pairs(data) do
		local frame = createFrame(v.Name,v.Cost.Value,v,traps.Folder,"Trap")

		if game.Players.LocalPlayer.TrapInventory:FindFirstChild(v.Name) then
			frame.Button.Image = greenTick
			frame.Cost.Text = "Owned"
		end

		if game.Players.LocalPlayer.EquippedTrap.Value == v.Name then
			frame.Cost.Text = "Equipped"
		end

		frame.Button.MouseButton1Click:Connect(function()
			local result = game.ReplicatedStorage.BuyItem:InvokeServer(v.Name,"Trap")


			if result == "bought" then
				-- the purchase was a success
				frame.Button.Image = greenTick
				frame.Cost.Text = "Owned"

			elseif result == "Equipped" then

				-- update the other frames' text 
				for _, object in pairs(traps.Folder:GetChildren()) do
					if object:IsA("Frame") and object:FindFirstChild("Cost") then -- filter the search
						if game.Players.LocalPlayer.TrapInventory:FindFirstChild(object.Name) then
							object.Cost.Text = "Owned"
						end
					end
				end

				-- equip the item 
				frame.Button.Image = greenTick
				frame.Cost.Text = "Equipped"

			end
		end)
	end
end



game.ReplicatedStorage.SendData.OnClientEvent:Connect(function() -- load the players data
	addSkins(skinsData)
	addTraps(trapsData)
end)
