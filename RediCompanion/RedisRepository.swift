//
//  RedisRepository.swift
//  RediCompanion
//
//  Created by Inder Dhir on 1/3/21.
//

import RediStack
import NIO
import Foundation

enum RedisError: Error {
    case noConnection, noKeysFound, valueMissing, other
}

final class RedisRepository {

    private var connection: RedisConnection?
    private var items: [(String, RedisItem)] = []

    init(eventLoop: EventLoop) throws {
        connection = try RedisConnection.make(
            configuration: try .init(hostname: "127.0.0.1"),
            boundEventLoop: eventLoop
        ).wait()
    }

    func getItems(eventLoopGroup: EventLoopGroup) -> EventLoopFuture<[(String, RedisItem)]> {
        guard let connection = connection else { return eventLoopGroup.next().makeSucceededFuture([]) }

//        EventLoopFuture.reduce(T##initialResult: _##_, <#T##futures: [EventLoopFuture<InputValue>]##[EventLoopFuture<InputValue>]#>, on: <#T##EventLoop#>, <#T##nextPartialResult: (_, InputValue) -> _##(_, InputValue) -> _#>)

        items.removeAll()
        return connection.scan()
            .flatMap { [weak self] scanResult in
                guard let `self` = self else { return eventLoopGroup.next().makeSucceededFuture([]) }

                let promise = eventLoopGroup.next().makePromise(of: [(String, RedisItem)].self)
                self.populateItems(scanResult.1[0...], overallResult: promise, eventLoop: eventLoopGroup.next())
                return promise.futureResult
            }
    }

    private func populateItems(
        _ remaining: ArraySlice<String>,
        overallResult: EventLoopPromise<[(String, RedisItem)]>,
        eventLoop: EventLoop
    ) {
        var remaining = remaining
        guard let key = remaining.popFirst() else {
            return overallResult.succeed(items)
        }

        connection?.send(command: "type", with: [RESPValue(from: key)])
            .flatMapThrowing { [weak self] respValue -> EventLoopFuture<Void> in
                guard let `self` = self else { throw RedisError.other }

                guard case let .simpleString(byteBuffer) = respValue,
                    let byteBufferStr = byteBuffer.getString(at: 0, length: byteBuffer.capacity),
                    let redisType = RedisItemType(rawValue: byteBufferStr)
                    else { throw RedisError.valueMissing }

                return try! self.getValue(for: key, type: redisType, eventLoop: eventLoop)
            }
            .map { [weak self, remaining] _ in
                self?.populateItems(remaining, overallResult: overallResult, eventLoop: eventLoop)
            }.whenFailure { error in
                overallResult.fail(error)
            }
    }

    private func getValue(for key: String, type: RedisItemType, eventLoop: EventLoop) throws -> EventLoopFuture<Void> {
        guard let connection = connection else { throw RedisError.noConnection }

        let redisKey = RedisKey(key)
        switch type {
        case .string:
            return connection.get(redisKey)
                .flatMapThrowing { [weak self] value in
                    guard case let .bulkString(bb) = value,
                          let byteBuffer = bb,
                          let byteBufferStr = byteBuffer.getString(at: 0, length: byteBuffer.capacity)
                          else { throw RedisError.valueMissing }

                    self?.items.append((key, RedisItem(type: type, name: key, value: byteBufferStr)))
                }
        case .list:
            return connection.llen(of: redisKey)
                .flatMapThrowing { length in
                    connection.lrange(from: redisKey, indices: 0...length - 1)
                        .whenSuccess { [weak self] values in
                            let redisValues = values.compactMap { value -> String? in
                                guard case let .bulkString(bb) = value,
                                      let byteBuffer = bb,
                                      let byteBufferStr = byteBuffer.getString(at: 0, length: byteBuffer.capacity)
                                        else { return nil }
                                return byteBufferStr
                            }
                            self?.items.append((key, RedisItem(type: type, name: key, value: redisValues.description)))
                        }
                }
        case .set:
            return connection.smembers(of: redisKey)
                .flatMapThrowing { [weak self] values in
                    let redisValues = values.compactMap { value -> String? in
                        guard case let .bulkString(bb) = value,
                              let byteBuffer = bb,
                              let byteBufferStr = byteBuffer.getString(at: 0, length: byteBuffer.capacity)
                                else { return nil }
                        return byteBufferStr
                    }
                    self?.items.append((key, RedisItem(type: type, name: key, value: redisValues.description)))
                }
        case .zset:
            return connection.zrange(from: redisKey, fromIndex: 0)
                .flatMapThrowing { [weak self] values in
                    let redisValues = values.compactMap { value -> String? in
                        guard case let .bulkString(bb) = value,
                              let byteBuffer = bb,
                              let byteBufferStr = byteBuffer.getString(at: 0, length: byteBuffer.capacity)
                                else { return nil }
                        return byteBufferStr
                    }
                    self?.items.append((key, RedisItem(type: type, name: key, value: redisValues.description)))
                }
        case .hash:
            return connection.hgetall(from: redisKey)
                .flatMapThrowing { [weak self] entries in
                    let printableEntries = entries.compactMapValues { value -> String? in
                        guard case let .bulkString(bb) = value,
                              let byteBuffer = bb,
                              let byteBufferStr = byteBuffer.getString(at: 0, length: byteBuffer.capacity)
                                else { return nil }
                        return byteBufferStr
                    }
                    self?.items.append((key, RedisItem(type: type, name: key, value: printableEntries.description)))
                }
//        case .stream:
//            // TODO:
        default:
            return eventLoop.makeSucceededFuture(())
        }
    }
}
