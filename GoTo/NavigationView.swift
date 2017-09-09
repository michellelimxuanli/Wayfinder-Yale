//
//  NavigationView.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import UIKit


class NavigationView: UIView {
    @IBOutlet var topLevelCustomView: UIView!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var confirmLocation: UIButton!
    
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
        let nib = UINib(nibName: "CustomView", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        topLevelCustomView.frame = bounds
        addSubview(topLevelCustomView)
        
    }
    var title: String? {
        get { return instruction?.text }
        set { instruction.text = newValue }
    }
}
