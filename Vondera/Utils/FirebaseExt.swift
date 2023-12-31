//
//  FirebaseExt.swift
//  Vondera
//
//  Created by Shreif El Sayed on 16/10/2023.
//

import Foundation
import FirebaseFirestore


extension DocumentReference {
    func getDocument<T>(as type: T.Type) async throws -> (item : T, exists : Bool) where T : Decodable {
        let doc = try await self.getDocument()
        let item = try doc.data(as: type)
        
        return (item, doc.exists)
    }
}

extension Query {
    
    func startAfter(lastDocument:DocumentSnapshot?) -> Query {
        if let snapshot = lastDocument {
            return self.start(afterDocument: snapshot)
        }
        
        return self
    }
    
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T : Decodable {
        try await getDocumentWithLastSnapshot(as: type).items
    }
    
    func getDocumentWithLastSnapshot<T>(as type: T.Type) async throws -> (items: [T], lastDocument: DocumentSnapshot?) where T : Decodable {
        
        let snapshot = try await self.getDocuments()
        let items =  try snapshot.documents.map({ document in
            try document.data(as: T.self)
        })
        
        return(items,snapshot.documents.last)
    }
}
