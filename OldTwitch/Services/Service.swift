//
//  Service.swift
//  OldTwitch
//
//  Created by Tyler Stickler on 5/2/20.
//  Copyright © 2020 Tyler Stickler. All rights reserved.
//

import Foundation
import PromiseKit
import RxSwift
import RxCocoa

class Service {
    private let clientId = "2l4p5lpdpd0ajxvsn35csik7kz5o6d"
    private let baseUrl = "https://api.twitch.tv/kraken/games/top"
    
    static let shared = Service()
    let fetchResponse = BehaviorRelay(value: [Game]())
    
    public func fetchGames(numOfGames: Int, offsetBy offset: Int) {
        let queryString = "limit=\(numOfGames)&offset=\(offset)"
        let builtUrl = URL(string: "\(baseUrl)?\(queryString)")
        
        guard let url = builtUrl else {
            print("fetchGames: Could not build URL")
            return
        }
        
        firstly {
            URLSession.shared.dataTask(.promise,
                                       with: try buildUrlRquest(url: url))
                .validate()
        }.map {
            try JSONSerialization.jsonObject(with: $0.data, options: []) as? [String: Any]
        }.done { serializedJson in
            if let jsonAsDict = serializedJson {
                self.fetchResponse.accept(self.addGamesRetrieved(topGamesDict: jsonAsDict))
            }
        }.catch { error in
            print(error.localizedDescription)
        }
    }
    
    public func fetchBoxArt(fromUrl urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("fetchBoxArt: Could not build URL")
            return
        }
        
        firstly {
            URLSession.shared.dataTask(.promise,
                                       with: try buildUrlRquest(url: url))
                .validate()
        }.done { data in
            completion(data.data, nil)
        }.catch { error in
            completion(nil, error)
        }
    }
    
    // Handle creating url request to interact with twitch api
    private func buildUrlRquest(url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.twitchtv.v5+json", forHTTPHeaderField: "Accept")
        request.setValue(clientId, forHTTPHeaderField: "Client-ID")
        return request
    }
    
    private func addGamesRetrieved(topGamesDict: [String: Any]) -> [Game] {
        if let topGames = topGamesDict["top"] as? [[String: Any]] { // Array of top games
            
            // Collect information for each game
            var games = [Game]()
            for game in topGames {
                if let gameToAdd = createGameFromInfo(fromGame: game) {
                    games.append(gameToAdd)
                } else {
                    print("Error creating game: \(game)")
                }
            }
            
            return games
        } else {
            return [Game]()
        }
    }

    private func createGameFromInfo(fromGame game: [String: Any]) -> Game? {
        // Build game from dictionary
        if let gameInfo = game["game"] as? [String: Any],
            let gameName = gameInfo["name"] as? String,
            let gameViewers = game["viewers"] as? Int,
            let gameArt = gameInfo["box"] as? [String:String],
            let gameArtLarge = gameArt["large"] {
            
            return Game(name: gameName, viewers: gameViewers, gameArt: gameArtLarge)
        } else {
            return nil
        }
    }
}
