//
//  Base.swift
//  FaceFoto
//
//  Created by 黄维平 on 2018/4/17.
//  Copyright © 2018年 ufoto. All rights reserved.
//

import UIKit
import Photos

// swiftlint:disable type_name
// swiftlint:disable line_length
// swiftlint:disable identifier_name

let appName = L("SweetSelfie")

// MARK: - 全局常量
// MARK: UI
public let STATUSBAR_HEIGHT: CGFloat = 20
class UI: NSObject {
    static let ScreenWidth  =  UIScreen.main.bounds.size.width
    static let ScreenHeight =  UIScreen.main.bounds.size.height
    static let ScreenScale = {return UIScreen.main.bounds.size.width / 375}()
    static let ScreenPixelScale = {return UIScreen.main.scale}()
    static let ScreenHeightScale = {return UIScreen.main.bounds.size.height / 667}()
    static let SafeAreaInsets: UIEdgeInsets = {return ( Dev.IsIPhoneX ? UIEdgeInsets.init(top: 24, left: 0, bottom: 17, right: 0) : UIEdgeInsets.zero)}()
    static let SafeTopHeight: CGFloat = {return UI.SafeAreaInsets.top}()
    static let SafeBottomHeight: CGFloat = {return UI.SafeAreaInsets.bottom}()
}

// MARK: 设备
class Dev: NSObject {
    static let IsIPhoneX  = {
        return UI.ScreenWidth < 376.0 &&  UI.ScreenHeight > 811.0
    }()

    static let IsIPhone4  = {
        return UI.ScreenHeight < 481
    }()

    static let IsIPhone5  = {
        return UI.ScreenHeight < 600 && UI.ScreenHeight > 500
    }()

    static let IsIPhonePlus  = {
        return UI.ScreenWidth > 375 && UI.ScreenHeight > 667
    }()
}

// MARK: 颜色
class Clr: NSObject {
    static let MainColor = {return UIColor.init(hexColor: "FF3A6F")}()
    static let MainAdditionColor = {return UIColor.init(hexColor: "FF0073")}()
    static let MainBackgroundColor = {return UIColor.init(r: 240, g: 240, b: 240)}()
}

// MARK: 其他
let ShareControllerActionNoti: String = "ShareControllerActionNoti"

public func L(_ string: String) -> String {
    return NSLocalizedString(string, tableName: nil, comment: string)
}

// MARK: - 类扩展
extension UIColor {
    /// 将十六进制颜色转换为UIColor
    convenience init(hexColor: String) {
        var pureHexString = hexColor
        if hexColor.hasPrefix("#") {
            pureHexString.remove(at: pureHexString.firstIndex(of: "#")!)
        }

        // 存储转换后的数值
        var red: UInt32 = 0, green: UInt32 = 0, blue: UInt32 = 0

        // 分别转换进行转换
        Scanner(string: pureHexString[0..<2]).scanHexInt32(&red)

        Scanner(string: pureHexString[2..<4]).scanHexInt32(&green)

        Scanner(string: pureHexString[4..<6]).scanHexInt32(&blue)

        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
    }

    convenience init(r: Int, g: Int, b: Int, a: Int = 255) {
        // 存储转换后的数值
        self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
    }
}

extension String {
    /// String使用下标截取字符串
    /// 例: "示例字符串"[0..<2] 结果是 "示例"
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            return String(self[startIndex..<endIndex])
        }
    }

    ///定位子字符串(NSRange)
    func nsRange(of string:String) -> NSRange {
        guard let range = self.range(of: string) else {return NSRange(location: 0, length: 0)}
        return NSRange(range, in: self)
    }

    func positionOf(sub:String, backwards:Bool = false)->Int {
        // 如果没有找到就返回-1
        var pos = -1
        if let range = range(of:sub, options: backwards ? .backwards : .literal ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }

    func appendingPath(path: String) -> String {
        if let lastChar =  self.last {
            let pathFirstChar = path.first
            return (lastChar == "/" || pathFirstChar == "/") ? self.appending(path):self.appending("/\(path)")
        }
        return path
    }

    func estimatedSize(withFont font:UIFont, maxWidth: CGFloat ) -> CGSize {
        let string = self as NSString
        return string.boundingRect(with: CGSize(width: maxWidth, height: CGFloat(MAXFLOAT)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
    }
}

extension NSAttributedString {
    func estimatedSize(maxWidth: CGFloat ,attributes: [NSAttributedString.Key : Any] =  [:] ) -> CGSize {
        return string.boundingRect(with: CGSize(width: maxWidth, height: CGFloat(MAXFLOAT)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil).size
    }
}

extension UILabel {
    open func set(text: String, textColor: UIColor = .white, textFont: UIFont = UIFont.systemFont(ofSize: 12), textAlignment: NSTextAlignment = .center) {
        self.text = text
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.font = textFont
    }

    open func estimatedHeight(withMaxWidth maxWidth: CGFloat ) -> CGFloat {
        guard let text = self.text else { return 0 }
        return text.estimatedSize(withFont: self.font, maxWidth: maxWidth).height
    }
}

extension UIImageView {
    open func getImageRect() -> CGRect {
        if self.contentMode == .scaleToFill || self.contentMode == .scaleAspectFill {
            return self.bounds
        }

        guard image != nil else {return CGRect.zero}
        var imageSize = image!.size
        let wScale = self.bounds.width / imageSize.width
        let hScale = self.bounds.height / imageSize.height
        let scale = min(wScale, hScale)

        imageSize.width *=  scale
        imageSize.height *= scale

        return CGRect(x: 0.5*(self.bounds.size.width - imageSize.width), y: 0.5*(self.bounds.size.height - imageSize.height), width: imageSize.width, height: imageSize.height)
    }
}

extension UIButton {
    open func setImageName(_ imageName: String?, hightLightImageName hImageName: String?, selectedImageName sImageName: String?) {
        if let imageName = imageName {
            setImage(UIImage(named: imageName), for: .normal)
        }

        if let hImageName = hImageName {
            setImage(UIImage(named: hImageName), for: .highlighted)
        }

        if let sImageName = sImageName {
            setImage(UIImage(named: sImageName), for: .selected)
        }
    }

    open func setAsTABStyle(titleImageSpace: CGFloat) {
        self.imageView?.contentMode = .scaleAspectFit
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -self.imageView!.frame.size.width, bottom:  -(self.imageView?.frame.size.height ?? 0 + (titleImageSpace * 0.5)), right: 0)
        self.imageEdgeInsets = UIEdgeInsets(top: -(self.titleLabel?.intrinsicContentSize.height ?? 0) - titleImageSpace * 0.5, left: 0.0, bottom:  0.0, right:-(self.titleLabel?.intrinsicContentSize.width ?? 0))
    }
}

// swiftlint:enable type_name
// swiftlint:enable line_length
// swiftlint:enable identifier_name

