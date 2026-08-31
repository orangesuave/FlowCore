@echo off
echo [FlowCore] Compiling perkexport.csv into PerksData.lua...
python "%~dp0build_perks_data.py"
echo.
echo [Done] You can now type /reload in World of Warcraft!
pause
