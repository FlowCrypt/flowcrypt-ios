//
//  WebServerManager.swift
//  FlowCrypt
//
//  Created by Techrechard on 05/02/25
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    

import Telegraph

class WebServerManager {
    static let shared = WebServerManager()
    private var server: Server?

    private init() {}

    func startServer() {
        // Create an HTTP server
        server = Server()
        
        // Start the server on HTTPS port 80
        try? server?.start(port: 80)
    }

    func stopServer() {
        server?.stop()
    }
}
