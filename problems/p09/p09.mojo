from memory import UnsafePointer, stack_allocation
from gpu import thread_idx, block_idx, block_dim, barrier
from gpu.host import DeviceContext
from gpu.memory import AddressSpace
from sys import sizeof
from testing import assert_equal

# ANCHOR: pooling
alias TPB = 8
alias SIZE = 8
alias BLOCKS_PER_GRID = (1, 1)
alias THREADS_PER_BLOCK = (TPB, 1)
alias dtype = DType.float32


fn pooling(
    output: UnsafePointer[Scalar[dtype]],
    a: UnsafePointer[Scalar[dtype]],
    size: Int,
):
    shared = stack_allocation[
        TPB,
        Scalar[dtype],
        address_space = AddressSpace.SHARED,
    ]()
    global_i = block_dim.x * block_idx.x + thread_idx.x
    local_i = thread_idx.x
    # FILL ME IN (roughly 10 lines)

    if global_i < size:
        shared[global_i] = a[global_i]

    barrier()

    if global_i == 0:
        output[0] = shared[0]
    elif global_i == 1:
        output[1] = shared[0] + shared[1]
    elif global_i < size:
        output[global_i] = (shared[global_i] + shared[global_i - 1] + shared[global_i - 2])

# ANCHOR_END: pooling


def main():
    with DeviceContext() as ctx:
        out = ctx.enqueue_create_buffer[dtype](SIZE).enqueue_fill(0)
        a = ctx.enqueue_create_buffer[dtype](SIZE).enqueue_fill(0)
        with a.map_to_host() as a_host:
            for i in range(SIZE):
                a_host[i] = i

        ctx.enqueue_function[pooling](
            out.unsafe_ptr(),
            a.unsafe_ptr(),
            SIZE,
            grid_dim=BLOCKS_PER_GRID,
            block_dim=THREADS_PER_BLOCK,
        )

        expected = ctx.enqueue_create_host_buffer[dtype](SIZE).enqueue_fill(0)

        ctx.synchronize()

        with a.map_to_host() as a_host:
            ptr = a_host.unsafe_ptr()
            for i in range(SIZE):
                s = Scalar[dtype](0)
                for j in range(max(i - 2, 0), i + 1):
                    s += ptr[j]

                expected[i] = s

        with out.map_to_host() as out_host:
            print("out:", out_host)
            print("expected:", expected)
            for i in range(SIZE):
                assert_equal(out_host[i], expected[i])
