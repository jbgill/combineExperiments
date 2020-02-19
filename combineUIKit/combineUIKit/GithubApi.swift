//
//  GithubApi.swift
//  combineUIKit
//
//  Created by JB Gill on 2/13/20.
//  Copyright © 2020 JB Gill. All rights reserved.
//

import Foundation
import Combine

//  this is borrowed heavily from :  https://heckj.github.io/swiftui-notes/

enum APIFailureCondition: Error {
  case invalidServerResponse
}

struct GithubAPIUser: Decodable {
  let login: String
  let public_repos: Int
  let avatar_url: String
  let name: String?
}

struct GithubAPI {
  
  static func retrieveGithubUser(username: String) -> AnyPublisher<GithubAPIUser?, Never> {
    
    if username.count < 3 {
      return Just(nil).eraseToAnyPublisher()
    }
    let assembledURL = String("https://api.github.com/users/\(username)")
    let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
      .tryMap { data, response -> Data in
        guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
            throw APIFailureCondition.invalidServerResponse
        }
        return data
      }
      .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
      .map { userData -> GithubAPIUser? in
        userData
      }
      .replaceError(with: nil)
      .eraseToAnyPublisher()
    return publisher
  }
  
}
