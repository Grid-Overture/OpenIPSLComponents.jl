# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Functions/div0protect.mo (function): c = a/max(b, eps) with eps = Modelica.Constants.small

div0protect(a, b) = a / max(b, Modelica.Constants.small)
