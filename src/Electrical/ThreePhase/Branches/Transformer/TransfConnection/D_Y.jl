# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Transformer/TransfConnection/D_Y.mo (function)
# The 12x12 pi matrix [A B; C D] of a D_Y three-phase transformer, argument order (X, R, tap) as in the .mo.
# Named TransfConnection_D_Y in Julia: the nine connections repeat the names of the MonoTri TransformerFcn family
# (package rule 6.5). Transcribed literally from the declaration section of the .mo; omitted: the documentation
# annotation. The 1e-6 fillers of the off-diagonal blocks are the .mo values and are copied, not rounded to zero.

function TransfConnection_D_Y(X, R, tap)
    sGser = ((1/tap)/sqrt(3))*(R/(R*R + X*X))
    sBser = ((1/tap)/sqrt(3))*(-X/(R*R + X*X))
    mGser = ((1/tap)/sqrt(3))*(-R/(R*R + X*X))
    mBser = ((1/tap)/sqrt(3))*(X/(R*R + X*X))
    sGshk = ((2 - tap*sqrt(3))/(3*tap*tap))*(R/(R*R + X*X))
    sBshk = ((2 - tap*sqrt(3))/(3*tap*tap))*(-X/(R*R + X*X))
    mGshk = ((tap*sqrt(3) - 1)/(3*tap*tap))*(R/(R*R + X*X))
    mBshk = ((tap*sqrt(3) - 1)/(3*tap*tap))*(-X/(R*R + X*X))
    nGshk = ((-1)/(3*tap*tap))*(R/(R*R + X*X))
    nBshk = ((-1)/(3*tap*tap))*(-X/(R*R + X*X))
    sGshm = ((2*tap - sqrt(3))/(3*tap))*(R/(R*R + X*X))
    sBshm = ((2*tap - sqrt(3))/(3*tap))*(-X/(R*R + X*X))
    mGshm = (-1/3)*(R/(R*R + X*X))
    mBshm = (-1/3)*(-X/(R*R + X*X))
    nGshm = ((sqrt(3) - tap)/(3*tap))*(R/(R*R + X*X))
    nBshm = ((sqrt(3) - tap)/(3*tap))*(-X/(R*R + X*X))
    zero = 1e-6
    Y_ser1 = [sGser -sBser mGser -mBser zero zero;
              sBser sGser mBser mGser zero zero;
              zero zero sGser -sBser mGser -mBser;
              zero zero sBser sGser mBser mGser;
              mGser -mBser zero zero sGser -sBser;
              mBser mGser zero zero sBser sGser]
    Y_ser2 = [sGser -sBser zero zero mGser -mBser;
              sBser sGser zero zero mBser mGser;
              mGser -mBser sGser -sBser zero zero;
              mBser mGser sBser sGser zero zero;
              zero zero mGser -mBser sGser -sBser;
              zero zero mBser mGser sBser sGser]
    Yshtk = [sGshk -sBshk mGshk -mBshk nGshk -nBshk;
             sBshk sGshk mBshk mGshk nBshk nGshk;
             nGshk -nBshk sGshk -sBshk mGshk -mBshk;
             nBshk nGshk sBshk sGshk mBshk mGshk;
             mGshk -mBshk nGshk -nBshk sGshk -sBshk;
             mBshk mGshk nBshk nGshk sBshk sGshk]
    Yshtm = [sGshm -sBshm mGshm -mBshm nGshm -nBshm;
             sBshm sGshm mBshm mGshm nBshm nGshm;
             nGshm -nBshm sGshm -sBshm mGshm -mBshm;
             nBshm nGshm sBshm sGshm mBshm mGshm;
             mGshm -mBshm nGshm -nBshm sGshm -sBshm;
             mBshm mGshm nBshm nGshm sBshm sGshm]
    A = Y_ser1 + Yshtk
    B = -Y_ser1
    C = -Y_ser2
    D = Y_ser2 + Yshtm
    [A B; C D]
end
