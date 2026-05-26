#include <stdio.h>

// lets work with same size matrices first
# define rows 3
# define cols 3
# define MAX_VALUE 10


void initialise_vectors(float **mat){
    int size = (cols * rows) * sizeof(int);
    *mat = (int *)malloc(size);

    for(int i=0;i < rows; i++){
        for(int j=0; j< cols; j++){
            (*mat)[i][j] = rand()/MAX_VALUE;
        }
    }
}

int main(void){
    int *mat1;
    int *mat2;

    // Initialise these matrices
    initialise_vectors(&mat1);
    initialise_vectors(&mat2); // pass teh address of the vectors

    // A simple matrix multiplication 
}