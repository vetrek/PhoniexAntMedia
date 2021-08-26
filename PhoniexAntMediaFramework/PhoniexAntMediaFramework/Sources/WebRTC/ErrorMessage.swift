//
//  ErrorMessage.swift
//  VoW
//
//  Created by Jayesh Mardiya on 10/09/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct ErrorMessage: Codable {
    let type: String
    let error: ErrorPayload?

    init(type: String,
         error: ErrorPayload? = nil) {
        
        self.type = type
        self.error = error
    }
}
