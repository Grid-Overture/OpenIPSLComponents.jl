# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/LineFcn/MT_InfiniteImpedances.mo (function)
# The 32 coefficients [Ar, Ai, MB1r, ..., D33i] of the hybrid positive-sequence/three-phase pi model of a
# transmission line, argument order (Yser, Ysht) as in the .mo; the two arguments and the result are Vectors in
# Julia, so the .mo index [1, k] is [k]. Norton equivalent admittances at the positive-sequence terminal assumed
# infinite (MT_FiniteImpedance takes them finite). The name is kept: `MT_InfiniteImpedances` is unique in the
# package, unlike the TransformerFcn family. Transcribed literally; omitted: the documentation annotation.
# With a diagonal `Yser = diag(1/(R + jX))` and `Ysht = 0` this returns exactly `TransformerFcn_Yg_Yg(X, R, 1)`:
# same closing formulas, and at `tap = 1` that transformer's shunt halves vanish (test_MT_LineFcn.jl, case a).

function MT_InfiniteImpedances(Yser, Ysht)
    Gaaser = Yser[1]
    Baaser = Yser[2]
    Gabser = Yser[3]
    Babser = Yser[4]
    Gacser = Yser[5]
    Bacser = Yser[6]
    Gbaser = Yser[7]
    Bbaser = Yser[8]
    Gbbser = Yser[9]
    Bbbser = Yser[10]
    Gbcser = Yser[11]
    Bbcser = Yser[12]
    Gcaser = Yser[13]
    Bcaser = Yser[14]
    Gcbser = Yser[15]
    Bcbser = Yser[16]
    Gccser = Yser[17]
    Bccser = Yser[18]
    Gaasht = Ysht[1]
    Baasht = Ysht[2]
    Gabsht = Ysht[3]
    Babsht = Ysht[4]
    Gacsht = Ysht[5]
    Bacsht = Ysht[6]
    Gbasht = Ysht[7]
    Bbasht = Ysht[8]
    Gbbsht = Ysht[9]
    Bbbsht = Ysht[10]
    Gbcsht = Ysht[11]
    Bbcsht = Ysht[12]
    Gcasht = Ysht[13]
    Bcasht = Ysht[14]
    Gcbsht = Ysht[15]
    Bcbsht = Ysht[16]
    Gccsht = Ysht[17]
    Bccsht = Ysht[18]
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
