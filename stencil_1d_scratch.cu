#include <stdio.h>
#include <algorithm>

using namespace std;

#define N 4096
#define RADIUS 3
#define BLOCK_SIZE 16

void fill_ints(int *x, int n){
    fill_n(x, n, 1); // starting from address x fill n elemnets with 1
}

__global__ void stencil_1d(int *in, int* out){
    __shared__ int temp[BLOCK_SIZE + 2*RADIUS];

    int gindex = threadIdx.x + blockDim.x * blockIdx.x + RADIUS;
    int lindex = RADIUS + threadIdx.x;

    temp[lindex] = in[gindex];
    if (threadIdx.x < RADIUS){
        temp[lindex - RADIUS] = in[gindex - RADIUS];
        temp[lindex + blockDim.x] = in[gindex + blockDim.x];

    }

    __syncthreads();

    int result = 0;
    for(int i = -RADIUS; i <= RADIUS; i++){
        result += temp[lindex + i];
    }
    out[gindex] = result;
}


int main(){
    int *HInput, *HOutput;
    int *DInput, *DOutput;

    int size = (N + 2*RADIUS)*sizeof(int);
    HInput = (int *)malloc(size);
    HOutput = (int *)malloc(size);

    fill_ints(HInput, N + 2*RADIUS);
    fill_ints(HOutput, N + 2*RADIUS); // only to initialise

    cudaMalloc((void **)&DInput, size);
    cudaMalloc((void **)&DOutput, size);

    cudaMemcpy(DInput, HInput, size, cudaMemcpyHostToDevice);
    cudaMemcpy(DOutput, DInput, size, cudaMemcpyHostToDevice);

    stencil_1d<<<N/BLOCK_SIZE,BLOCK_SIZE>>>(DInput, DOutput);

    cudaMemcpy(HOutput, DOutput, size, cudaMemcpyDeviceToHost);


    // Validate the results
    for(int i=0; i< N + 2*RADIUS; i++){
        if(i < RADIUS || i >= N + RADIUS){
            if(HOutput[i] != 1){
                printf("Mismatch at index %d, was: %d, should be: %d\n", i, HOutput[i], 1);
            } 
        }
        else {
            if (HOutput[i] != 1 + 2*RADIUS)
                printf("Mismatch at index %d, was: %d, should be: %d\n", i, HOutput[i], 1 + 2*RADIUS);
            }
    }
    printf("Hello !");

    free(HInput); free(HOutput);
    cudaFree(DInput); cudaFree(DOutput);
}