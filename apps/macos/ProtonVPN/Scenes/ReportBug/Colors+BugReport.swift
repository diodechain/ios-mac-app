//
//  Created on 2022-02-10.
//
//  Copyright (c) 2022 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import BugReport
import ProtonCoreUIFoundations
import SwiftUI

public extension BugReport.Colors {
    init() {
        self.init(
            primary: Color(nsColor: ColorProvider.Primary),
            interactive: Color(nsColor: ColorProvider.InteractionNorm),
            interactiveSecondary: Color(nsColor: ColorProvider.InteractionNormActive),
            interactiveActive: Color(nsColor: ColorProvider.InteractionNormHover),
            interactiveDisabled: Color(nsColor: ColorProvider.InteractionWeak),
            textPrimary: Color(nsColor: ColorProvider.TextNorm),
            textSecondary: Color(nsColor: ColorProvider.TextWeak),
            textAccent: Color(nsColor: ColorProvider.TextHint),
            background: Color(nsColor: ColorProvider.BackgroundNorm),
            backgroundWeak: Color(nsColor: ColorProvider.BackgroundWeak),
            backgroundStrong: Color(nsColor: ColorProvider.BackgroundStrong),
            backgroundUpdateButton: Color(nsColor: ColorProvider.InteractionWeak),
            separator: Color(nsColor: ColorProvider.BorderWeak),
            qfIcon: Color(nsColor: ColorProvider.SignalWarning),
            externalLinkIcon: Color(nsColor: ColorProvider.TextHint)
        )
    }
}
