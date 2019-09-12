#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h>
#include <getopt.h>
#include <time.h>

float randFloat(float high, float low);

/*                   ENUMS and STRUCTS                   */

//ENUMS

//NORMALIZATION CONDITIONS FOR HANDLING OUT OF BOUNDS
typedef enum normcond {ERROR, WRAP, RANDOM, REFLECT} norm;

//LOCATION OF REFERENCE OF FUNCTION
typedef enum location {CENTER, CARTESIAN} loc;

//STRUCTS

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

//READIN INPUT STRUCT
typedef struct readreturn returnstruct;
/* returnstruct: struct that contains variables that contain the inputs
 * provided by the user for the particular level file
 *
 */
struct readreturn{
    header h;       //Header for file
    char *function; //REMEMBER TO UPDATE WITH TWO FUNCTION THING
    loc fncenter;   //Location of function center (cartesian or centered)
    char *filename; //Name of the file to be saved as
};

/*
//TEMP FUNCTION FOR FUNCTION INPUTS< ABANDONED
float fn(float t, char *func, int funclen){
    (void)func;
    (void)funclen;
    float res = 0;
    float bound = 100000.0;
    float maxscale = 
    while(res < 0 || res >= bound){
        if(res < 0) res += bound;
        else if(res >= bound) res -= bound;
    }
    return res;
}*/

/*                  HEADER and INPUT HANDLING                   */

//HEADER

/* newHeader: Initializes a new header.  There are some hard coded values
 * due to the nature of the project.
 *
 */
