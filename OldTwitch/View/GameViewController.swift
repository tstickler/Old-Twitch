//
//  GameViewController.swift
//  OldTwitch
//
//  Created by Tyler Stickler on 5/2/20.
//  Copyright © 2020 Tyler Stickler. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GameViewController: UIViewController {
    let disposeBag = DisposeBag()
    var gameViewModels = BehaviorRelay(value: [GameViewModel]())
    var alreadySeen = [String: Bool]()
    
    // Twitch API takes 2 query parameters for fetching top games
    // numOfGames is the number of games to be fetched from 0-100
    // offset is the distance from the top game to start fetching
    var offset = 0
    var numOfGames = 25
        
    @IBOutlet weak var gameCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameCollectionView.delegate = self
        gameCollectionView.dataSource = self
        
        subscribeToViewModel()
        subscribeToFetchGames()

        Service.shared.fetchGames(numOfGames: numOfGames, offsetBy: offset)
    }
    
    private func subscribeToViewModel() {
        // Reload collection view whenever move view models are added
        gameViewModels.asObservable().subscribe(onNext: {
            [unowned self] event in
            
            self.gameCollectionView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    private func subscribeToFetchGames() {
        // Create view models when games are fetched
        Service.shared.fetchResponse.asObservable().subscribe(onNext: {
            [unowned self] event in
            
            var currentGameViewModels = self.gameViewModels.value
            var newGames = event.map{ GameViewModel(game: $0) }
            newGames = self.discardAlreadySeenGames(fromNewGames: newGames)
            currentGameViewModels.append(contentsOf: newGames)
            self.gameViewModels.accept(currentGameViewModels)
            
            // Reducing offset by a few allows still fetching a game if was
            // on the edge of the previous group and moved up on viewer list this fetch.
            // discardAlreadySeen fuction will catch any duplicates this would create.
            let offsetGreaterThanZero = self.gameViewModels.value.count - 5 > 0
            self.offset = offsetGreaterThanZero ? self.gameViewModels.value.count - 5 : 0
        }).disposed(by: disposeBag)
    }
    
    // Checks new games fetched against dictionary to see if the game is unique
    private func discardAlreadySeenGames(fromNewGames newGames: [GameViewModel]) -> [GameViewModel] {
        var gamesToAdd = [GameViewModel]()
        for game in newGames {
            if alreadySeen[game.name] == nil {
                gamesToAdd.append(game)
                alreadySeen[game.name] = true
            }
        }
        return gamesToAdd
    }
}


extension GameViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameViewModels.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCell
        cell.game = gameViewModels.value[indexPath.row]
        
        // Request the view model fetch the image to display
        gameViewModels.value[indexPath.row].getImage() {
            image, err in
            if let error = err {
                print(error.localizedDescription)
            }
            
            guard let image = image else { return }
            cell.gameImage.image = image
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Fetch more games if the user scrolls to the bottom of the collection view
        if (indexPath.row == gameViewModels.value.count - 1) {
            Service.shared.fetchGames(numOfGames: numOfGames, offsetBy: offset)
        }
    }
    
    // Modifications can be made to this method to improve how cells display on different sized devices
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Num of cells per row and column
        let gameCellRowCount: CGFloat = 3.0
        let gameCellColCount: CGFloat = 3.5
        
        // Determines the total spacing around cells
        let gameFlowLayout = gameCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let horizontalSpaceBetweenCells = gameCellRowCount * gameFlowLayout.minimumInteritemSpacing
        let horizontalInsets = gameFlowLayout.sectionInset.left + gameFlowLayout.sectionInset.right
        let verticalSpaceBetweenCells = (gameCellColCount - 1) * gameFlowLayout.minimumLineSpacing
        let verticalInsets = gameFlowLayout.sectionInset.top + gameFlowLayout.sectionInset.bottom
        
        let cellWidthSpacing: CGFloat =  horizontalSpaceBetweenCells + horizontalInsets
        let cellHeightSpacing: CGFloat =  verticalSpaceBetweenCells + verticalInsets
        
        // Cell size
        let cellWidth = (gameCollectionView.bounds.width - cellWidthSpacing) / gameCellRowCount
        let cellHeight = (gameCollectionView.bounds.height - cellHeightSpacing) / gameCellColCount
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
