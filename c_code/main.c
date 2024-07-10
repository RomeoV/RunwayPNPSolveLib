#include <stdio.h>
#include <stdlib.h>

// Julia headers (for initialization and gc commands)
#include "julia_init.h"
#include "runwaypnpsolve.h"

int main(int argc, char *argv[])
{
    init_julia(argc, argv);

    int ret;
    double dst_pos[3] = {0., 0., 0.};
    double dst_cov[9] = {0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.};


    double rwylength = 3500.0;  // m
    double rwywidth = 61.0;  // m
    double rwycorners[3*4] = {0.0, -rwywidth / 2, 0.0,
                              0.0, +rwywidth / 2, 0.0,
                              rwylength, +rwywidth / 2, 0.0,
                              rwylength, -rwywidth / 2, 0.0};

    // we got these from the julia code
    // double truepos[3] = {-4000., 10., 400.};
    double measuredprojs[2*4] = {
	   74.01856336432996, -731.0475394007898,
	  -37.466186394290474, -731.0475394007898,
	  -19.98196607695492, -389.8920210137545,
	   39.476567127642646, -389.8920210137545
    };

    int n_rwycorners = 4;
    ret = predict_pose_c_interface(dst_pos, dst_cov,
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
        printf("fail :(\n");
    }

    // Cleanup and gracefully exit
done:
    shutdown_julia(ret);
    return ret;
}
