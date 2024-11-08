//
//  NotificationExtension.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 10/31/24
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

public extension Notification.Name {
    static var reloadThreadList: Notification.Name {
        return .init(rawValue: "ThreadList.Reload")
    }
}
