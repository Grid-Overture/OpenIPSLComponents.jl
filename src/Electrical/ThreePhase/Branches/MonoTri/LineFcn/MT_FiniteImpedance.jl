# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/LineFcn/MT_FiniteImpedance.mo (function)
# As MT_InfiniteImpedances but with FINITE Norton equivalent admittances at the positive-sequence terminal, passed
# as the extra Vector of 18 `Y012` (g0, b0 at [1, 2], g1, b1 at [9, 10], g2, b2 at [17, 18]); argument order
# (Yser, Yshtk, Y012) as in the .mo. Uses Inverse, PositiveFilter and NegZerFilter of MonoTriFcn, exactly as the
# TransformerFcn._FinImp family. Transcribed literally; omitted: the documentation annotation.
# Two notes on the matrix `A = Yabcnrt + Yshtk` this function inverts first. (1) With the .mo's own defaults
# (`Y012 = 0` and all `Bsht = 0`, i.e. `Line_MT`'s shipped values) `A` is the NULL matrix and `Inverse(A)` divides
# by zero: every one of the 32 coefficients comes out NaN and `Line_MT(ModelType = 1)` is unusable as shipped
# (F-97, checked in test_MT_LineFcn.jl case c). (2) This is NOT the singularity of F-83: there it is `Yser`
# itself, the wye/delta circulant of a transformer, which has no zero-sequence path; a line whose series matrix
# has a non-zero diagonal is regular, and with finite `Y012` this function does tend to MT_InfiniteImpedances as
# 1/Y012 (case b).

