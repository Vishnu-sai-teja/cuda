#include <stdio.h>
#include <stdlib.h>

#define N 1048576


void fill_array(int *arr, int size){
    for(int i=0; i<size; i++){
        arr[i] = rand() % 10;
    }
}

__global__ void add(int *d_a, int *d_b, int *d_c){
    int index = threadIdx.x + blockDim.x * blockIdx.x;
    if (index < N){
        d_c[index] = d_a[index] + d_b[index];
    }
}

__global__ void grid_stride_add(int *d_a, int *d_b, int* d_c){
    // each hterad handles elements at a stride lendth  / gap
    int index = threadIdx.x + blockDim.x * blockIdx.x;
    for(int i=index; i<N; i+=gridDim.x * blockDim.x){
        d_c[i] = d_b[i] + d_a[i];
    }
}


int main(){
    // create a array
    int *a; int *b; int *c; int *d;
    int *d_a; int *d_b; int *d_c;

    float time_in_milliseconds;

    cudaEvent_t start, stop; // define the handle for the envent
    cudaEventCreate(&start); // create the event on GPU 
    cudaEventCreate(&stop);

    int vector_size = N * sizeof(int);
    a = (int *)malloc(vector_size);
    b = (int *)malloc(vector_size);
    c = (int *)malloc(vector_size);
    d = (int *)malloc(vector_size);

    fill_array(a, N);
    fill_array(b, N);
    fill_array(c, N);

    cudaMalloc((int **)&d_a, vector_size);
    cudaMalloc((int **)&d_b, vector_size);
    cudaMalloc((int **)&d_c, vector_size);

    cudaMemcpy(d_a, a, vector_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, vector_size, cudaMemcpyHostToDevice);

    // start with the process now - one element per thread

    // create the event
    cudaEventRecord(start); // recrod teh timestamp with event
    add<<<N/256, 256>>>(d_a, d_b, d_c);
    cudaEventRecord(stop);

    cudaEventSynchronize(stop); // sync the last stage of the event

    // time taken
    cudaEventElapsedTime(&time_in_milliseconds, start, stop);
    printf("Time: %f ms\n", time_in_milliseconds);

    cudaMemcpy(c, d_c, vector_size, cudaMemcpyDeviceToHost);

    // faster add - with grid-stride add instead of one thread handling a single operation
    int blocks =160;
    int threads = 1024;
    cudaEventRecord(start);
    grid_stride_add<<<blocks, threads>>>(d_a, d_b, d_c);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&time_in_milliseconds, start, stop);
    printf("Time in grid : %f ms\n", time_in_milliseconds);

    cudaMemcpy(d, d_c, vector_size, cudaMemcpyDeviceToHost);

    // validate the results;
    for(int i=0; i < N; i++){
        if((a[i] + b[i]) != c[i]){
            printf("Vector addition failed at index : %i with the value %i instead of %i\n", i, c[i], a[i] + b[i]);
        } 
    }

    // validate the resutls
    for(int i=0; i < N; i++){
        if((a[i] + b[i]) != d[i]){
            printf("Vector Grid addition failed at index : %i with the value %i instead of %i\n", i, d[i], a[i] + b[i]);
        } 
    }

    free(a); free(b); free(c);
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
}