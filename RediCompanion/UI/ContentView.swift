//
//  ContentView.swift
//  RediCompanion
//
//  Created by Inder Dhir on 1/3/21.
//

import SwiftUI

struct ContentView: View {

    enum RefreshInterval: Int, CaseIterable, Identifiable {
        case five = 5
        case fifteen = 15
        case thirty = 30
        case sixty = 60

        var id: Int { self.rawValue }
    }

    @ObservedObject private var viewModel = MainViewModel()
    @State private var selectedRefreshInterval = RefreshInterval.fifteen {
        didSet { viewModel.refreshInterval = TimeInterval(selectedRefreshInterval.rawValue) }
    }

    var body: some View {
        VStack {
            HStack {
                Toggle("Auto refresh", isOn: $viewModel.isRefreshing)
                    .toggleStyle(SwitchToggleStyle())
                    .padding()

                Picker(selection: $selectedRefreshInterval, label: Text("Interval"), content: {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text("\(interval.rawValue) seconds")
                            .tag(interval)
                    }
                })
                .disabled(!viewModel.isRefreshing)
                .fixedSize()
            }

            if viewModel.items.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List(viewModel.items.map { $0.1 }, id: \.self) {
                    RedisItemView(item: $0)
                }
                .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            ContentView().colorScheme(.dark)
        }
    }
}

