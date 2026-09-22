# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Transformer/TransfConnection/D_D.mo (function)
# The 12x12 pi matrix [A B; C D] of a D_D three-phase transformer, argument order (X, R, tap) as in the .mo.
# Named TransfConnection_D_D in Julia: the nine connections repeat the names of the MonoTri TransformerFcn family
# (package rule 6.5). Transcribed literally from the declaration section of the .mo; omitted: the documentation
# annotation. The 1e-6 fillers of the off-diagonal blocks are the .mo values and are copied, not rounded to zero.

function TransfConnection_D_D(X, R, tap)
    sGser = ((1/tap)/3)*(2*R/(R*R + X*X))
    sBser = ((1/tap)/3)*(-2*X/(R*R + X*X))
    mGser = ((1/tap)/3)*(-R/(R*R + X*X))
    mBser = ((1/tap)/3)*(X/(R*R + X*X))
    sGshk = ((1 - tap)/(3*tap*tap))*(2*R/(R*R + X*X))
    sBshk = ((1 - tap)/(3*tap*tap))*(-2*X/(R*R + X*X))
    mGshk = ((1 - tap)/(3*tap*tap))*(-R/(R*R + X*X))
    mBshk = ((1 - tap)/(3*tap*tap))*(X/(R*R + X*X))
    Y_ser = [sGser -sBser mGser -mBser mGser -mBser;
             sBser sGser mBser mGser mBser mGser;
             mGser -mBser sGser -sBser mGser -mBser;
             mBser mGser sBser sGser mBser mGser;
             mGser -mBser mGser -mBser sGser -sBser;
             mBser mGser mBser mGser sBser sGser]
    Yshtk = [sGshk -sBshk mGshk -mBshk mGshk -mBshk;
             sBshk sGshk mBshk mGshk mBshk mGshk;
             mGshk -mBshk sGshk -sBshk mGshk -mBshk;
             mBshk mGshk sBshk sGshk mBshk mGshk;
             mGshk -mBshk mGshk -mBshk sGshk -sBshk;
             mBshk mGshk mBshk mGshk sBshk sGshk]
    Yshtm = zeros(6, 6)
    A = Y_ser + Yshtk
    B = -Y_ser
    C = -Y_ser
    D = Y_ser + Yshtm
    [A B; C D]
end
