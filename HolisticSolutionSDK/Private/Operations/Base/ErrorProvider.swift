//
//  ErrorProvider.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 07.06.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation


protocol ErrorProvider {
    var error: HSError? { get }
}
