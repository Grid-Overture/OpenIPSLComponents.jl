# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/MonoTriFcn/Inverse.mo (function)
# Inverse of a 3x3 complex matrix in closed form, by cofactors over the complex determinant A + jB. The .mo passes
# the matrix as a 1x18 row [r11, x11, r12, x12, ..., r33, x33]; in Julia it is a Vector of 18 with the same order,
# so the .mo index [1, k] is [k] here. Transcribed literally; omitted: the documentation annotation.

function Inverse(I)
    a11 = I[1]
    b11 = I[2]
    a12 = I[3]
    b12 = I[4]
    a13 = I[5]
    b13 = I[6]
    a21 = I[7]
    b21 = I[8]
    a22 = I[9]
    b22 = I[10]
    a23 = I[11]
    b23 = I[12]
    a31 = I[13]
    b31 = I[14]
    a32 = I[15]
    b32 = I[16]
    a33 = I[17]
    b33 = I[18]
    A = (a13*a21*a32 - a13*b21*b32 - b13*a21*b32 - b13*b21*a32 + a12*a23*a31 - a12*b23*b31 - b12*a23*b31
         - b12*b23*a31 + a11*a22*a33 - a11*b22*b33 - b11*a22*b33 - b11*b22*a33
         - (a33*a21*a12 - a33*b21*b12 - b33*a21*b12 - b33*b21*a12)
         - (a11*a23*a32 - a11*b23*b32 - b11*a23*b32 - b11*b23*a32)
         - (a13*a22*a31 - a13*b22*b31 - b13*a22*b31 - b13*b22*a31))
    B = (a13*a21*b32 + a13*b21*a32 + b13*a21*a32 - b13*b21*b32 + a12*a23*b31 + a12*b23*a31 + b12*a23*a31
         - b12*b23*b31 + a11*a22*b33 + a11*b22*a33 + b11*a22*a33 - b11*b22*b33
         - (a33*a21*b12 + a33*b21*a12 + b33*a21*a12 - b33*b21*b12)
         - (a11*a23*b32 + a11*b23*a32 + b11*a23*a32 - b11*b23*b32)
         - (a13*a22*b31 + a13*b22*a31 + b13*a22*a31 - b13*b22*b31))
    r11 = (A*(a22*a33 - a32*a23 - b22*b33 + b32*b23) + B*(a22*b33 + b22*a33 - a32*b23 - b32*a23))/(A*A + B*B)
    x11 = (A*(a22*b33 + b22*a33 - a32*b23 - b32*a23) - B*(a22*a33 - a32*a23 - b22*b33 + b32*b23))/(A*A + B*B)
    r12 = (A*(a13*a32 - a12*a33 - b13*b32 + b12*b33) + B*(a13*b32 + b13*a32 - a12*b33 - b12*a33))/(A*A + B*B)
    x12 = (A*(a13*b32 + b13*a32 - a12*b33 - b12*a33) - B*(a13*a32 - a12*a33 - b13*b32 + b12*b33))/(A*A + B*B)
    r13 = (A*(a12*a23 - a13*a22 - b12*b23 + b13*b22) + B*(a12*b23 + b12*a23 - a13*b22 - b13*a22))/(A*A + B*B)
    x13 = (A*(a12*b23 + b12*a23 - a13*b22 - b13*a22) - B*(a12*a23 - a13*a22 - b12*b23 + b13*b22))/(A*A + B*B)
    r21 = (A*(a23*a31 - a21*a33 - b23*b31 + b21*b33) + B*(a23*b31 + b23*a31 - a21*b33 - b21*a33))/(A*A + B*B)
    x21 = (A*(a23*b31 + b23*a31 - a21*b33 - b21*a33) - B*(a23*a31 - a21*a33 - b23*b31 + b21*b33))/(A*A + B*B)
    r22 = (A*(a11*a33 - a13*a31 - b11*b33 + b13*b31) + B*(a11*b33 + b11*a33 - a13*b31 - b13*a31))/(A*A + B*B)
    x22 = (A*(a11*b33 + b11*a33 - a13*b31 - b13*a31) - B*(a11*a33 - a13*a31 - b11*b33 + b13*b31))/(A*A + B*B)
    r23 = (A*(a13*a21 - a11*a23 - b13*b21 + b11*b23) + B*(a13*b21 + b13*a21 - a11*b23 - b11*a23))/(A*A + B*B)
    x23 = (A*(a13*b21 + b13*a21 - a11*b23 - b11*a23) - B*(a13*a21 - a11*a23 - b13*b21 + b11*b23))/(A*A + B*B)
    r31 = (A*(a21*a32 - a22*a31 - b21*b32 + b22*b31) + B*(a21*b32 + b21*a32 - a22*b31 - b22*a31))/(A*A + B*B)
    x31 = (A*(a21*b32 + b21*a32 - a22*b31 - b22*a31) - B*(a21*a32 - a22*a31 - b21*b32 + b22*b31))/(A*A + B*B)
    r32 = (A*(a12*a31 - a11*a32 - b12*b31 + b11*b32) + B*(a12*b31 + b12*a31 - a11*b32 - b11*a32))/(A*A + B*B)
    x32 = (A*(a12*b31 + b12*a31 - a11*b32 - b11*a32) - B*(a12*a31 - a11*a32 - b12*b31 + b11*b32))/(A*A + B*B)
    r33 = (A*(a11*a22 - a12*a21 - b11*b22 + b12*b21) + B*(a11*b22 + b11*a22 - a12*b21 - b12*a21))/(A*A + B*B)
    x33 = (A*(a11*b22 + b11*a22 - a12*b21 - b12*a21) - B*(a11*a22 - a12*a21 - b11*b22 + b12*b21))/(A*A + B*B)
    [r11, x11, r12, x12, r13, x13, r21, x21, r22, x22, r23, x23, r31, x31, r32, x32, r33, x33]
end
