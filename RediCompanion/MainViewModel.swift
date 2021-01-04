//
//  MainViewModel.swift
//  RediCompanion
//
//  Created by Inder Dhir on 1/3/21.
//

import NIO
import Combine
import Foundation

final class MainViewModel: ObservableObject {

    @Published var items: [(String, RedisItem)] = []
    var refreshInterval: TimeInterval = 15 {
        didSet { setupPolling() }
    }

    @Published var isRefreshing = true {
        didSet {
            if isRefreshing {
                setupPolling()
            } else {
                timer?.invalidate()
            }
        }
    }

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let redisRepo: RedisRepository?
    var timer: Timer?

    init() {
        redisRepo = try? RedisRepository(eventLoop: eventLoopGroup.next())
        setupPolling()
    }

    private func setupPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
            guard let `self` = self else { return }

            self.redisRepo?.getItems(eventLoopGroup: self.eventLoopGroup)
                .whenSuccess { newItems in
                    DispatchQueue.main.async {
                        self.items = newItems
                    }
                }
        })
        timer?.fire()
    }

    deinit {
        try? eventLoopGroup.syncShutdownGracefully()
        timer?.invalidate()
    }
}
