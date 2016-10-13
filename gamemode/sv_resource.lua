local RESOURCE_LIST =
{
	"materials/lambda/blockade.png",
	"materials/lambda/death_point.png",
	"materials/lambda/ring1.png",
	"materials/lambda/ring2.png",
	"materials/lambda/ring3.png",
	"materials/lambda/run_point.png",
	"materials/lambda/trigger.png",
	"materials/lambda/vehicle.png",

	"scripts/sentences-hl1.txt",	-- Override because it crashes.

	"sound/lambda/death.mp3",
}

for _,v in pairs(RESOURCE_LIST) do
	resource.AddSingleFile(v)
end
