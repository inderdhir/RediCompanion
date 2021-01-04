//
//  RedisItem.swift
//  RediCompanion
//
//  Created by Inder Dhir on 1/3/21.
//

struct RedisItem: Hashable, Equatable {
    var id: String { name }
    let type: RedisItemType
    let name: String
    let value: String
}
