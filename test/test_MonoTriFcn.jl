# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# MonoTriFcn: Inverse, PositiveFilter, NegZerFilter (PLAN-09 step 6.1). No upstream Test covers them.
# All three take and return a 3x3 complex matrix flattened row-major into 18 reals, [r11, x11, r12, x12, ...];
# `m3` folds it back, which is what checks the flattening order.
@testset "MonoTriFcn" begin
    m3(v) = [v[6(i - 1) + 2j - 1] + im * v[6(i - 1) + 2j] for i in 1:3, j in 1:3]
    v18(M) = vcat([[real(M[i, j]), imag(M[i, j])] for i in 1:3 for j in 1:3]...)
    Z = [1.0+0.3im 0.2-0.1im 0.05+0.02im
         0.2-0.1im 1.1+0.35im 0.15+0.05im
         0.05+0.02im 0.15+0.05im 0.9+0.25im]
    Id = [1 0 0; 0 1 0; 0 0 1]

    # Inverse: the closed-form cofactor inverse of a regular complex 3x3
    @test maximum(abs, m3(Inverse(v18(Z))) * Z - Id) < 1e-14
    @test maximum(abs, Z * m3(Inverse(v18(Z))) - Id) < 1e-14
    # an unsymmetric matrix too, so that a transposed cofactor would be caught
    W = [2.0+1.0im 0.3+0.0im 0.1-0.4im; -0.2+0.5im 1.5-0.2im 0.6+0.1im; 0.4+0.0im -0.1+0.3im 1.8+0.7im]
    @test maximum(abs, m3(Inverse(v18(W))) * W - Id) < 1e-14

    # The two filters are the complementary projectors of the symmetrical-component decomposition
    P, N = PositiveFilter(v18(Z)), NegZerFilter(v18(Z))
    @test maximum(abs, m3(P) + m3(N) - Z) < 1e-14          # PositiveFilter(Z) + NegZerFilter(Z) = Z
    @test maximum(abs, m3(PositiveFilter(P)) - m3(P)) < 1e-14   # a positive-sequence matrix is left invariant
    @test maximum(abs, m3(NegZerFilter(N)) - m3(N)) < 1e-14
    @test maximum(abs, m3(PositiveFilter(N))) < 1e-14      # the two ranges do not overlap
    @test maximum(abs, m3(NegZerFilter(P))) < 1e-14
    # the filters are linear and do not depend on Z beyond the product
    @test maximum(abs, m3(PositiveFilter(v18(2.5 .* Z))) - 2.5 .* m3(P)) < 1e-14
end
