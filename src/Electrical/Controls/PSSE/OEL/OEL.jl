# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/OEL/OEL.mo (model), blocks as subsystems:
#   IFDSetpoint                                 Modelica.Blocks.Sources.Constant (k = IFDdes)
#   imLimitedIntegrator, ...1, ...2, ...3       Modelica.Blocks.Continuous.LimIntegrator (outMin = Vmin,
#       outMax = Vmax, k = KMX, InitialOutput, y_start = 0, 6, 6 and 7.5 respectively)
#   comparisor                                  IF_comparisor (HighCurrentLimit = IFD3, MediumCurrentLimit = IFD2,
#                                                               LowCurrentLimit = IFD1)
#   add                                         Modelica.Blocks.Math.Add (k1 = -1)
#   multiSum                                    Modelica.Blocks.Math.MultiSum (nu = 4)
# Ports are plain variables (IFD in, VOEL out).
# The Julia name is `PSSE_OEL`: `OEL` is already `Electrical.Controls.PSAT.OEL.OEL` (rule 6.5, as PSSE_baseLoad).
# Two things reproduced and not fixed (rule 5, F-90): `TIME1`, `TIME2` and `TIME3` are declared and reach
# nothing, and three of the four integrators start at 6, 6 and 7.5 while their own limits are [Vmin, Vmax] =
# [-0.05, 0], so `VOEL` starts at 19.5 pu and acts as "no limit" for the exciter downstream.
# Omitted: graphical annotations.

@component function PSSE_OEL(; name, IFD1 = 1.1, IFD2 = 1.2, IFD3 = 1.5, TIME1 = 60, TIME2 = 30, TIME3 = 15,
        IFDdes = 1, Vmax = 0, Vmin = -0.05, KMX = 1)
    IFD1, IFD2, IFD3, TIME1, TIME2, TIME3, IFDdes, Vmax, Vmin, KMX =
        float.((IFD1, IFD2, IFD3, TIME1, TIME2, TIME3, IFDdes, Vmax, Vmin, KMX))
    n = (; IFD1, IFD2, IFD3, IFDdes, Vmax, Vmin, KMX)
    pars = @parameters begin
        IFD1 = IFD1, [description = "Low OEL limit"]
        IFD2 = IFD2, [description = "Medium OEL limit"]
        IFD3 = IFD3, [description = "High OEL limit"]
        TIME1 = TIME1, [description = "Timing for low OEL"]
        TIME2 = TIME2, [description = "Timimg for medium OEL"]
        TIME3 = TIME3, [description = "Timing for high OEL"]
        IFDdes = IFDdes, [description = "IFD setpoint"]
        Vmax = Vmax, [description = "Max. OEL output"]
        Vmin = Vmin, [description = "Min. OEL output"]
        KMX = KMX, [description = "Control constant"]
    end
    systems = @named begin
        IFDSetpoint = Constant(; k = n.IFDdes)
        imLimitedIntegrator = LimIntegrator(; outMin = n.Vmin, outMax = n.Vmax, k = n.KMX, y_start = 0,
            initType = :InitialOutput)
        comparisor = IF_comparisor(; HighCurrentLimit = n.IFD3, MediumCurrentLimit = n.IFD2, LowCurrentLimit = n.IFD1)
        imLimitedIntegrator1 = LimIntegrator(; outMin = n.Vmin, outMax = n.Vmax, k = n.KMX, y_start = 6,
            initType = :InitialOutput)
        imLimitedIntegrator2 = LimIntegrator(; outMin = n.Vmin, outMax = n.Vmax, k = n.KMX, y_start = 6,
            initType = :InitialOutput)
        imLimitedIntegrator3 = LimIntegrator(; outMin = n.Vmin, outMax = n.Vmax, k = n.KMX, y_start = 7.5,
            initType = :InitialOutput)
        add = Add(; k1 = -1)
        multiSum = MultiSum(; nu = 4)
    end
    vars = @variables begin
        IFD(t), [guess = 1.0, description = "Field current"]
        VOEL(t), [guess = 0.0, description = "OEL output"]
    end
    eqs = Equation[
        imLimitedIntegrator.u ~ comparisor.n1,    # connect(comparisor.n1, imLimitedIntegrator.u)
        imLimitedIntegrator1.u ~ comparisor.n2,   # connect(comparisor.n2, imLimitedIntegrator1.u)
        imLimitedIntegrator2.u ~ comparisor.n3,   # connect(comparisor.n3, imLimitedIntegrator2.u)
        imLimitedIntegrator3.u ~ comparisor.n4,   # connect(comparisor.n4, imLimitedIntegrator3.u)
        comparisor.p ~ add.y,                     # connect(add.y, comparisor.p)
        add.u2 ~ IFD,                             # connect(add.u2, IFD)
        add.u1 ~ IFDSetpoint.y,                   # connect(IFDSetpoint.y, add.u1)
        VOEL ~ multiSum.y,                        # connect(multiSum.y, VOEL)
        multiSum.u[1] ~ imLimitedIntegrator.y,    # connect(imLimitedIntegrator.y, multiSum.u[1])
        multiSum.u[2] ~ imLimitedIntegrator1.y,   # connect(imLimitedIntegrator1.y, multiSum.u[2])
        multiSum.u[3] ~ imLimitedIntegrator2.y,   # connect(imLimitedIntegrator2.y, multiSum.u[3])
        multiSum.u[4] ~ imLimitedIntegrator3.y,   # connect(imLimitedIntegrator3.y, multiSum.u[4])
    ]
    System(eqs, t, vars, pars; name, systems)
end
