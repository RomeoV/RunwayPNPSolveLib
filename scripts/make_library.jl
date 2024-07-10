using PackageCompiler
create_library(".", "RunwayPNPSolveLibrary_compiled";
               lib_name="librunwaypnpsolve",
               precompile_execution_file="scripts/precompile_script.jl",
               # header_files=["RunwayPNPSolveLibrary/build/runwaypnpsolvelirary.h"]
               force=true,
               # filter_stdlibs=true,
               incremental=true,
               include_lazy_artifacts=true, include_transitive_dependencies = true,
              )

