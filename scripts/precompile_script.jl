using RunwayPNPSolveLibrary
using Unitful
import Unitful: Units, Quantity
using Unitful.DefaultSymbols
using RunwayLib
using GeodesyXYZExt: XYZ
using Rotations
using Distributions
using LinearAlgebra
using ProbabilisticParameterEstimators
using MKL
import Base: unsafe_convert

dst_pos = zeros(3);
dst_pos_ptr = unsafe_convert(Ptr{Float64}, dst_pos)
dst_cov = zeros(9);
dst_cov_ptr = unsafe_convert(Ptr{Float64}, dst_cov)

truepos = Float64[-4000., 10, 400]
truepos_ptr = unsafe_convert(Ptr{Float64}, truepos)

rwylength = 3500.0m
rwywidth = 61.0m
rwycorners = XYZ.([[0m,        -rwywidth / 2, 0m],
                   [0m,        +rwywidth / 2, 0m],
                   [rwylength, +rwywidth / 2, 0m],
                   [rwylength, -rwywidth / 2, 0m]])
rwycorners_flat = ustrip.(m, vcat(Vector.(rwycorners)...))
rwycorners_ptr = unsafe_convert(Ptr{Float64}, rwycorners_flat)


truerot = RotXYZ(0,0,0)
trueprojs = project.([CamTransform(truerot, XYZ(truepos)*m)], rwycorners)
noisedistrs = [MvNormal(zeros(2), 1e0*(I(2)))
               for _ in eachindex(rwycorners)]
# measuredprojs = trueprojs .+ [rand(D)pxl for D in noisedistrs]
measuredprojs = trueprojs
measuredprojs_flat = ustrip.(pxl, vcat(Vector.(measuredprojs)...))
measuredprojs_ptr = unsafe_convert(Ptr{Float64}, measuredprojs_flat) 

n_rwycorners = convert(Cint, length(rwycorners))
RunwayPNPSolveLibrary.predict_pose_c_interface(dst_pos_ptr, dst_cov_ptr, truepos_ptr,
                         rwycorners_ptr, n_rwycorners,
                         measuredprojs_ptr)
#Cint, (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Cint, Ptr{Float64}))
