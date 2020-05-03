//
//  GameCollectionViewCell.swift
//  OldTwitch
//
//  Created by Tyler Stickler on 5/2/20.
//  Copyright © 2020 Tyler Stickler. All rights reserved.
//

import Foundation
import UIKit

class GameCell: UICollectionViewCell {
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    
    var game: GameViewModel! {
        didSet {
            gameImage.image = game.image
            gameLabel.text = game.name
            viewCountLabel.text = game.viewers
        }
    }
}
