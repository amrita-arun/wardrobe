//
//  RepositoryProtocol.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

protocol Repository {
    associatedtype T
    
    func fetch(id: String) async throws -> T
    func fetchAll(userId: String) async throws -> [T]
    func save(_ item: T) async throws
    func update(_ item: T) async throws
    func delete(id: String) async throws
}
