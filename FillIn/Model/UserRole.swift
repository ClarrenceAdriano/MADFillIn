//
//  UserRole.swift
//  FillIn
//
//  Created by Clarrence Adriano Hemeldan on 03/06/26.
//

import Foundation
 
enum UserRole: String, Codable {
    case user = "user"
    case fieldKeeper = "fieldKeeper"
    case superAdmin = "superAdmin"
}
