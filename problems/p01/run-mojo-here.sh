#!/bin/bash
# Wrapper to run mojo with proper GLIBC and environment setup

MOJO_BASE="/n/home07/fucheng/mojo-gpu-puzzles/.pixi/envs/default"
CONTAINER_PATH="/n/home07/fucheng/mojo-gpu-puzzles/mojo-ubuntu24.sif"

# Run mojo inside the container with proper environment
singularity exec --nv \
    --bind /n/home07/fucheng:/n/home07/fucheng \
    --env MOJO_STDLIB_PATH="${MOJO_BASE}/lib/mojo" \
    --env PATH="${MOJO_BASE}/bin:$PATH" \
    --env LD_LIBRARY_PATH="${MOJO_BASE}/lib:$LD_LIBRARY_PATH" \
    "$CONTAINER_PATH" \
    "${MOJO_BASE}/bin/mojo" "$@"