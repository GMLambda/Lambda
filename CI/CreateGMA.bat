@echo off
setlocal

rmdir publish /Q /S
mkdir publish 
mkdir publish\gamemodes
mkdir publish\gamemodes\lambda 

rmdir publish /Q /S
mkdir gma

xcopy "backgrounds" "publish\gamemodes\lambda\backgrounds\" /s /y /e 
xcopy "gamemode" "publish\gamemodes\lambda\gamemode\" /s /y /e 
xcopy "content" "publish\gamemodes\lambda\content\" /s /y /e 
xcopy "entities" "publish\gamemodes\lambda\entities\" /s /y /e 

xcopy "addon.json" "publish\addon.json*"
xcopy "icon24.png" "publish\gamemodes\lambda\icon24.png*"
xcopy "logo.png" "publish\gamemodes\lambda\logo.png*"
xcopy "lambda.txt" "publish\gamemodes\lambda\lambda.txt*"

.\gmpublish-ci\gmad.exe create -folder ".\publish" -out "gma\lambda.gma"
