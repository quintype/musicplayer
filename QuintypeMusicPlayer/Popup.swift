//
//  Popup.swift
//  MusicPlayer
//
//  Created by Albin.git on 6/13/17.
//  Copyright © 2017 Albin.git. All rights reserved.
//

import UIKit

class Banner:UIView{
    
    private let containerView : UIView = {
        let view = UIView()
        view.backgroundColor = .white//ThemeService.shared.theme.primaryColor.withAlphaComponent(0.9)
        
        return view
    }()
    
    private let Titlelabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        //        label.font = ThemeService.shared.theme.relatedStoriesSectionTitleFont
        
        return label
    }()
    
    private let SubTitlelabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        //        label.font = ThemeService.shared.theme.playerSeekerLabelFont
        return label
    }()
    
    class func topWindow() -> UIWindow?{
        for window in UIApplication.shared.windows.reversed(){
            if window.windowLevel == UIWindowLevelNormal && window.isKeyWindow && window.frame != CGRect.zero{return window}
        }
        return nil
    }
    
    public required init(title:String?,subtitle:String?){
        super.init(frame:CGRect.zero)
        
        Titlelabel.text = title
        SubTitlelabel.text = subtitle
        
        setUpView()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpView(){
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let screenWidth = UIScreen.main.bounds.width
        
        
        
        self.addSubview(containerView)
        
        containerView.addSubview(Titlelabel)
        containerView.addSubview(SubTitlelabel)
        
        containerView.fillSuperview()
        
        Titlelabel.anchor(containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 5 + statusBarHeight, leftConstant: 15, bottomConstant: 0, rightConstant: 15, widthConstant: 0, heightConstant: 0)
        
        SubTitlelabel.anchor(Titlelabel.bottomAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, topConstant: 5, leftConstant: 15, bottomConstant: 15, rightConstant: 15, widthConstant: 0, heightConstant: 0)
        
        let size = caculateSize(MAXWidth: screenWidth)
        
        self.frame = CGRect(x: 0, y: -size.height, width: size.width, height: size.height)
        
    }
    
    public func show(view:UIView? = Banner.topWindow(),durationInSeconds:Int? = 2){
        guard let unwrappedView = view else{
            print("Could not find a view.Aborting")
            return
        }
        
        unwrappedView.addSubview(self)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.frame.origin.y = 0
        }) { (_) in
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(durationInSeconds!), execute: {
                self.dismiss()
            })
        }
        
    }
    
    public func dismiss(){
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
            self.frame.origin.y = -self.frame.size.height
        }) { (_) in
            DispatchQueue.main.async {
                self.removeFromSuperview()
            }
        }
        
    }
    
    func caculateSize(MAXWidth : CGFloat) -> CGSize{
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = NSLayoutConstraint(item: self,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1,
                                                 constant:MAXWidth)
        
        self.addConstraint(widthConstraint)
        
        var size = UILayoutFittingCompressedSize
        size.width = MAXWidth
        
        let Size = self.systemLayoutSizeFitting(size, withHorizontalFittingPriority: UILayoutPriority(rawValue: 1000), verticalFittingPriority:UILayoutPriority(rawValue: 1))
        self.removeConstraint(widthConstraint)
        
        self.translatesAutoresizingMaskIntoConstraints = true
        
        return Size
        
    }
    
}

