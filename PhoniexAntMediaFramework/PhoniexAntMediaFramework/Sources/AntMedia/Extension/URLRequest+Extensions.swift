//
//  URLRequest+Extensions.swift
//  VoW
//
//  Created by Sumit Anantwar on 01/08/2021.
//  Copyright © 2021 Vox SpA. All rights reserved.
//

import Foundation

import Foundation

private let AUTH_HEADER_FIELD = "Authorization"
private let CONTENT_TYPE_HEADER_FIELD = "ContentType"

extension URLRequest {
    mutating func setAuthHeader(_ authString: String) {
        self.setValue(authString, forHTTPHeaderField: AUTH_HEADER_FIELD)
    }
    
    mutating func setContentTypeJson() {
        self.setValue("application/json", forHTTPHeaderField: CONTENT_TYPE_HEADER_FIELD)
    }
}
