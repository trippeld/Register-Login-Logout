//
//  Post.swift
//  Wip
//
//  Created by Daniel Douglas Dyrseth on 16/10/2017.
//  Copyright © 2017 Lightpear. All rights reserved.
//

import Foundation

struct Authenticate: Encodable {
    let username: String
    let password: String
}

struct Register: Encodable {
    let username: String
    let email: String
    let password: String
}

struct JWT: Decodable {
    let success: Bool
    let token: String
}

struct Response: Decodable {
    let success: Bool
    let msg: String
}
