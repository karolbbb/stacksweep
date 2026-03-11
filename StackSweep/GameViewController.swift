//
//  GameViewController.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private var scenePresented = false

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = self.view as? SKView else { return }
        skView.ignoresSiblingOrder = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !scenePresented, let skView = self.view as? SKView else { return }

        let sceneSize = skView.bounds.size
        let menu = MenuScene(size: sceneSize)
        menu.scaleMode = .aspectFill
        skView.presentScene(menu)
        scenePresented = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool { true }
}
