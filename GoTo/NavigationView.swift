//
//  NavigationView.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import UIKit

protocol NavigateDialogDelegate {
    func didPressCancel(button:UIButton)
    func didPressStarting(button:UIButton)
}


class NavigationView: UIView {

    @IBOutlet var topLevelCustomView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmLocation: UIButton!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var loadingCircle: UIActivityIndicatorView!
    var delegate: NavigateDialogDelegate!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        // standard initialization logic
        let nib = UINib(nibName: "NavigationView", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        topLevelCustomView.frame = bounds
        
        loadingCircle.hidesWhenStopped = true
        loadingCircle.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        
        addSubview(topLevelCustomView)
    }
    
    func start(){
        confirmLocation.isHidden = true
        loadingCircle.startAnimating()
        instruction.text = "Loading route..."
    }
    
    func stop(){
        confirmLocation.isHidden = false
        loadingCircle.stopAnimating()
    }
    
    @IBAction func cancelClicked(_ sender: UIButton) {
        delegate.didPressCancel(button: sender)
    }
    @IBAction func confirmStarting(_ sender: UIButton) {
        delegate.didPressStarting (button: sender)
    }
    
}
