# 作用：
# - 在项目根目录创建 .venv-flint 虚拟环境
# - 安装并验证 python-flint
# - 供 Windows 用户一键配置 BaikovGF 外部化简环境

[CmdletBinding()]
param(
  [string]$Python = "python"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$venvDir = Join-Path $projectRoot ".venv-flint"
$venvPython = Join-Path $venvDir "Scripts\python.exe"

Write-Host "Project root: $projectRoot"
Write-Host "Using Python launcher: $Python"

& $Python --version

if (-not (Test-Path $venvPython)) {
  Write-Host "Creating virtual environment at $venvDir"
  & $Python -m venv $venvDir
}
else {
  Write-Host "Reusing existing virtual environment at $venvDir"
}

Write-Host "Upgrading pip, setuptools and wheel"
& $venvPython -m pip install --upgrade pip setuptools wheel

Write-Host "Installing python-flint"
& $venvPython -m pip install --upgrade python-flint

Write-Host "Verifying FLINT import"
& $venvPython -c "import sys, flint; print('python =', sys.executable); print('flint =', flint.__file__)"

Write-Host ""
Write-Host "Environment is ready."
Write-Host "The package will automatically prefer:"
Write-Host "  $venvPython"
