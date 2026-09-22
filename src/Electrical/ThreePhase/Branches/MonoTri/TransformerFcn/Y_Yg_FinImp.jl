# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/TransformerFcn/Y_Yg_FinImp.mo (function)
# As TransformerFcn_Y_Yg but with FINITE Norton equivalent admittances, passed as the extra 1x18 argument Y012
# (G_0, B_0 at [1, 2], G_1, B_1 at [9, 10], G_2, B_2 at [17, 18]); a Vector of 18 in Julia, so [1, k] is [k].
# Uses Inverse, PositiveFilter and NegZerFilter of MonoTriFcn. Transcribed literally; omitted: the documentation
# annotation.

function TransformerFcn_Y_Yg_FinImp(X, R, tap, Y012)
    sGser = ((1/tap)/3)*(2*R/(R*R + X*X))
    sBser = ((1/tap)/3)*(-2*X/(R*R + X*X))
    mGser = ((1/tap)/3)*(-R/(R*R + X*X))
    mBser = ((1/tap)/3)*(X/(R*R + X*X))
    sGshk = ((1 - tap)/(3*tap*tap))*(2*R/(R*R + X*X))
    sBshk = ((1 - tap)/(3*tap*tap))*(-2*X/(R*R + X*X))
    mGshk = ((1 - tap)/(3*tap*tap))*(-R/(R*R + X*X))
    mBshk = ((1 - tap)/(3*tap*tap))*(X/(R*R + X*X))
    sGshm = ((3*tap - 2)/(3*tap))*(R/(R*R + X*X))
    sBshm = ((3*tap - 2)/(3*tap))*(-X/(R*R + X*X))
    mGshm = (1/(3*tap))*(R/(R*R + X*X))
    mBshm = (1/(3*tap))*(-X/(R*R + X*X))
    g0 = Y012[1]
    b0 = Y012[2]
    g1 = Y012[9]
    b1 = Y012[10]
    g2 = Y012[17]
    b2 = Y012[18]
    g11 = (g0 + g1 + g2)/3
    b11 = (b0 + b1 + b2)/3
    g12 = (2*g0 - g1 - b1*sqrt(3) - g2 + b2*sqrt(3))/6
    b12 = (2*b0 + g1*sqrt(3) - b1 - g2*sqrt(3) - b2)/6
    g13 = (2*g0 - g1 + b1*sqrt(3) - g2 - b2*sqrt(3))/6
    b13 = (2*b0 - g1*sqrt(3) - b1 + g2*sqrt(3) - b2)/6
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
    Yser = [sGser, sBser, mGser, mBser, mGser, mBser, mGser, mBser, sGser, sBser, mGser, mBser, mGser, mBser, mGser,
            mBser, sGser, sBser]
    Yshtk = [sGshk, sBshk, mGshk, mBshk, mGshk, mBshk, mGshk, mBshk, sGshk, sBshk, mGshk, mBshk, mGshk, mBshk,
             mGshk, mBshk, sGshk, sBshk]
    Yshtm = [sGshm, sBshm, mGshm, mBshm, mGshm, mBshm, mGshm, mBshm, sGshm, sBshm, mGshm, mBshm, mGshm, mBshm,
             mGshm, mBshm, sGshm, sBshm]
    A = Yabcnrt + Yshtk
    B = Inverse(A)
    C = Inverse(Yser)
    D = B + C
    E = Inverse(D)
    Yshtm2 = NegZerFilter(E)
    Ysernew = PositiveFilter(Yser)
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
    Gaasm = Yshtmnew[1]
    Baasm = Yshtmnew[2]
    Gabsm = Yshtmnew[3]
    Babsm = Yshtmnew[4]
    Gacsm = Yshtmnew[5]
    Bacsm = Yshtmnew[6]
    Gbasm = Yshtmnew[7]
    Bbasm = Yshtmnew[8]
    Gbbsm = Yshtmnew[9]
    Bbbsm = Yshtmnew[10]
    Gbcsm = Yshtmnew[11]
    Bbcsm = Yshtmnew[12]
    Gcasm = Yshtmnew[13]
    Bcasm = Yshtmnew[14]
    Gcbsm = Yshtmnew[15]
    Bcbsm = Yshtmnew[16]
    Gccsm = Yshtmnew[17]
    Bccsm = Yshtmnew[18]
    Gaask = Yshtk[1]
    Baask = Yshtk[2]
    Gabsk = Yshtk[3]
    Babsk = Yshtk[4]
    Gacsk = Yshtk[5]
    Bacsk = Yshtk[6]
    Gbask = Yshtk[7]
    Bbask = Yshtk[8]
    Gbbsk = Yshtk[9]
    Bbbsk = Yshtk[10]
    Gbcsk = Yshtk[11]
    Bbcsk = Yshtk[12]
    Gcask = Yshtk[13]
    Bcask = Yshtk[14]
    Gcbsk = Yshtk[15]
    Bcbsk = Yshtk[16]
    Gccsk = Yshtk[17]
    Bccsk = Yshtk[18]
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
