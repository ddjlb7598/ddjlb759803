whlie true do
local args = {
	"swingKatana"
}
game:GetService("Players").LocalPlayer:WaitForChild("ninjaEvent"):FireServer(unpack(args))
wait(0.3) 
end
