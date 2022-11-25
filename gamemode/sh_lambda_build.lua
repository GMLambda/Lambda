if SERVER then
    AddCSLuaFile()
end

GM.Name = "Lambda"
GM.Author = "N/A"
GM.Email = "N/A"
GM.Website = "https://github.com/ZehMatt/Lambda"
GM.Version = "0.9.14"

if LAMBDA_STAGING then
    GM.WorkshopID = "801875828"
else
    GM.WorkshopID = "780244493"
end
GM.WorkshopBuild = false