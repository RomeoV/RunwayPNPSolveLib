// Julia headers (for initialization and gc commands)
#include "uv.h"
/* #include <julia.h> */


// prototype of the C entry points in our application
int predict_pose_c_interface(double*, double*, double*, double*, int, double*);
