#!/bin/bash
set -e

# Defaults (can be overridden via env vars)
VLLM_REPO=${VLLM_REPO:-"https://github.com/vllm-project/vllm.git"}
VLLM_BRANCH=${VLLM_BRANCH:-"main"}
WORKDIR=${WORKDIR:-"/workspace"}

echo "=========================================="
echo "Installing vLLM from ${VLLM_REPO}"
echo "Branch: ${VLLM_BRANCH}"
echo "=========================================="

# Create workspace directory if it doesn't exist
mkdir -p ${WORKDIR}
cd ${WORKDIR}

# Clone or update the repo
if [ -d "vllm" ]; then
    echo "vLLM directory exists, updating..."
    cd vllm
    git fetch origin || true
    
    # Try to checkout the branch (create if it doesn't exist locally)
    if git show-ref --verify --quiet refs/heads/${VLLM_BRANCH}; then
        git checkout ${VLLM_BRANCH}
        git pull origin ${VLLM_BRANCH} || true
    elif git show-ref --verify --quiet refs/remotes/origin/${VLLM_BRANCH}; then
        git checkout -b ${VLLM_BRANCH} origin/${VLLM_BRANCH}
    else
        echo "Warning: Branch ${VLLM_BRANCH} not found, using current branch"
    fi
else
    echo "Cloning vLLM repository..."
    git clone --depth 1 --branch ${VLLM_BRANCH} ${VLLM_REPO} vllm || \
        git clone ${VLLM_REPO} vllm
    cd vllm
    git checkout ${VLLM_BRANCH} || echo "Warning: Could not checkout ${VLLM_BRANCH}, using default branch"
fi

# Show current commit
echo "Current commit:"
git log -1 --oneline

# Install vLLM in editable mode using pre-compiled binaries from base image
# This skips kernel compilation and makes install take seconds instead of 30+ minutes
echo "Installing vLLM (using pre-compiled binaries)..."
VLLM_USE_PRECOMPILED=1 pip install -e . --no-build-isolation

echo "=========================================="
echo "vLLM installation complete!"
echo "Starting vLLM server..."
echo "=========================================="

# Run vLLM serve with all arguments passed to this script
exec vllm serve "$@"

