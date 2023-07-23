//
//  Get.swift
//  Rainbow
//
//  Created by Daniel Douglas Dyrseth on 04/01/2018.
//  Copyright © 2018 Lightpear. All rights reserved.
//

import Foundation

struct Profile: Decodable {
    let user: user
}

struct user: Decodable {
    let username: String
    let email: String
}
