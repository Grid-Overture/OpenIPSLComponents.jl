# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/MonoTriFcn/PositiveFilter.mo (function)
# Positive-sequence filter of the Norton equivalent: the product C*Z with the fixed sequence matrix built from
# g0 = 0, g1 = 1, g2 = 0. Vectors of 18 as in Inverse.jl. Transcribed literally; omitted: the documentation
# annotation. PositiveFilter(Z) + NegZerFilter(Z) = Z.

function PositiveFilter(Z)
    g0 = 0
    b0 = 0
    g1 = 1
    b1 = 0
    g2 = 0
    b2 = 0
    c11 = (g0 + g1 + g2)/3
    d11 = (b0 + b1 + b2)/3
    c12 = (2*g0 - g1 - b1*sqrt(3) - g2 + b2*sqrt(3))/6
    d12 = (2*b0 + g1*sqrt(3) - b1 - g2*sqrt(3) - b2)/6
    c13 = (2*g0 - g1 + b1*sqrt(3) - g2 - b2*sqrt(3))/6
    d13 = (2*b0 - g1*sqrt(3) - b1 + g2*sqrt(3) - b2)/6
    c21 = c13
    d21 = d13
    c22 = c11
    d22 = d11
    c23 = c12
    d23 = d12
    c31 = c12
    d31 = d12
    c32 = c13
    d32 = d13
    c33 = c11
    d33 = d11
    r11 = Z[1]
    x11 = Z[2]
    r12 = Z[3]
    x12 = Z[4]
    r13 = Z[5]
    x13 = Z[6]
    r21 = Z[7]
    x21 = Z[8]
    r22 = Z[9]
    x22 = Z[10]
    r23 = Z[11]
    x23 = Z[12]
    r31 = Z[13]
    x31 = Z[14]
    r32 = Z[15]
    x32 = Z[16]
    r33 = Z[17]
    x33 = Z[18]
    g11 = c11*r11 - d11*x11 + c12*r21 - d12*x21 + c13*r31 - d13*x31
    b11 = c11*x11 + d11*r11 + c12*x21 + d12*r21 + c13*x31 + d13*r31
    g12 = c11*r12 - d11*x12 + c12*r22 - d12*x22 + c13*r32 - d13*x32
    b12 = c11*x12 + d11*r12 + c12*x22 + d12*r22 + c13*x32 + d13*r32
    g13 = c11*r13 - d11*x13 + c12*r23 - d12*x23 + c13*r33 - d13*x33
    b13 = c11*x13 + d11*r13 + c12*x23 + d12*r23 + c13*x33 + d13*r33
    g21 = c21*r11 - d21*x11 + c22*r21 - d22*x21 + c23*r31 - d23*x31
    b21 = c21*x11 + d21*r11 + c22*x21 + d22*r21 + c23*x31 + d23*r31
    g22 = c21*r12 - d21*x12 + c22*r22 - d22*x22 + c23*r32 - d23*x32
    b22 = c21*x12 + d21*r12 + c22*x22 + d22*r22 + c23*x32 + d23*r32
    g23 = c21*r13 - d21*x13 + c22*r23 - d22*x23 + c23*r33 - d23*x33
    b23 = c21*x13 + d21*r13 + c22*x23 + d22*r23 + c23*x33 + d23*r33
    g31 = c31*r11 - d31*x11 + c32*r21 - d32*x21 + c33*r31 - d33*x31
    b31 = c31*x11 + d31*r11 + c32*x21 + d32*r21 + c33*x31 + d33*r31
    g32 = c31*r12 - d31*x12 + c32*r22 - d32*x22 + c33*r32 - d33*x32
    b32 = c31*x12 + d31*r12 + c32*x22 + d32*r22 + c33*x32 + d33*r32
    g33 = c31*r13 - d31*x13 + c32*r23 - d32*x23 + c33*r33 - d33*x33
    b33 = c31*x13 + d31*r13 + c32*x23 + d32*r23 + c33*x33 + d33*r33
    [g11, b11, g12, b12, g13, b13, g21, b21, g22, b22, g23, b23, g31, b31, g32, b32, g33, b33]
end