header newHeader(){
    //header *h = (header*)malloc(sizeof(header));
    header h;
    //only using npart[1] for halo particles
    h.npart[0] = h.npart[1] = h.npart[2] = h.npart[3] = h.npart[4] = h.npart[5] = 0;
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

/* freeHeader: frees memory of header
 * UNUSED
 */
//void freeHeader(header *h){free(h);}

/* printHeader: FOR DEBUGGING ONLY, prints header to stdout
 *
 */
void printHeader(header h){
    printf("Header Size: %lu\n",sizeof(header));
    printf("Particle Counts:\n");
    printf("   Gas: %d\n   Halo (DM): %d\n   Disk: %d\n   Bulge: %d\n   Stars: %d\n   ???: %d\n",
        h.npart[0],h.npart[1],h.npart[2],h.npart[3],h.npart[4],h.npart[5]);
    printf("Particle Masses:\n");
    printf("   Gas: %lf\n   Halo (DM): %lf\n   Disk: %lf\n   Bulge: %lf\n   Stars: %lf\n   ???: %lf\n",
        h.mass[0],h.mass[1],h.mass[2],h.mass[3],h.mass[4],h.mass[5]);
    printf("Particle Counts (Maybe):\n");
    printf("   Gas: %d\n   Halo (DM): %d\n   Disk: %d\n   Bulge: %d\n   Stars: %d\n   ???: %d\n",
        h.npartTotal[0],h.npartTotal[1],h.npartTotal[2],
        h.npartTotal[3],h.npartTotal[4],h.npartTotal[5]);
    printf("Redshift: %lf       Time: %lf       BoxSize: %lf\n",h.redshift, h.time, h.BoxSize);
    printf("Omegas: 0: %lf   Lambda: %lf\n",h.Omega0,h.OmegaLambda);
    printf("HubbleParam: %lf\n",h.HubbleParam);
    printf("Flags:  Cooling: %d    SFR: %d      Feedback: %d\n", h.flag_cooling,h.flag_sfr,h.flag_feedback);
    printf("Num Files: %d\n",h.num_files);
}

//GETOPTIONS

/* handleGetOpt: handles input values.  Takes in the input arguments
 * from argv with argument amount argc.  Initializes a return struct and saves
 * all values into the returnstruct
 *
 */
returnstruct handleGetOpt(int argc, char **argv){
    returnstruct rs;
    header h = newHeader();
    const char *options = "hx:y:c:f:n:";
    char chr;
    int xpart = 0;
    int ypart = 0;
    while((chr = getopt(argc, argv, options)) != -1){
        switch (chr){
            case 'h':
                printf("INSERT HELP MESSAGE HERE\n");
                //freeHeader(h);
                exit(0);
            case 'x':
                xpart = atoi(optarg);
                break;
            case 'y':
                ypart = atoi(optarg);
                break;
            case 'f':
                printf("FUNCTION IS %s\n", optarg);
                rs.function = optarg;
                break;
            case 'c':
                printf("FUNCTION IS CENTERED AT %s\n",optarg);
                break;
            case 'n':
                rs.filename = optarg;
                break;
            default:
                printf("INSERT HELP MESSAGE HERE\n");
                //freeHeader(h);
                exit(0);
        }
    }
    h.npart[1] = xpart * ypart;
    h.npart[2] = xpart; //using it as temp
    h.npart[3] = ypart; //using it as temp
    rs.fncenter = CARTESIAN;
    //exit(0);
    rs.h = h;
    return rs;
}

//particle **

/* getNC: takes an integer representing norm condition and returns corresp.
 * normalization condition.
 *
 */
norm getNC(int normcond){
    norm nc;
    switch(normcond){
        case 0:
            nc = WRAP;
            break;
        case 1:
            nc = RANDOM;
            break;
        case 3:
            nc = REFLECT;
            break;
        default:
            nc = ERROR;
            break;
    }
    return nc;
}

/* normalize: handles condition when coordinate given is out of bounds,
 * provides different solutions based off of normalization condition.
 * WRAP: wraps particle around (treats boundaries as if on sphere)
 * RANDOM: random location for coordinate
 * REFLECT: reflects particle off of boundary (treats boundaries as self looping)
 * ERROR: assumed user has handled, returns a purposeful error value for later fn handling.
 *
 */
float normalize(float val, norm nc){
    float bound = 100000.0;
    if(val <= 0.0 || val > bound){
        switch(nc){
            case WRAP:
                if(val <= 0) return normalize(val + bound, nc);
                else return normalize(val - bound, nc);
            case RANDOM:
                return normalize(randFloat(bound,0), nc);
            case REFLECT:
                if(val <= 0) return normalize(val * (-1), nc);
                else return normalize((-1*val)+bound, nc);
            case ERROR:
                return bound + 1;
        }
    }
    return val;
}

/*              FUNCTION APPLICATION FUNCTIONS                  */

/* dist: returns distance of particle from origin
 *
 */
float dist(float x, float y){
    return sqrt(x*x + y*y);
}

/* unitx: returns the unit component along x axis
 *
 */
float unitx(float x, float y){
    float distance = dist(x,y);
    return x / distance;
}

/* unity: returns the unit component along y axis
 *
 */
float unity(float x, float y){
    float distance = dist(x,y);
    return y / distance;
}

/* randFloat: returns a random float between high and low floats.
 *
 */
float randFloat(float high, float low){
    return low + static_cast <float> (rand()) / static_cast <float> (RAND_MAX/(high - low));
}

/* parseXFn: parses function for x coord
 *
 */
float parseXFn(float x, float y, char *xfn){
    (void)xfn;
    float bound = 100000.0;
    float boundhalf = bound/2;
    float distance = dist(x,y);
    float temp = distance;
    float res = 0.0;
    distance *= distance * distance;
    distance *= boundhalf;
    if(temp>1.0){
        res = (distance * unitx(x,y)) + (boundhalf/2);
    }
    else{
        res = (distance * unitx(x,y)) + boundhalf;
    }
    return normalize(res,WRAP);
}

/* parseYFn: parses function for y coord
 *
 */
float parseYFn(float x, float y, char *yfn){
    (void)yfn;
    float bound = 100000.0;
    float boundhalf = bound/2;
    float distance = dist(x,y);
    float temp = distance;
    float res = 0.0;
    distance *= distance * distance;
    distance *= boundhalf;
    if(temp>1.0){
        res = (distance * unitx(x,y)) + (boundhalf/2);
    }
    else{
        res = (distance * unitx(x,y)) + boundhalf;
    }
    return normalize(res,WRAP);
}

void applyFn(float px, float py, char *xfn, char *yfn, float *res){
    (void)xfn;
    (void)yfn;
    px = randFloat(4.0,-4.0);
    py = randFloat(4.0,-4.0);
    res[0] = parseXFn(px,py,xfn);
    res[1] = parseYFn(px,py,yfn);
}

/* coordpurturb: 
 *
 */
float coordpurturb(float dist, float purturbmax, float distmax){
    dist += static_cast <float> (rand()) / static_cast <float> (RAND_MAX/(purturbmax*2.0)) + (-1.0*purturbmax);
    if(dist < 0){
        dist += (distmax - 1);
    }
    else if(dist >= distmax){
        dist -= distmax;
    }
    return dist;
}

int main(int argc, char **argv){
    float minx = 0.0f;
    float miny = 0.0f;
    float bound = 100000.0f;
    float z = 50000.0f;
    float minvx = -1000.0f;
    float minvy = -1000.0f;
    float maxvx = 1000.0f;
    float maxvy = 1000.0f;
    float xparts = 0;
    float yparts = 0;
    float dx = 0;
    float dy = 0;
    int pid = 0;
    int blklen = 256;
    int NumPart = 1024;
    float purturbmax = 10000.0f;
    float newloc[2];
    float randx = randFloat(1.0,-1.0);
    float randy = randFloat(1.0,-1.0);
    float *funcres = (float*)calloc(sizeof(float),2);

    #define WSKIP fwrite(&blklen, sizeof(int), 1, wfile);
    FILE *wfile;

    returnstruct rs = handleGetOpt(argc, argv);
    header h = rs.h;
    xparts = 32.0f;//(float)(h.npart[2]);
    yparts = 32.0f;//(float)(h.npart[3]);
    h.npart[1] = NumPart;
    //NumPart = (int)(xparts*yparts);
    h.npart[2] = 0;
    h.npart[3] = 0;
    dx = bound/(xparts);
    dy = bound/(yparts);
    printHeader(h);
    srand(time(NULL));
    int ignore = rand();
    particle P[h.npart[1]];
    for(int y = 0; y < (int)yparts; y++){
        for(int x = 0; x < (int)xparts; x++){
            randx = randFloat(2.0,-2.0);
            randy = randFloat(2.0,-2.0);
            pid = y * ((int)xparts) + x;
            P[pid].Pos[0] = randx;
            P[pid].Pos[1] = randy;
            P[pid].Pos[2] = z;
            P[pid].Vel[0] = randFloat(maxvx,minvx);
            P[pid].Vel[1] = randFloat(maxvy,minvy);
            P[pid].Vel[2] = 0.0f;
            P[pid].ID = pid + 1;
            applyFn(P[pid].Pos[0],P[pid].Pos[1],NULL,NULL,funcres);
            P[pid].Pos[0] = funcres[0];
            P[pid].Pos[1] = funcres[1];
            P[pid].Pos[0] = coordpurturb(P[pid].Pos[0], purturbmax, bound);
            P[pid].Pos[1] = coordpurturb(P[pid].Pos[1], purturbmax, bound);
        }
    }
    free(funcres);
    /*for(int i = 0; i < h.npart[1]; i++){
        printf("Particle Number %d: X: %f Y: %f VX: %f VY: %f\n\n",P[i].ID,P[i].Pos[0],P[i].Pos[1],P[i].Vel[0],P[i].Vel[1]);
    }*/

    if((wfile = fopen(rs.filename,"wb"))){
        WSKIP;
        fwrite(&h,sizeof(io_header),1,wfile);
        WSKIP;
        WSKIP;
        for(int i = 0; i < NumPart; i++){
            fwrite(&P[i].Pos, sizeof(float), 3, wfile);
        }
        WSKIP;
        WSKIP;
        for(int i = 0; i < NumPart; i++){
            fwrite(&P[i].Vel, sizeof(float), 3, wfile);
        }
        WSKIP;
        WSKIP;
        for(int i = 0; i < NumPart; i++){
            fwrite(&P[i].ID, sizeof(int), 1, wfile);
        }
        WSKIP;
    }
    //free(P);
    //freeHeader(h);
    return 0;
}
