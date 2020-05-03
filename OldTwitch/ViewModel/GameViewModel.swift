//
//  GameViewModel.swift
//  OldTwitch
//
//  Created by Tyler Stickler on 5/2/20.
//  Copyright © 2020 Tyler Stickler. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import PromiseKit

class GameViewModel {
    let name: String
    let viewers: String
    var image: UIImage?
    private let game: Game

    init(game: Game) {
        name = game.name
        viewers = "\(game.viewers) viewers"
        self.game = game
    }
    
    // Handles fetching box art for the game from internet
    // Passes result back through compeltion handler
    func getImage(completion: @escaping (UIImage?, Error?) -> Void) {
        Service.shared.fetchBoxArt(fromUrl: game.gameArt) {
            [unowned self] data, err in
            if let error = err {
                completion(nil, error)
            }
            
            guard let data = data else { return }
            self.image = UIImage(data: data)
            completion(self.image, nil)
        }
    }
}
