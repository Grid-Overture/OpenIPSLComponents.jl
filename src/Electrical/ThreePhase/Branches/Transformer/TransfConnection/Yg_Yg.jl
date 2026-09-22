# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Transformer/TransfConnection/Yg_Yg.mo (function)
# The 12x12 pi matrix [A B; C D] of a Yg_Yg three-phase transformer, argument order (X, R, tap) as in the .mo.
# Named TransfConnection_Yg_Yg in Julia: the nine connections repeat the names of the MonoTri TransformerFcn family
# (package rule 6.5). Transcribed literally from the declaration section of the .mo; omitted: the documentation
# annotation. The 1e-6 fillers of the off-diagonal blocks are the .mo values and are copied, not rounded to zero.

function TransfConnection_Yg_Yg(X, R, tap)
    Gser = (1/tap)*(R/(R*R + X*X))
    Bser = (1/tap)*(-X/(R*R + X*X))
    Gshk = (1/tap)*((1/tap) - 1)*(R/(R*R + X*X))
    Bshk = (1/tap)*((1/tap) - 1)*(-X/(R*R + X*X))
    Gshm = (1 - (1/tap))*(R/(R*R + X*X))
    Bshm = (1 - (1/tap))*(-X/(R*R + X*X))
    zero = 1e-6
    Y_ser = [Gser -Bser zero zero zero zero;
             Bser Gser zero zero zero zero;
             zero zero Gser -Bser zero zero;
             zero zero Bser Gser zero zero;
             zero zero zero zero Gser -Bser;
             zero zero zero zero Bser Gser]
    Yshtk = [Gshk -Bshk zero zero zero zero;
             Bshk Gshk zero zero zero zero;
             zero zero Gshk -Bshk zero zero;
             zero zero Bshk Gshk zero zero;
             zero zero zero zero Gshk -Bshk;
             zero zero zero zero Bshk Gshk]
    Yshtm = [Gshm -Bshm zero zero zero zero;
             Bshm Gshm zero zero zero zero;
             zero zero Gshm -Bshm zero zero;
             zero zero Bshm Gshm zero zero;
             zero zero zero zero Gshm -Bshm;
             zero zero zero zero Bshm Gshm]
    A = Y_ser + Yshtk
    B = -Y_ser
    C = -Y_ser
    D = Y_ser + Yshtm
    [A B; C D]
end
