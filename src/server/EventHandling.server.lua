-- This script handles most events(PlayerAdded, PlayerRemoved, etc.) on the server side
local keyModule = require(script.Parent:WaitForChild("Game Logic").KeyModule)
local roundModule = require(script.Parent:WaitForChild("Game Logic").RoundModule)

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("MyDataStore")


game.Players.PlayerAdded:Connect(function(player) -- when a player is added, insert values into their character
	
	-- insert a currency value into the player for the shop
	local PiggyTokens = Instance.new("IntValue")
	PiggyTokens.Name = "Tokens"
	PiggyTokens.Value = 1000
	PiggyTokens.Parent = player
	
	local trapInventory = Instance.new("Folder")
	trapInventory.Name = "TrapInventory"
	trapInventory.Parent = player
	
	local skinInventory = Instance.new("Folder")
	skinInventory.Name = "SkinInventory"
	skinInventory.Parent = player
	
	local equippedTrap = Instance.new("StringValue")
	equippedTrap.Name = "EquippedTrap"
	equippedTrap.Parent = player
	
	local equippedSkin = Instance.new("StringValue")
	equippedSkin.Name = "EquippedSkin"
	equippedSkin.Parent = player
	
	-- Insert a tag inside the player so we can tell if a player is afk 
	local inMenu = Instance.new("BoolValue")
	inMenu.Name = "InMenu"
	inMenu.Parent = player
	
	local data
	
	local success, errormsg = pcall(function() -- return any previously saved data 
		data = DataStore:GetAsync(player.UserId)
	end)
	
	if data ~= nil then 
		
		-- check the data from GetAsync()
		
		if data.EquippedTrap then
			equippedTrap.Value = data.EquippedTrap
		end
		
		if data.EquippedSkin then
			equippedSkin.Value = data.EquippedSkin
		end
		
		if data.Tokens then
			PiggyTokens.Value = data.Tokens
		end
		
		if data.Skins then
			for i, v in pairs(data.Skins) do
				local val = Instance.new("StringValue")
				val.Name = v
				val.Parent = skinInventory
			end
		end
		
		if data.Traps then
			for i, v in pairs(data.Traps) do
				local val = Instance.new("StringValue")
				val.Name = v
				val.Parent = trapInventory
			end
		end	
	end
	
	game.ReplicatedStorage.SendData:FireClient(player,data) -- pass the player's data
	
	player.CharacterAdded:Connect(function(char) -- drop the player's tools and remove their tags on death
		char.Humanoid.Died:Connect(function() 
			
			if char:FindFirstChild("HumanoidRootPart") then 
				if game.Workspace.Map then
					keyModule.DropTools(player,game.Workspace.Map,char.HumanoidRootPart.Position) 
					print("tools dropped")
				end
			end
			
			if player:FindFirstChild("Contestant") then  
				player.Contestant:Destroy()
			elseif player:FindFirstChild("Piggy") then
				player.Piggy:Destroy()
			end
		end)
	end)
end) 

game.Players.PlayerRemoving:Connect(function(player) -- On the player leaving, save their data
	
	local data = {} -- create a huge data table of the players tokens,
	-- skins, traps, and more
	
	data.Tokens = player.Tokens.Value
	
	data.EquippedSkin = player.EquippedSkin.Value
	data.EquippedTrap = player.EquippedTrap.Value
	
	data.Skins = {}
	data.Traps = {}
	
	for i, v in pairs(player.SkinInventory:GetChildren()) do -- add each skin into the mini table
		table.insert(data.Skins,v.Name)
		print(v.Name)
	end
	
	for i, v in pairs(player.TrapInventory:GetChildren()) do -- add each Trap into the mini table
		table.insert(data.Traps,v.Name)
		print(v.Name)
	end
	
	local success, errorMsg = pcall(function()		
		DataStore:SetAsync(player.UserId,data) -- set the data into their DataStore
	end)
		
	if success then
		print("Successfully Saved")
	end
	
end)

