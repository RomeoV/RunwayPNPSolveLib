## Workflow

### Making the C library
Here's how you can generate the library. Takes 10 minutes or so.
```julia
$ julia --project=.
julia> import Pkg
julia> Pkg.instantiate()
julia> include("scripts/make_library.jl")
```

### Compiling the c code
Now you can just use this in your C code. Check [the example](./c_code/main.c)
To compile and run the example:
```bash
# from directory `c_code`
# compile 
cc -I../RunwayPNPSolveLibrary_compiled/include -L../RunwayPNPSolveLibrary_compiled/lib -lrunwaypnpsolve main.c -o main
# run 
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../RunwayPNPSolveLibrary_compiled/lib ./main 
```
or just
```bash
# from directory `c_code`
chmod +x compile_and_run
./compile_and_run
```

Either will yield
```bash
$ ./compile_and_run
success
Array elements: -4000.00 10.00 400.00 
Covar elements: [
279.33 -0.63 -25.05 
-0.63 0.12 0.06 
-25.05 0.06 2.36 
]
```
which effectively solves the problem and writes the results into a c-array.

Good luck!
