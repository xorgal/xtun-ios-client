//
//  LogsView.swift
//  xtun-ios-client
//
//  Created by xorgal on 24/08/2023.
//

import SwiftUI

struct LogsView: View {
    @EnvironmentObject var model: TunnelViewModel
    var body: some View {
        ScrollViewReader { scrollView in
            List {
                ForEach(model.log.logs, id: \.id) { logEntry in
                    VStack(alignment: .leading, spacing: 4) {
                        let logTitle = logEntry.isNEMessage ? " - Network Ext." : " - App"
                        Text(logEntry.timestamp + logTitle)
                            .bold()
                        Text(logEntry.message)
                    }
                    .padding(.vertical, 2)
                }
                Spacer().frame(height: 50)
            }
            .onChange(of: model.log.logs) { logs in
                if let last = logs.last {
                    withAnimation {
                        scrollView.scrollTo(last.id, anchor: .center)
                    }
                }
            }
            .onAppear(perform: {
                if let last = model.log.logs.last {
                    withAnimation {
                        scrollView.scrollTo(last.id, anchor: .center)
                    }
                }
            })
        }
    }
}

extension LogService.LogEntry: Equatable {
    static func ==(lhs: LogService.LogEntry, rhs: LogService.LogEntry) -> Bool {
        return lhs.id == rhs.id
    }
}

struct LogsView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var model = TunnelViewModel()
        ZStack {
             BackgroundView()
            LogsView().environmentObject(model)
        }
    }
}
