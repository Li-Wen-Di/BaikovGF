#!/usr/bin/env bash
# 作用：
# - 在项目根目录创建 .venv-flint 虚拟环境
# - 安装并验证 python-flint
# - 供 Linux 用户配置 BaikovGF 外部化简环境

set -euo pipefail

PYTHON_BIN="${1:-python3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENV_DIR="${PROJECT_ROOT}/.venv-flint"
VENV_PYTHON="${VENV_DIR}/bin/python"

echo "Project root: ${PROJECT_ROOT}"
echo "Using Python launcher: ${PYTHON_BIN}"

"${PYTHON_BIN}" --version

if [[ ! -x "${VENV_PYTHON}" ]]; then
  echo "Creating virtual environment at ${VENV_DIR}"
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
else
  echo "Reusing existing virtual environment at ${VENV_DIR}"
fi

echo "Upgrading pip, setuptools and wheel"
"${VENV_PYTHON}" -m pip install --upgrade pip setuptools wheel

echo "Installing python-flint"
"${VENV_PYTHON}" -m pip install --upgrade python-flint

echo "Verifying FLINT import"
"${VENV_PYTHON}" -c "import sys, flint; print('python =', sys.executable); print('flint =', flint.__file__)"

echo
echo "Environment is ready."
echo "The package will automatically prefer:"
echo "  ${VENV_PYTHON}"
