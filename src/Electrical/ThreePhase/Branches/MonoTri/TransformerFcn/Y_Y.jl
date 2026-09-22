# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/TransformerFcn/Y_Y.mo (function)
# The 32 coefficients [Ar, Ai, MB1r, ..., D33i] of the hybrid positive-sequence/three-phase pi model of a Y_Y
# transformer, argument order (X, R, tap) as in the .mo; a Vector of 32 in Julia. Norton equivalent impedances
# assumed infinite (the _FinImp variants take them finite). Named TransformerFcn_Y_Y in Julia: the family repeats
# the names of TransfConnection (package rule 6.5). Transcribed literally; omitted: the documentation annotation.

function TransformerFcn_Y_Y(X, R, tap)
    sGser = ((1/tap)/3)*(2*R/(R*R + X*X))
    sBser = ((1/tap)/3)*(-2*X/(R*R + X*X))
    mGser = ((1/tap)/3)*(-R/(R*R + X*X))
    mBser = ((1/tap)/3)*(X/(R*R + X*X))
    sGshk = ((1 - tap)/(3*tap*tap))*(2*R/(R*R + X*X))
    sBshk = ((1 - tap)/(3*tap*tap))*(-2*X/(R*R + X*X))
    mGshk = ((1 - tap)/(3*tap*tap))*(-R/(R*R + X*X))
    mBshk = ((1 - tap)/(3*tap*tap))*(X/(R*R + X*X))
    Gaaser = sGser
    Baaser = sBser
    Gabser = mGser
    Babser = mBser
    Gacser = mGser
    Bacser = mBser
    Gbaser = mGser
    Bbaser = mBser
    Gbbser = sGser
    Bbbser = sBser
    Gbcser = mGser
    Bbcser = mBser
    Gcaser = mGser
    Bcaser = mBser
    Gcbser = mGser
    Bcbser = mBser
    Gccser = sGser
    Bccser = sBser
    Gaask = sGshk
    Baask = sBshk
    Gabsk = mGshk
    Babsk = mBshk
    Gacsk = mGshk
    Bacsk = mBshk
    Gbask = mGshk
    Bbask = mBshk
    Gbbsk = sGshk
    Bbbsk = sBshk
    Gbcsk = mGshk
    Bbcsk = mBshk
    Gcask = mGshk
    Bcask = mBshk
    Gcbsk = mGshk
    Bcbsk = mBshk
    Gccsk = sGshk
    Bccsk = sBshk
    Gaasm = 0
    Baasm = 0
    Gabsm = 0
    Babsm = 0
    Gacsm = 0
    Bacsm = 0
    Gbasm = 0
    Bbasm = 0
    Gbbsm = 0
    Bbbsm = 0
    Gbcsm = 0
    Bbcsm = 0
    Gcasm = 0
    Bcasm = 0
    Gcbsm = 0
    Bcbsm = 0
    Gccsm = 0
    Bccsm = 0
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
    C1r = -(2*Gaaser - Gabser + sqrt(3)*Babser - Gacser - sqrt(3)*Bacser)/2
    C1i = -(2*Baaser - Babser - sqrt(3)*Gabser - Bacser + sqrt(3)*Gacser)/2
    C2r = -(2*Gbaser - Gbbser + sqrt(3)*Bbbser - Gbcser - sqrt(3)*Bbcser)/2
    C2i = -(2*Bbaser - Bbbser - sqrt(3)*Gbbser - Bbcser + sqrt(3)*Gbcser)/2
    C3r = -(2*Gcaser - Gcbser + sqrt(3)*Bcbser - Gccser - sqrt(3)*Bccser)/2
    C3i = -(2*Bcaser - Bcbser - sqrt(3)*Gcbser - Bccser + sqrt(3)*Gccser)/2
    D11r = Gaaser + Gaasm
    D11i = Baaser + Baasm
    D12r = Gabser + Gabsm
    D12i = Babser + Babsm
    D13r = Gacser + Gacsm
    D13i = Bacser + Bacsm
    D21r = Gbaser + Gbasm
    D21i = Bbaser + Bbasm
    D22r = Gbbser + Gbbsm
    D22i = Bbbser + Bbbsm
    D23r = Gbcser + Gbcsm
    D23i = Bbcser + Bbcsm
    D31r = Gcaser + Gcasm
    D31i = Bcaser + Bcasm
    D32r = Gcbser + Gcbsm
    D32i = Bcbser + Bcbsm
    D33r = Gccser + Gccsm
    D33i = Bccser + Bccsm
    [Ar, Ai, MB1r, MB1i, MB2r, MB2i, MB3r, MB3i, C1r, C1i, C2r, C2i, C3r, C3i, D11r, D11i, D12r, D12i, D13r, D13i,
     D21r, D21i, D22r, D22i, D23r, D23i, D31r, D31i, D32r, D32i, D33r, D33i]
end
