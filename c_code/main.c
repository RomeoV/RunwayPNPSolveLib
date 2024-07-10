#include <stdio.h>
#include <stdlib.h>

// Julia headers (for initialization and gc commands)
#include "julia_init.h"
#include "runwaypnpsolve.h"
/* #include "librunwaypnpsolve.h" */

size_t len = 10;

int main(int argc, char *argv[])
{
    init_julia(argc, argv);

    int ret;
    double dst_pos[3] = {0., 0., 0.};
    double dst_cov[9] = {0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.};

    double truepos[3] = {-4000., 10., 400.};

    double rwylength = 3500.0;  // m
    double rwywidth = 61.0;  // m
    double rwycorners[3*4] = {0.0, -rwywidth / 2, 0.0,
                              0.0, +rwywidth / 2, 0.0,
                              rwylength, +rwywidth / 2, 0.0,
                              rwylength, -rwywidth / 2, 0.0};

    // we got these from the julia code
    double measuredprojs[2*4] = {
        73.36956521739131, -724.6376811594204,
        -37.13768115942029, -724.6376811594204,
        -19.806763285024154, -386.47342995169083,
        39.130434782608695, -386.47342995169083
    };

    int n_rwycorners = 4;
    ret = predict_pose_c_interface(dst_pos, dst_cov, truepos,
                                   rwycorners, n_rwycorners,
                                   measuredprojs);
    if (ret == 0) {
        printf("success\n");
        printf("Array elements: ");
        for (int i = 0; i < 3; i++) {
            printf("%.2f ", dst_pos[i]);
        }
        printf("\n");
        printf("Covar elements: [");
        printf("\n");
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                printf("%.2f ", dst_cov[3*i+j]);
            }
            printf("\n");
        }
        printf("]\n");
    } else {
        printf("fail :(");
    }

    // Cleanup and gracefully exit
done:
    shutdown_julia(ret);
    return ret;
}
