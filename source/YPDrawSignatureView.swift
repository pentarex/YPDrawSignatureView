// YPDrawSignatureView is open source
// Version 0.1.1
//
// Copyright (c) 2014 - 2016 Yuppielabel and the project contributors
// Available under the MIT license
//
// See https://github.com/yuppielabel/YPDrawSignatureView/blob/master/LICENSE for license information
// See https://github.com/yuppielabel/YPDrawSignatureView/blob/master/README.md for the list project contributors

import UIKit

@IBDesignable
public class YPDrawSignatureView: UIView {
    
    var delegate:YPDrawSignatureViewDelegate? // ADDED
    
    // MARK: - Public properties
    @IBInspectable public var strokeWidth: CGFloat = 2.0 {
        didSet {
            self.path.lineWidth = strokeWidth
        }
    }
    
    @IBInspectable public var strokeColor: UIColor = UIColor.blackColor() {
        didSet {
            self.strokeColor.setStroke()
        }
    }
    
    @IBInspectable public var signatureBackgroundColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.backgroundColor = signatureBackgroundColor
        }
    }
    
    // Computed Property returns true if the view actually contains a signature
    public var containsSignature: Bool {
        get {
            if self.path.empty {
                return false
            } else {
                return true
            }
        }
    }
    
    // MARK: - Private properties
    private var path = UIBezierPath()
    private var pts = [CGPoint](count: 5, repeatedValue: CGPoint())
    private var ctr = 0
    
    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = self.signatureBackgroundColor
        self.path.lineWidth = self.strokeWidth
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = self.signatureBackgroundColor
        self.path.lineWidth = self.strokeWidth
    }
    
    // MARK: - Draw
    override public func drawRect(rect: CGRect) {
        self.strokeColor.setStroke()
        self.path.stroke()
    }
    
    // MARK: - Touch handling functions
    override public func touchesBegan(touches: Set <UITouch>, withEvent event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.locationInView(self)
            self.ctr = 0
            self.pts[0] = touchPoint
            
            // ADDED
            if (self.delegate != nil) {
               self.delegate?.startedDrawing!()
            }
            
        }
    }
    
    override public func touchesMoved(touches: Set <UITouch>, withEvent event: UIEvent?) {
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.locationInView(self)
            self.ctr += 1
            self.pts[self.ctr] = touchPoint
            if (self.ctr == 4) {
                self.pts[3] = CGPointMake((self.pts[2].x + self.pts[4].x)/2.0, (self.pts[2].y + self.pts[4].y)/2.0)
                self.path.moveToPoint(self.pts[0])
                self.path.addCurveToPoint(self.pts[3], controlPoint1:self.pts[1], controlPoint2:self.pts[2])
                
                self.setNeedsDisplay()
                self.pts[0] = self.pts[3]
                self.pts[1] = self.pts[4]
                self.ctr = 1
            }
            
            self.setNeedsDisplay()
        }
    }
    
    override public func touchesEnded(touches: Set <UITouch>, withEvent event: UIEvent?) {
        if self.ctr == 0 {
            let touchPoint = self.pts[0]
            self.path.moveToPoint(CGPointMake(touchPoint.x-1.0,touchPoint.y))
            self.path.addLineToPoint(CGPointMake(touchPoint.x+1.0,touchPoint.y))
            self.setNeedsDisplay()
            // ADDED
            if (self.delegate != nil) {
                self.delegate?.finishedDrawing!()
            }
        } else {
            self.ctr = 0
            // ADDED
            if (self.delegate != nil) {
                self.delegate?.finishedDrawing!()
            }
        }
    }
    
    // MARK: - Methods for interacting with Signature View
    
    // Clear the Signature View
    public func clearSignature() {
        self.path.removeAllPoints()
        self.setNeedsDisplay()
    }
    
    // Save the Signature as an UIImage
    public func getSignature() -> UIImage? {
        UIGraphicsBeginImageContext(CGSizeMake(self.bounds.size.width, self.bounds.size.height))
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.renderInContext(context)
            let signature = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return signature
        } else {
            return nil
        }
    }
    
    // Save the Signature (cropped of outside white space) as a UIImage
    public func getSignatureCropped() -> UIImage? {
        if let fullRender = getSignature() {
            if let imageRef = CGImageCreateWithImageInRect(fullRender.CGImage, path.bounds) {
                return UIImage(CGImage: imageRef)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

// MARK: - Optional Protocol Methods for YPDrawSignatureViewDelegate
@objc protocol YPDrawSignatureViewDelegate: class {
    optional func startedDrawing()
    optional func finishedDrawing()
}
