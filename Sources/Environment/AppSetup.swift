//
//  AppSetup.swift
//  Ello
//
//  Created by Sean Dougherty on 11/21/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import SwiftyUserDefaults

public class AppSetup {
    public struct Size {
        public static let calculatorHeight = CGFloat(20)
    }

    public var isTesting = false
    private var _isSimulator: Bool?
    public var isSimulator: Bool {
        get { return _isSimulator ?? (UIDevice.currentDevice().name == "iPhone Simulator" || UIDevice.currentDevice().name == "iPad Simulator") }
        set {
            if newValue == true {
                _isSimulator = nil
            }
            else {
                _isSimulator = false
            }
        }
    }

    public class var sharedState: AppSetup {
        struct Static {
            static let instance = AppSetup()
        }
        return Static.instance
    }

    public init() {
        if NSClassFromString("XCTest") != nil {
            isTesting = true
        }
    }

}
