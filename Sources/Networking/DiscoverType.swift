//
//  DiscoverType.swift
//  Ello
//
//  Created by Colin Gray on 2/23/2016.
//  Copyright (c) 2016 Ello. All rights reserved.
//

public enum DiscoverType: String {
    case Featured = "recommended"
    case Trending = "trending"
    case Recent = "recent"

    public var slug: String { return rawValue }
    public var name: String {
        switch self {
        case Featured: return InterfaceString.Discover.Featured
        case Trending: return InterfaceString.Discover.Trending
        case Recent: return InterfaceString.Discover.Recent
        }
    }
}
