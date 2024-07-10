module RunwayPNPSolveLibrary
	using Unitful
	using Unitful
	import Unitful: Units, Quantity
	using Unitful.DefaultSymbols
	using RunwayLib
	# using RunwayLib: WithUnits
	using GeodesyXYZExt: XYZ
	using Rotations
	# using UnitfulAngles
	using Distributions
	using LinearAlgebra
	using ProbabilisticParameterEstimators
	# import ProbabilisticParameterEstimators.NonlinearSolve: LevenbergMarquardt
	# using StaticArrays
	# using StructArrays
	# using OhMyThreads
	# using MvNormalCalibration
	# using Plots, StatsPlots, PGFPlotsX
	# using Random
	# using TimerOutputs
	# import ProbabilisticParameterEstimators.Turing
	using SimpleNonlinearSolve: SimpleNewtonRaphson
	#using Underscores
	# using DelimitedFiles
  import Base: unsafe_convert

  include("with_dims.jl")

"""
rwylength = 3500.0m
rwywidth = 61.0m
rwycorners = XYZ.([[0m,        -rwywidth / 2, 0m],
                   [0m,        +rwywidth / 2, 0m],
                   [rwylength, +rwywidth / 2, 0m],
                   [rwylength, -rwywidth / 2, 0m]])
"""
function f3(x::XYZ{<:WithUnits(m)}, p, rot=zeros(3))::ImgProj
  @assert length(p) == 3
	pos = XYZ(p)*m
	rot = RotXYZ(rot...)
	ustrip.(pxl, project(CamTransform(rot, pos), x))
end

function mksimplenewtonraphson(; autodiff=false)
    SimpleNewtonRaphson()
end

Base.@ccallable function predict_pose_c_interface(
        dst_pos_ptr::Ptr{Float64}, dst_cov_ptr::Ptr{Float64},
        truepos_ptr::Ptr{Float64},
        rwycorners_ptr::Ptr{Float64}, n_rwycorners::Cint,
        measuredprojs_ptr::Ptr{Float64})::Cint
    try
        predict_pose(dst_pos_ptr, dst_cov_ptr, truepos_ptr, rwycorners_ptr,
                     n_rwycorners, measuredprojs_ptr)
    catch
        return 1
    end
    return 0
end

function predict_pose(
        dst_pos_ptr::Ptr{Float64}, dst_cov_ptr::Ptr{Float64},
        truepos_ptr::Ptr{Float64},
        rwycorners_ptr::Ptr{Float64}, n_rwycorners::Cint,
        measuredprojs_ptr::Ptr{Float64})

    truepos = XYZ(unsafe_wrap(Vector{Float64}, truepos_ptr, 3))*m
    posprior = ustrip.(m, truepos) + MvNormal(zeros(3), Diagonal([1000.0^2, 200^2, 100^2]))
    truerot = RotXYZ(0,0,0)

    rwycorners_flat = unsafe_wrap(Vector{Float64}, rwycorners_ptr, 3*n_rwycorners)
    rwycorners = [XYZ(rwycorners_flat[(1:3) .+ offset])*m
                  for offset in 0:3:(3*n_rwycorners-1)]
    measuredprojs_flat = unsafe_wrap(Vector{Float64}, measuredprojs_ptr, 2*n_rwycorners)
    measuredprojs = [ImgProj(measuredprojs_flat[(1:2) .+ offset])*pxl
                     for offset in 0:2:(2*n_rwycorners-1)]

    trueprojs = project.([CamTransform(truerot, truepos)], rwycorners)
    noisedistrs = [MvNormal(zeros(2), 1*(I(2)))
                   for _ in eachindex(rwycorners)]
    noisemodel = UncorrGaussianNoiseModel(noisedistrs)
    #Σ = [if i==j; 1; elseif ((i - j) % 2 == 0); 0.7; else; 0; end
    #     for i in 1:8, j in 1:8]
    #D = MvNormal(zeros(8), 2*I(8)*Σ)
    #noisemodel = CorrGaussianNoiseModel(D)

    # estlin  = LinearApproxEstimator( solvealg=mksimplenewtonraphson, solveargs=(; maxiters=100))
    estlin  = LinearApproxEstimator( solvealg=mksimplenewtonraphson, solveargs=(;maxiters=10_000))
    measuredprojs_ = map(xs->ustrip.(xs), measuredprojs)
    distr_lin  = predictdist(estlin, f3, rwycorners, measuredprojs_, posprior, noisemodel)

    dst_pos_wrap = unsafe_wrap(Vector{Float64}, dst_pos_ptr, 3)
    dst_cov_wrap = unsafe_wrap(Vector{Float64}, dst_cov_ptr, 9)
    dst_pos_wrap .= mean(distr_lin)
    dst_cov_wrap .= cov(distr_lin)[:]
end

# function test_interface()
#     dst_pos = zeros(3);
#     dst_pos_ptr = unsafe_convert(Ptr{Float64}, dst_pos)
#     dst_cov = zeros(9);
#     dst_cov_ptr = unsafe_convert(Ptr{Float64}, dst_cov)

#     truepos = Float64[-4000., 10, 400]
#     truepos_ptr = unsafe_convert(Ptr{Float64}, truepos)

#     rwylength = 3500.0m
#     rwywidth = 61.0m
#     rwycorners = XYZ.([[0m,        -rwywidth / 2, 0m],
#                        [0m,        +rwywidth / 2, 0m],
#                        [rwylength, +rwywidth / 2, 0m],
#                        [rwylength, -rwywidth / 2, 0m]])
#     rwycorners_flat = ustrip.(m, vcat(Vector.(rwycorners)...))
#     rwycorners_ptr = unsafe_convert(Ptr{Float64}, rwycorners_flat)


#     truerot = RotXYZ(0,0,0)
#     trueprojs = project.([CamTransform(truerot, XYZ(truepos)*m)], rwycorners)
#     noisedistrs = [MvNormal(zeros(2), 1e0*(I(2)))
#                    for _ in eachindex(rwycorners)]
#     # measuredprojs = trueprojs .+ [rand(D)pxl for D in noisedistrs]
#     measuredprojs = trueprojs
#     measuredprojs_flat = ustrip.(pxl, vcat(Vector.(measuredprojs)...))
#     @show measuredprojs_flat
#     return
#     measuredprojs_ptr = unsafe_convert(Ptr{Float64}, measuredprojs_flat) 

#     n_rwycorners = convert(Cint, length(rwycorners))
#     predict_pose_c_interface(dst_pos_ptr, dst_cov_ptr, truepos_ptr,
#                              rwycorners_ptr, n_rwycorners,
#                              measuredprojs_ptr)
#     MvNormal(dst_pos, reshape(dst_cov, 3, 3))
# end


greet() = print("Hello World!")

end # module RunwayPNPSolveLibrary
