#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h>
#include <getopt.h>
#include <time.h>
#include <iostream>
#include <vector>

float randFloat(float high, float low);

//HEADER FOR VALUES IN FILE THING
typedef struct io_header header;
/* header: contains all the variables required for the file, including
 * particle counts.
 *
 */
struct io_header{
    int npart[6];       //Particle counds per type of particle
    double mass[6];     //Mass of respective particles
    double time;        //Init time of file
    double redshift;    //Redshift at init time of file
    int flag_sfr;       //a flag
    int flag_feedback;  //another flag
    int npartTotal[6];  //Random particle totals
    int flag_cooling;   //another flag
    int num_files;      //Number of read files (just this one, so one)
    double BoxSize;     //Size of box of sim
    double Omega0;      //Omega var
    double OmegaLambda; //Another omega var
    double HubbleParam; //the hubble parameter
    char fill[96];      //Fill bytes (for total of 256 bytes)
};

//PARTICLE STRUCT
typedef struct sim_particle particle;
/* particle: contains values for each particle in simulation
 *
 */
struct sim_particle{
    float Pos[3];   //Particle location, x = 0, y = 1, z = 2
    float Vel[3];   //Particle velocity, x = 0, y = 1, z = 2
    int ID;         //Particle numerical identity
    float Mass;     //Mass of particular particle
};

/* newHeader: Initializes a new header.  There are some hard coded values
 * due to the nature of the project.
 *
 */
header newHeader(){
    //header *h = (header*)malloc(sizeof(header));
    header h;
    //only using npart[1] for halo particles
    h.npart[0] = h.npart[1] = h.npart[2] = h.npart[3] = h.npart[4] = h.npart[5] = 0;
    h.npart[1] = 1024;
    h.mass[0] = h.mass[2] = h.mass[3] = h.mass[4] = h.mass[5] = 0;
    h.mass[1] = 8131.346910;
    h.time = 0.090909;
    h.redshift = 10.0;
    h.flag_sfr = 0;
    h.flag_feedback = 0;
    h.npartTotal[0] = h.npartTotal[1] = h.npartTotal[2] = h.npartTotal[3] = h.npartTotal[4] = h.npartTotal[5] = 0;
    h.flag_cooling = 0;
    h.num_files = 1;
    h.BoxSize = 100000.0;
    h.Omega0 = 0.301465; //calculate it later
    h.OmegaLambda = 0.7;
    h.HubbleParam = 0.7;
    return h;
}

void setupP(std::vector<particle *> &P, int partDim){
    float defaultZ = 50000.0f;

    for(int j = 0; j < partDim; j++){
        for(int i = 0; i < partDim; i++){
            int pid = j * partDim + i;
            particle *p = new particle();
            p -> ID = pid + 1;
            p -> Pos[0] = 0.0f;
            p -> Pos[1] = 0.0f;
            p -> Pos[2] = defaultZ;
            p -> Vel[0] = 0.0f;
            p -> Vel[1] = 0.0f;
            p -> Vel[2] = 0.0f;
            P.push_back(p);
        }
    }
}

void deleteP(std::vector<particle *> &P){
    while(!(P.empty())){
        size_t plen = P.size();
        particle *p = P[plen - 1];
        P.pop_back();
        delete(p);
    }
}

char *getFD(int argc, char **argv){
    const char *options = "f:";
    char *res;
    char chr;
    while((chr = getopt(argc, argv, options)) != -1){
        switch (chr){
            case 'f':
                res = optarg;
                break;
            default:
                exit(0);
        }
    }
    return res;
}

int main(int argc, char **argv){
    int blklen = 256;
    int partDim = 32;

    float delta;
    float bound = 100000.0f;

    #define WSKIP fwrite(&blklen, sizeof(int), 1, wfile);
    FILE *wfile;
    header h = newHeader();
    std::vector<particle *> P;// = new std::vector<particle *>();
    setupP(P, partDim);

    delta = bound / ((float)partDim);
    srand(time(NULL));

    deleteP(P);
    return 0;
}