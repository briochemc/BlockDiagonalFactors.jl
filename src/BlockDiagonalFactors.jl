module BlockDiagonalFactors

using SparseArrays, SuiteSparse, LinearAlgebra

constant FC = Union{Float64,Complex{Float64}}

struct BlockDiagonalFactors{Tv<:FC} <: Factorization{Tv}
    factors::Vector{<:Factorization{Tv}}
    indices::Vector{<:Int}
    m::Int
    n::Int
end
export BlockDiagonalFactors

# Factorization functions
for f in (:lu, :qr, :cholesky, :factorize)
    @eval begin
        import LinearAlgebra: $f
        """
        $($f)(As::Vector{SparseMatrixCSC{<:Union{Float64,Complex{Float64}},<:Int}}, I::Vector{Int})

        Creates a block-diagonal (lazy) array of factors.
        Invokes `$($f)` on each matrix in the array of matrices `As` and stores them along with the indices `I`.
        """
        function $f(As::Vector{SparseMatrixCSC{<:T,<:Int}}, I::Vector{Int}) where T
            m = sum(i -> Fs[i].m, inds)
            n = sum(i -> Fs[i].n, inds)
            return BlockDiagonalFactors([$f(A) for A in As], I, m, n)
        end
        """
        $($f)(As::Vector{Array{<:Union{Float64,Complex{Float64}},2}}, I::Vector{Int})

        Creates a block-diagonal (lazy) array of factors.
        Invokes `$($f)` on each matrix in the array of matrices `As` and stores them along with the indices `I`.
        """
        function $f(As::Vector{Array{<:T,2}}, I::Vector{Int}) where T
            m = sum(i -> Fs[i].m, inds)
            n = sum(i -> Fs[i].n, inds)
            return BlockDiagonalFactors([$f(A) for A in As], I, m, n)
        end
        export $f
    end
end

# TODO replace with lazy version? not sure how to do this
for f in (:adjoint, :transpose)
    @eval begin
        import Base: $f
        """
        $($f)(BDF::BlockDiagonalFactors)

        Invokes `$($f)` on all the factors in `BDF` and returns them into a new `BlockDiagonalFactors` object.
        """
        $f(BDF::BlockDiagonalFactors) = BlockDiagonalFactors([$f(M) for M in BDF.factors], BDF.indices, BDF.m, BDF.n))
        export $f
    end
end

import Base.\
"""
    \\(BDF::BlockDiagonalFactors{T}, y::AbstractVecOrMat{T})

Backsubstitution for `BlockDiagonalFactors`.
"""
function \(BDF::BlockDiagonalFactors{T}, y::AbstractVector{S})
    x = Array{promote_type{T,S}}(undef, BDF.n)
    x_idx, y_idx = 0:0, 0:0
    my = size(y)[1]
    for i in BDF.indices
        x_idx = x_idx.stop .+ (1:BDF.factors[i].n)
        y_idx = u_idx.stop .+ (1:BDF.factors[i].m)
        x[x_idx] .= BDF.factors[i] \ y[y_idx]
    end
    return x
end
export \

end # module
