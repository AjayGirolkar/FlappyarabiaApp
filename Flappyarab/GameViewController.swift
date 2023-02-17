//
//  GameViewController.swift
//  Flappyarabia
//
//  Created by AdnanTech on 11/10/15.
//  Copyright (c) 2015 AdnanTech. All rights reserved.
//

import UIKit
import SpriteKit
class GameViewController: UIViewController, GameSceneDelegate {
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        if let skView = self.view as? SKView {
            if skView.scene == nil {
                
                // Create the scene
                let aspectRatio = skView.bounds.size.height / skView.bounds.size.width
                let scene = GameScene(size:CGSize(width: 320, height: 320 * aspectRatio), delegate: self, gameState: .MainMenu)
                
                skView.showsFPS = false
                skView.showsNodeCount = false
                skView.showsPhysics = false
                skView.ignoresSiblingOrder = true
                
                scene.scaleMode = .aspectFill
                
                skView.presentScene(scene)
                
                

            }
        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
          get {
              return true
          }
      }
    
    func screenshot() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 1.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()
        return image
        
    }
    
    func shareString(string: String, url: NSURL, image: UIImage) {
        let vc = UIActivityViewController(activityItems: [string, url, image], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    }
    
}