game:BindToClose(function() -- Run this code when the server is about to shut down
	for i, player in pairs(game.Players:GetPlayers()) do
		local data = {} 

		data.Tokens = player.Tokens.Value

		data.EquippedSkin = player.EquippedSkin.Value
		data.EquippedTrap = player.EquippedTrap.Value

		data.Skins = {}
		data.Traps = {}

		for i, v in pairs(player.SkinInventory:GetChildren()) do -- add each skin into the mini table
			table.insert(data.Skins,v.Name)
			print(v.Name)
		end

		for i, v in pairs(player.TrapInventory:GetChildren()) do -- add each Trap into the mini table
			table.insert(data.Traps,v.Name)
			print(v.Name)
		end

		local success, errorMsg = pcall(function()		
			DataStore:SetAsync(player.UserId,data) -- set the data into their DataStore
		end)

		if success then
			print("Successfully Saved")
		end
	end
end)

game.ReplicatedStorage.PlaceTrap.OnServerEvent:Connect(function(player)
	-- make sure the player is the piggy 
	if player:FindFirstChild("Piggy") then
		if player:FindFirstChild("TrapCount") then
			
			if player.TrapCount.Value > 0 then
				
				if game.Workspace:FindFirstChild("Map") then
					
					local trap 
					
					if player.EquippedTrap.Value ~= "" then -- use the equipped trap
						if game.ReplicatedStorage.Traps:FindFirstChild(player.EquippedTrap.Value) then
							trap = game.ReplicatedStorage.Traps[player.EquippedTrap.Value]:Clone()
						end
					else -- else, use the default trap 
						trap = game.ReplicatedStorage.Traps.Bear_Trap:Clone()
					end
					
					local offset = Vector3.new(0,-3.5,-2)
					
					trap.CFrame = player.Character.HumanoidRootPart.CFrame*CFrame.new(offset) -- combine two cframes to offset the position of the bear trap
					warn("Not properly offset")
					trap.Parent = game.Workspace:FindFirstChild("Map") 
					
				end
			end
		end
	end
end)

game.ReplicatedStorage.MenuPlay.OnServerEvent:Connect(function(player)
	if player:FindFirstChild("InMenu") then
		-- Remove the InMenu tag so that you can be counted as an active player
		player.InMenu:Destroy()
	end
	
	if game.ServerStorage.GameValues.GameInProgress.Value == true then -- check if the game is in progress
		local contestant = Instance.new("BoolValue")
		contestant.Name = "Contestant"
		contestant.Parent = player
		
		game.ReplicatedStorage.ToggleCrouch:FireClient(player,true)
		
		roundModule.TeleportPlayers({player},game.Workspace:FindFirstChild("Map").PlayerSpawns:GetChildren()) -- a buffer
	end
	
end)

-- Fired when a player attempts to buy an item 
game.ReplicatedStorage.BuyItem.OnServerInvoke = function(player,itemName,itemType) 
	local item
	local inInventory
	
	-- check whether the item is in the player's inventory
	if itemType == "Skin" then 
		
		item = game.ReplicatedStorage.Skins:FindFirstChild(itemName)
		
		if player.SkinInventory:FindFirstChild(itemName) then
			inInventory = true
		end
		
	elseif itemType == "Trap" then
		
		item = game.ReplicatedStorage.Traps:FindFirstChild(itemName)
		
		if player.TrapInventory:FindFirstChild(itemName) then
			inInventory = true
		end
	end
	
	if item then -- determine whether item is real
		if item:FindFirstChild("Cost") then
			if not inInventory then
				if tonumber(item.Cost.Value) <= tonumber(player.Tokens.Value) then
					print("You can buy this")
					
					player.Tokens.Value = player.Tokens.Value - item.Cost.Value
					
					-- put the item in the player's inventory 
					local stringValue = Instance.new("StringValue")
					stringValue.Name = itemName
					
					if itemType == "Skin" then
						stringValue.Parent = player.SkinInventory
					elseif itemType == "Trap" then
						stringValue.Parent = player.TrapInventory
					end
					
					return "bought"
					
				else
					return "failed"
				end
			else
				print("You already own this item") 
				
				if itemType == "Skin" then
					player.EquippedSkin.Value = itemName
				elseif itemType == "Trap" then
					player.EquippedTrap.Value = itemName
				end
				
				return "Equipped"
			end
		end
	else
		print("No Skin/Trap found") 
		return "failed"
	end
end
