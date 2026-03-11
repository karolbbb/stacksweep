//
//  GameViewController.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    private var scenePresented = false

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let view = self.view as? SKView else { return }
        view.ignoresSiblingOrder = true
        view.showsFPS = true
        view.showsNodeCount = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !scenePresented, let view = self.view as? SKView else { return }
        // Use actual view size; fallback if layout not yet applied
        var sceneSize = view.bounds.size
        if sceneSize.width <= 0 || sceneSize.height <= 0 {
            sceneSize = CGSize(width: 375, height: 667)
        }
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .aspectFill
        view.presentScene(scene)
        scenePresented = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
