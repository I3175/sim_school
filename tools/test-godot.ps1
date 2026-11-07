param([string]$Godot = "godot")
$ErrorActionPreference = "Stop"
$projectPath = Split-Path -Parent $PSScriptRoot
& $Godot --headless --path $projectPath --editor --import
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Godot --headless --path $projectPath --quit-after 2
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Godot --headless --path $projectPath -s addons/gut/gut_cmdln.gd -gexit
exit $LASTEXITCODE
