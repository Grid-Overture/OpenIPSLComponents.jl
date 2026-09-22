# NOTICE — provenance and third-party attribution

`OpenIPSLComponents` is a **derivative work**. It is a class-by-class translation,
from Modelica to Julia/ModelingToolkit, of two libraries that other people wrote
and that are both distributed under the 3-Clause BSD License:

| Upstream | Covers | Licence | Copyright |
| --- | --- | --- | --- |
| [**OpenIPSL 3.1.0**](https://github.com/OpenIPSL/OpenIPSL) | the 320 classes under `src/Electrical`, `src/NonElectrical`, `src/Interfaces` and `src/Examples` | BSD-3-Clause | © 2016–2026 Prof. Luigi Vanfretti, AlsetLab, Troy, NY (formerly SmarTS Lab, Stockholm, Sweden) |
| [**Modelica Standard Library 4.0.0**](https://github.com/modelica/ModelicaStandardLibrary) | the 56 blocks under `src/Modelica` | BSD-3-Clause | © Modelica Association and contributors |

The translation is deliberately literal: class names, parameter names, variable
names, the equations and their order follow the `.mo` sources, quirks included.
Every file names the `.mo` it comes from on its first comment line.

**The modelling work is theirs.** What GridOverture contributes is the
translation into ModelingToolkit, the initialization and event handling that
Julia needs, and the validation of each class against a reference simulation.
That contribution is licensed under the Mozilla Public License 2.0 (`LICENSE`).
The terms below continue to apply to the upstream material it derives from.

**This project is not affiliated with, nor endorsed by, the OpenIPSL project,
AlsetLab, or the Modelica Association.** The name `OpenIPSLComponents` describes
what the library is a port of; it does not imply any endorsement by, or
association with, the copyright holders named above.

---

## 3-Clause BSD License — applies to the upstream material described above

Copyright © 2016–2026 Luigi Vanfretti, AlsetLab (OpenIPSL).
Copyright © Modelica Association and contributors (Modelica Standard Library).
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

## Reference simulations

The files under `test/oracle/` are sampled trajectories produced by running the
upstream Modelica models in [OpenModelica](https://openmodelica.org) 1.25 against
OpenIPSL 3.1.0. They are measurements used to check this port, and are
distributed with it for that purpose. OpenModelica is not redistributed here.
