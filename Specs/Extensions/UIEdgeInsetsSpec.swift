//
//  UIEdgeInsetsSpec.swift
//  Ello
//
//  Created by Colin Gray on 6/17/2016.
//  Copyright (c) 2016 Ello. All rights reserved.
//

@testable import Ello
import Quick
import Nimble


class UIEdgeInsetsSpec: QuickSpec {
    override func spec() {
        describe("UIEdgeInsets") {
            describe("convenience initializers") {
                it("supports UIEdgeInsets(top:)") {
                    let insets = UIEdgeInsets(top: 10)
                    expect(insets.top) == 10
                    expect(insets.left) == 0
                    expect(insets.bottom) == 0
                    expect(insets.right) == 0
                }
                it("supports UIEdgeInsets(left:)") {
                    let insets = UIEdgeInsets(left: 10)
                    expect(insets.top) == 0
                    expect(insets.left) == 10
                    expect(insets.bottom) == 0
                    expect(insets.right) == 0
                }
                it("supports UIEdgeInsets(bottom:)") {
                    let insets = UIEdgeInsets(bottom: 10)
                    expect(insets.top) == 0
                    expect(insets.left) == 0
                    expect(insets.bottom) == 10
                    expect(insets.right) == 0
                }
                it("supports UIEdgeInsets(right:)") {
                    let insets = UIEdgeInsets(right: 10)
                    expect(insets.top) == 0
                    expect(insets.left) == 0
                    expect(insets.bottom) == 0
                    expect(insets.right) == 10
                }
            }
        }
    }
}
