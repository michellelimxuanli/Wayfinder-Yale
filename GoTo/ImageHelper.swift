//
//  ImageHelper.swift
//  GoTo
//
//  Created by Michelle Lim on 9/9/17.
//  Copyright © 2017 Michelle & Aadit. All rights reserved.
//

import Foundation
import UIKit

class ImageHelper {
    //from https://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
    public static func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: targetSize.width, height: targetSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
