//
//  GenericError.swift
//  VoW
//
//  Created by Sumit Anantwar on 01/08/2021.
//  Copyright © 2021 Vox SpA. All rights reserved.
//

import Foundation

struct GenericError : Error {
    
    private let description: String
    init(_ description: String) {
        self.description = description
    }
    
    var localizedDescription: String {
        return description
    }
}
