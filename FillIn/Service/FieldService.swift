//
//  FieldService.swift
//  FillIn
//
//  Created by Shatrya Christiano on 04/06/26.
//

import Foundation
import FirebaseFirestore

class FieldService {
    private let db = Firestore.firestore()

    func fetchFields() async throws -> [Field] {
        let snapshot = try await db.collection("fields").getDocuments()
        return snapshot.documents.compactMap {
            Field.fromDictionary($0.data(), id: $0.documentID)
        }
    }
}
