//
//  RedisItemType.swift
//  RediCompanion
//
//  Created by Inder Dhir on 1/3/21.
//

import SwiftUI

enum RedisItemType: String {
    case string, list, set, zset, hash, stream
}

extension RedisItemType {
    var color: Color {
        switch self {
        case .string:
            return .blue
        case .list:
            return .pink
        case .set:
            return .orange
        case .zset:
            return .gray
        case .hash:
            return .green
        case .stream:
            return .accentColor
        }
    }
}
