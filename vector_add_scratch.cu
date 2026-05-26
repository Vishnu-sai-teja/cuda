#include <stdio.h>
#include <stdlib.h>

# define NUM_ELEMENTS 10

void initialise_vectors(float **a){
    *a = (float * )malloc(NUM_ELEMENTS * sizeof(float));
    for(int i=0; i < NUM_ELEMENTS; i++){
        (*a)[i] = (float)rand();
        printf("The value at the index %d is %f\n", i, (*a)[i]);
    }
}

__global__ void add(float *d_v1, float *d_v2, float *d_result){
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    d_result[index] = d_v1[index] + d_v2[index];
}

int main(void){
    // Lets create a custom array pointer here
    float *v1, *v2, *result; // for host memory
    float *d_v1, *d_v2, *d_result; // for the device memory

    // size of the memory required
    int size = NUM_ELEMENTS * sizeof(float);
    printf("Size of the memory allocation : %d\n", size);

    // Allocate the memory and move it to the DRAM
    // -- in this case we are passing the addres of the pointer - so taht the value of the allocated memory on the device address is store inside the address pointer
    cudaMalloc((float **)&d_v1, size);
    cudaMalloc((float **)&d_v2, size);
    cudaMalloc((float **)&d_result, size);

    // initialise and create teh vectoes for teh host device 
    initialise_vectors(&v1); // pass on the address of hte pointer to update teh address of the poitner itself
    initialise_vectors(&v2);

    cudaMemcpy(d_v1, v1, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_v2, v2, size, cudaMemcpyHostToDevice);

    // trigger the computation
    add<<<1, NUM_ELEMENTS>>>(d_v1, d_v2, d_result);

    //copy the response back
    result = (float *)malloc(size);
    int error_code = cudaMemcpy(result, d_result, size, cudaMemcpyDeviceToHost);

    printf("\nResult : \n");
    for(int i=0; i < NUM_ELEMENTS; i++){
        printf("The value at the index %d is %f \n", i, result[i]);
    }

    printf("\nThe value at random position : test : %f\n", *result);
    printf("The error code : %d\n", error_code);

    cudaFree(d_result);
    cudaFree(d_v1);
    cudaFree(d_v2);

    free(result); free(v1); free(v2);

    // results after clearning
    printf("\nCleared Result : \n");
    for(int i=0; i < NUM_ELEMENTS; i++){
        printf("The value at the index %d is %f \n", i, result[i]);
    }
}