function MT_FiniteImpedance(Yser, Yshtk, Y012)
    g0 = Y012[1]
    b0 = Y012[2]
    g1 = Y012[9]
    b1 = Y012[10]
    g2 = Y012[17]
    b2 = Y012[18]
    g11 = (g0 + g1 + g2)/3
    b11 = (b0 + b1 + b2)/3
    g12 = (2*g0 - g1 + b1*sqrt(3) - g2 - b2*sqrt(3))/6
    b12 = (2*b0 - g1*sqrt(3) - b1 + g2*sqrt(3) - b2)/6
    g13 = (2*g0 - g1 - b1*sqrt(3) - g2 + b2*sqrt(3))/6
    b13 = (2*b0 + g1*sqrt(3) - b1 - g2*sqrt(3) - b2)/6
    g21 = g13
    b21 = b13
    g22 = g11
    b22 = b11
    g23 = g12
    b23 = b12
    g31 = g12
    b31 = b12
    g32 = g13
    b32 = b13
    g33 = g11
    b33 = b11
    Yabcnrt = [g11, b11, g12, b12, g13, b13, g21, b21, g22, b22, g23, b23, g31, b31, g32, b32, g33, b33]
    A = Yabcnrt + Yshtk
    B = Inverse(A)
    C = Inverse(Yser)
    D = B + C
    E = Inverse(D)
    Yshtm2 = NegZerFilter(E)
    Ysernew = PositiveFilter(Yser)
    Yshtm = Yshtk
    Yshtmnew = Yshtm + Yshtm2
    Gaaser = Ysernew[1]
    Baaser = Ysernew[2]
    Gabser = Ysernew[3]
    Babser = Ysernew[4]
    Gacser = Ysernew[5]
    Bacser = Ysernew[6]
    Gbaser = Ysernew[7]
    Bbaser = Ysernew[8]
    Gbbser = Ysernew[9]
    Bbbser = Ysernew[10]
    Gbcser = Ysernew[11]
    Bbcser = Ysernew[12]
    Gcaser = Ysernew[13]
    Bcaser = Ysernew[14]
    Gcbser = Ysernew[15]
    Bcbser = Ysernew[16]
    Gccser = Ysernew[17]
    Bccser = Ysernew[18]
    Gaasht = Yshtmnew[1]
    Baasht = Yshtmnew[2]
    Gabsht = Yshtmnew[3]
    Babsht = Yshtmnew[4]
    Gacsht = Yshtmnew[5]
    Bacsht = Yshtmnew[6]
    Gbasht = Yshtmnew[7]
    Bbasht = Yshtmnew[8]
    Gbbsht = Yshtmnew[9]
    Bbbsht = Yshtmnew[10]
    Gbcsht = Yshtmnew[11]
    Bbcsht = Yshtmnew[12]
    Gcasht = Yshtmnew[13]
    Bcasht = Yshtmnew[14]
    Gcbsht = Yshtmnew[15]
    Bcbsht = Yshtmnew[16]
    Gccsht = Yshtmnew[17]
    Bccsht = Yshtmnew[18]
    G1 = (Gaasht + Gaaser + Gbbsht + Gbbser + Gccsht + Gccser)/3
    B1 = (Baasht + Baaser + Bbbsht + Bbbser + Bccsht + Bccser)/3
    G2 = (Gbasht + Gbaser + Gacsht + Gacser + Gcbsht + Gcbser)/3
    B2 = (Bbasht + Bbaser + Bacsht + Bacser + Bcbsht + Bcbser)/3
    G3 = (Gabsht + Gabser + Gbcsht + Gbcser + Gcasht + Gcaser)/3
    B3 = (Babsht + Babser + Bbcsht + Bbcser + Bcasht + Bcaser)/3
    Ar = (2*G1 - G2 - sqrt(3)*B2 - G3 + sqrt(3)*B3)/2
    Ai = (2*B1 - B2 + sqrt(3)*G2 - B3 - sqrt(3)*G3)/2
    MB1r = -(2*Gaaser - Gbaser - sqrt(3)*Bbaser - Gcaser + sqrt(3)*Bcaser)/6
    MB1i = -(2*Baaser - Bbaser + sqrt(3)*Gbaser - Bcaser - sqrt(3)*Gcaser)/6
    MB2r = -(2*Gabser - Gbbser - sqrt(3)*Bbbser - Gcbser + sqrt(3)*Bcbser)/6
    MB2i = -(2*Babser - Bbbser + sqrt(3)*Gbbser - Bcbser - sqrt(3)*Gcbser)/6
    MB3r = -(2*Gacser - Gbcser - sqrt(3)*Bbcser - Gccser + sqrt(3)*Bccser)/6
    MB3i = -(2*Bacser - Bbcser + sqrt(3)*Gbcser - Bccser - sqrt(3)*Gccser)/6
    C1r = -(2*Gaaser - Gabser + sqrt(3)*Babser - Gacser - sqrt(3)*Bacser)/2
    C1i = -(2*Baaser - Babser - sqrt(3)*Gabser - Bacser + sqrt(3)*Gacser)/2
    C2r = -(2*Gbaser - Gbbser + sqrt(3)*Bbbser - Gbcser - sqrt(3)*Bbcser)/2
    C2i = -(2*Bbaser - Bbbser - sqrt(3)*Gbbser - Bbcser + sqrt(3)*Gbcser)/2
    C3r = -(2*Gcaser - Gcbser + sqrt(3)*Bcbser - Gccser - sqrt(3)*Bccser)/2
    C3i = -(2*Bcaser - Bcbser - sqrt(3)*Gcbser - Bccser + sqrt(3)*Gccser)/2
    D11r = Gaaser + Gaasht
    D11i = Baaser + Baasht
    D12r = Gabser + Gabsht
    D12i = Babser + Babsht
    D13r = Gacser + Gacsht
    D13i = Bacser + Bacsht
    D21r = Gbaser + Gbasht
    D21i = Bbaser + Bbasht
    D22r = Gbbser + Gbbsht
    D22i = Bbbser + Bbbsht
    D23r = Gbcser + Gbcsht
    D23i = Bbcser + Bbcsht
    D31r = Gcaser + Gcasht
    D31i = Bcaser + Bcasht
    D32r = Gcbser + Gcbsht
    D32i = Bcbser + Bcbsht
    D33r = Gccser + Gccsht
    D33i = Bccser + Bccsht
    [Ar, Ai, MB1r, MB1i, MB2r, MB2i, MB3r, MB3i, C1r, C1i, C2r, C2i, C3r, C3i, D11r, D11i, D12r, D12i,
     D13r, D13i, D21r, D21i, D22r, D22i, D23r, D23i, D31r, D31i, D32r, D32i, D33r, D33i]
end
