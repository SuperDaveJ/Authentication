//
//  QuickLoginViewLifecycleHelper.swift
//  Authentication
//
//  Created by Dave Johnson on 1/17/18.
//  Copyright © 2018 Paycom. All rights reserved.
//

import Shared

class QuickLoginViewLifecycleHelper {
    var alreadyPrompted = false

    static let shared = QuickLoginViewLifecycleHelper()

    private init() {}
}
