//
//  CustomView.swift
//  GoTo
//
//  Created by Michelle Lim on 9/5/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import UIKit

class CustomView: UIView {

    @IBOutlet var topLevelCustomView: CustomView!
    @IBOutlet weak var roomTitle: UILabel!
    @IBOutlet weak var DirectionsButton: UIButton!
    
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
        get { return roomTitle?.text }
        set { roomTitle.text = newValue }
    }
}
