# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/TransformerFcn/D_Yg.mo (function)
# The 32 coefficients [Ar, Ai, MB1r, ..., D33i] of the hybrid positive-sequence/three-phase pi model of a D_Yg
# transformer, argument order (X, R, tap) as in the .mo; a Vector of 32 in Julia. Norton equivalent impedances
# assumed infinite (the _FinImp variants take them finite). Named TransformerFcn_D_Yg in Julia: the family repeats
# the names of TransfConnection (package rule 6.5). Transcribed literally; omitted: the documentation annotation.

function TransformerFcn_D_Yg(X, R, tap)
    sGser = (1/tap/sqrt(3))*(R/(R*R + X*X))
    sBser = (1/tap/sqrt(3))*(-X/(R*R + X*X))
    mGser = (1/tap/sqrt(3))*(-R/(R*R + X*X))
    mBser = (1/tap/sqrt(3))*(X/(R*R + X*X))
    sGshk = ((2/3/tap/tap) - (1/tap/sqrt(3)))*(R/(R*R + X*X))
    sBshk = ((2/3/tap/tap) - (1/tap/sqrt(3)))*(-X/(R*R + X*X))
    mGshk = ((1/3/tap/tap))*(-R/(R*R + X*X))
    mBshk = ((1/3/tap/tap))*(X/(R*R + X*X))
    nGshk = ((1/sqrt(3)/tap) - (1/3/tap/tap))*(R/(R*R + X*X))
    nBshk = ((1/sqrt(3)/tap) - (1/3/tap/tap))*(-X/(R*R + X*X))
    sGshm = (1 - (1/tap/sqrt(3)))*(R/(R*R + X*X))
    sBshm = (1 - (1/tap/sqrt(3)))*(-X/(R*R + X*X))
    mGshm = (1/tap/sqrt(3))*(R/(R*R + X*X))
    mBshm = (1/tap/sqrt(3))*(-X/(R*R + X*X))
    Gaaser = sGser
    Baaser = sBser
    Gabser = 0
    Babser = 0
    Gacser = mGser
    Bacser = mBser
    Gbaser = mGser
    Bbaser = mBser
    Gbbser = sGser
    Bbbser = sBser
    Gbcser = 0
    Bbcser = 0
    Gcaser = 0
    Bcaser = 0
    Gcbser = mGser
    Bcbser = mBser
    Gccser = sGser
    Bccser = sBser
    Gaaser2 = Gaaser
    Baaser2 = Baaser
    Gabser2 = Gbaser
    Babser2 = Bbaser
    Gacser2 = Gcaser
    Bacser2 = Bcaser
    Gbaser2 = Gabser
    Bbaser2 = Babser
    Gbbser2 = Gbbser
    Bbbser2 = Bbbser
    Gbcser2 = Gcbser
    Bbcser2 = Bcbser
    Gcaser2 = Gacser
    Bcaser2 = Bacser
    Gcbser2 = Gbcser
    Bcbser2 = Bbcser
    Gccser2 = Gccser
    Bccser2 = Bccser
    Gaask = sGshk
    Baask = sBshk
    Gabsk = mGshk
    Babsk = mBshk
    Gacsk = nGshk
    Bacsk = nBshk
    Gbask = nGshk
    Bbask = nBshk
    Gbbsk = sGshk
    Bbbsk = sBshk
    Gbcsk = mGshk
    Bbcsk = mBshk
    Gcask = mGshk
    Bcask = mBshk
    Gcbsk = nGshk
    Bcbsk = nBshk
    Gccsk = sGshk
    Bccsk = sBshk
    Gaasm = sGshm
    Baasm = sBshm
    Gabsm = mGshm
    Babsm = mBshm
    Gacsm = 0
    Bacsm = 0
    Gbasm = 0
    Bbasm = 0
    Gbbsm = sGshm
    Bbbsm = sBshm
    Gbcsm = mGshm
    Bbcsm = mBshm
    Gcasm = mGshm
    Bcasm = mBshm
    Gcbsm = 0
    Bcbsm = 0
    Gccsm = sGshm
    Bccsm = sBshm
    G1 = (Gaask + Gaaser + Gbbsk + Gbbser + Gccsk + Gccser)/3
    B1 = (Baask + Baaser + Bbbsk + Bbbser + Bccsk + Bccser)/3
    G2 = (Gbask + Gbaser + Gacsk + Gacser + Gcbsk + Gcbser)/3
    B2 = (Bbask + Bbaser + Bacsk + Bacser + Bcbsk + Bcbser)/3
    G3 = (Gabsk + Gabser + Gbcsk + Gbcser + Gcask + Gcaser)/3
    B3 = (Babsk + Babser + Bbcsk + Bbcser + Bcask + Bcaser)/3
    Ar = (2*G1 - G2 - sqrt(3)*B2 - G3 + sqrt(3)*B3)/2
    Ai = (2*B1 - B2 + sqrt(3)*G2 - B3 - sqrt(3)*G3)/2
    MB1r = -(2*Gaaser - Gbaser - sqrt(3)*Bbaser - Gcaser + sqrt(3)*Bcaser)/6
    MB1i = -(2*Baaser - Bbaser + sqrt(3)*Gbaser - Bcaser - sqrt(3)*Gcaser)/6
    MB2r = -(2*Gabser - Gbbser - sqrt(3)*Bbbser - Gcbser + sqrt(3)*Bcbser)/6
    MB2i = -(2*Babser - Bbbser + sqrt(3)*Gbbser - Bcbser - sqrt(3)*Gcbser)/6
    MB3r = -(2*Gacser - Gbcser - sqrt(3)*Bbcser - Gccser + sqrt(3)*Bccser)/6
    MB3i = -(2*Bacser - Bbcser + sqrt(3)*Gbcser - Bccser - sqrt(3)*Gccser)/6
    C1r = -(2*Gaaser2 - Gabser2 + sqrt(3)*Babser2 - Gacser2 - sqrt(3)*Bacser2)/2
    C1i = -(2*Baaser2 - Babser2 - sqrt(3)*Gabser2 - Bacser2 + sqrt(3)*Gacser2)/2
    C2r = -(2*Gbaser2 - Gbbser2 + sqrt(3)*Bbbser2 - Gbcser2 - sqrt(3)*Bbcser2)/2
    C2i = -(2*Bbaser2 - Bbbser2 - sqrt(3)*Gbbser2 - Bbcser2 + sqrt(3)*Gbcser2)/2
    C3r = -(2*Gcaser2 - Gcbser2 + sqrt(3)*Bcbser2 - Gccser2 - sqrt(3)*Bccser2)/2
    C3i = -(2*Bcaser2 - Bcbser2 - sqrt(3)*Gcbser2 - Bccser2 + sqrt(3)*Gccser2)/2
    D11r = Gaaser2 + Gaasm
    D11i = Baaser2 + Baasm
    D12r = Gabser2 + Gabsm
    D12i = Babser2 + Babsm
    D13r = Gacser2 + Gacsm
    D13i = Bacser2 + Bacsm
    D21r = Gbaser2 + Gbasm
    D21i = Bbaser2 + Bbasm
    D22r = Gbbser2 + Gbbsm
    D22i = Bbbser2 + Bbbsm
    D23r = Gbcser2 + Gbcsm
    D23i = Bbcser2 + Bbcsm
    D31r = Gcaser2 + Gcasm
    D31i = Bcaser2 + Bcasm
    D32r = Gcbser2 + Gcbsm
    D32i = Bcbser2 + Bcbsm
    D33r = Gccser2 + Gccsm
    D33i = Bccser2 + Bccsm
    [Ar, Ai, MB1r, MB1i, MB2r, MB2i, MB3r, MB3i, C1r, C1i, C2r, C2i, C3r, C3i, D11r, D11i, D12r, D12i, D13r, D13i,
     D21r, D21i, D22r, D22i, D23r, D23i, D31r, D31i, D32r, D32i, D33r, D33i]
end
