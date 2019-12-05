import UIKit
import SWXMLHash
import PlaygroundSupport

extension SignedNumeric {

    var string: String {
        return String(describing: self)
    }
}

extension String {
    
    var cgFloat: CGFloat {
        CGFloat(NSString(string: self).floatValue)
    }
}

enum GNSColor: String, CaseIterable, Hashable {
    case ash
    case black
    case charcoal
    case confidentOrange
    case gray
    case latte
    case lemonade
    case lightgray
    case poppyRed
    case warmYellow
    case white
    
    var isAchromatic: Bool {
        switch self {
        case .ash, .charcoal, .gray, .lightgray, .black, .white:
            return true
        default:
            return false
        }
    }
    
    var isGray: Bool {
        switch self {
        case .ash, .charcoal, .gray, .lightgray:
            return true
        default:
            return false
        }
    }
    
    var replaceColors: [(red: CGFloat, green: CGFloat, blue: CGFloat)] {
        switch self {
        case .ash:
            return [(red: 153 / 255, green: 153 / 255, blue: 153 / 255)]
        case .black:
            return [(red: 0 / 255, green: 0 / 255, blue: 0 / 255)]
        case .charcoal:
            return [(red: 102 / 255, green: 102 / 255, blue: 102 / 255)]
        case .confidentOrange:
            return [(red: 255 / 255, green: 84 / 255, blue: 15 / 255), (red: 69 / 255, green: 106 / 255, blue: 168 / 255), (red: 255 / 255, green: 115 / 255, blue: 115 / 255), (red: 255 / 255, green: 106 / 255, blue: 106 / 255)]
        case .gray:
            return [(red: 214 / 255, green: 214 / 255, blue: 214 / 255)]
        case .latte:
            return [(red: 191 / 255, green: 134 / 255, blue: 80 / 255)]
        case .lemonade:
            return [(red: 244 / 255, green: 248 / 255, blue: 266 / 255), (red: 255 / 255, green: 240 / 255, blue: 240 / 255), (red: 255 / 255, green: 247 / 255, blue: 224 / 255)]
        case .lightgray:
            return [(red: 245 / 255, green: 245 / 255, blue: 245 / 255)]
        case .poppyRed:
            return [(red: 224 / 255, green: 49 / 255, blue: 49 / 255)]
        case .warmYellow:
            return [(red: 255 / 255, green: 210 / 255, blue: 103 / 255)]
        case .white:
            return [(red: 255 / 255, green: 255 / 255, blue: 255 / 255)]
        }
    }
}

var colors = GNSColor.allCases

extension CGFloat {
    func addRadixPoint() -> String {
         String(format: "%.3f", self)
    }
    
    var int: Int {
        return Int(self)
    }
    
    var toRGB: CGFloat {
        self * 255
    }
    
    func similarInGrayColors() -> GNSColor {
        if self == 0 {
            return .black
        } else if self == 1 {
            return .white
        }
        let grayColors = colors.filter { $0.isGray }
        let grayColorValues = grayColors.compactMap { $0.replaceColors.first?.red }.map { CGFloat(abs(self - $0)) }
        return grayColors[grayColorValues.firstIndex(of: grayColorValues.min()!)!]
    }
}

extension XMLElement: Equatable {
    public static func == (lhs: XMLElement, rhs: XMLElement) -> Bool {
        return lhs.red?.cgFloat.toRGB.int == rhs.red?.cgFloat.toRGB.int && lhs.blue?.cgFloat.toRGB.int == rhs.blue?.cgFloat.toRGB.int && lhs.green?.cgFloat.toRGB.int == rhs.green?.cgFloat.toRGB.int
    }
}

extension XMLElement {
    
    @discardableResult func modifyElementIfNeeded() -> Set<GNSColor> {
        var usedColors = Set<GNSColor>()
        
        colors.forEach { color in
            color.replaceColors.forEach {
                if color.isAchromatic,
                    $0.red.addRadixPoint() == white?.cgFloat.addRadixPoint() {
                    // 무채색이면서 white가 있고 같을경우
                    modifyElement(with: color)
                    usedColors.insert(color)
                } else if color.isAchromatic,
                    $0.red.addRadixPoint() == red?.cgFloat.addRadixPoint() {
                    // 무채색이면서 white가 없고 서로 같을경우
                    modifyElement(with: color)
                    usedColors.insert(color)
                } else if $0.red.addRadixPoint() == red?.cgFloat.addRadixPoint() && $0.green.addRadixPoint() == green?.cgFloat.addRadixPoint() && $0.blue.addRadixPoint() == blue?.cgFloat.addRadixPoint() {
                    // 유채색이면서 같을경우
                    modifyElement(with: color)
                    usedColors.insert(color)
                }
            }
        }
        
        return usedColors
    }
    
    @discardableResult func modifyGrayElementIfNeeded() -> Set<GNSColor> {
        var usedColors = Set<GNSColor>()
        
        if let white = white {
            let color = white.cgFloat.similarInGrayColors()
            modifyElement(with: color)
            usedColors.insert(color)
        } else if let white = red {
            let color = white.cgFloat.similarInGrayColors()
            modifyElement(with: color)
            usedColors.insert(color)
        }
        
        return usedColors
    }
    
    func modifyElement(with color: GNSColor) {
        if let keyAttribute = attribute(by: "key") {
            allAttributes = ["key": keyAttribute, "name": XMLAttribute(name: "name", text: color.rawValue)]
        }
    }
    
    var red: String? {
        attribute(by: "red")?.text
    }
    var green: String? {
        attribute(by: "green")?.text
    }
    var blue: String? {
        attribute(by: "blue")?.text
    }
    var white: String? {
        attribute(by: "white")?.text
    }
}

func storyboardXML() -> [(url: URL, xml: XMLIndexer)]? {
    
    guard let storyboardURLs = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "storyboard") else {
        print("path not found")
        return nil
    }
    guard let xibURLs = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "xib") else {
        print("path not found")
        return nil
    }

    let urls = storyboardURLs + xibURLs
    
    return urls.compactMap {
        try? String(contentsOf: $0, encoding: .utf8)
    }.enumerated().map {
        (path: urls[$0.offset], xml:SWXMLHash.parse($0.element))
    }
}

var xmls = storyboardXML()
var unknownColors = [XMLElement]()

var setColors = Set<GNSColor>()

func toHexString(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
    let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
    
    return NSString(format:"#%06x", rgb) as String
}

func enumerate(_ indexer: XMLIndexer?) {
    guard let indexer = indexer else { return }
    for child in indexer.children {
        if child.element?.name.contains("color") ?? false {
            let red = child.element?.red?.cgFloat.addRadixPoint()
            let green = child.element?.green?.cgFloat.addRadixPoint()
            let blue = child.element?.blue?.cgFloat.addRadixPoint()
            
            let white = child.element?.attribute(by: "white")
            
            if child.element?.attribute(by: "alpha")?.text.cgFloat == 1 {
                if let replacedColors = child.element?.modifyElementIfNeeded(),
                    !replacedColors.isEmpty {
                    // 대치 가능 한 색 확인 후 대치
                    replacedColors.forEach {
                        setColors.insert($0)
                    }
                } else {
                    if (red == green && blue == green) || white != nil,
                        let replacedColors = child.element?.modifyGrayElementIfNeeded(),
                        !replacedColors.isEmpty {
                        // 가장 비슷한 Gray값 확인 후 대치
                        replacedColors.forEach {
                            setColors.insert($0)
                        }
                    } else {
                        //print(child.element)
                    }
                }
            }
        } else if child.element?.name.contains("tableViewCellContentView") ?? false { // TableView ContentView 색 변경
            var isContainsBackgroundColor = false
            for lowChild in child.children {
                if lowChild.element?.name.contains("color") ?? false,
                    lowChild.element?.attribute(by: "key")?.name == "backgroundColor" {
                    isContainsBackgroundColor = true
                }
            }
            
            if !isContainsBackgroundColor {
                child.element?.addElement("color", withAttributes: ["key": "backgroundColor", "name": GNSColor.white.rawValue], caseInsensitive: false)
            }
        }
        
        enumerate(child)
    }
}

func processXML() {
    xmls?.forEach { url, xml in
        enumerate(xml)
        setColors.forEach {
            xml["document"]["resources"].element?.addElement("namedColor", withAttributes: ["name": $0.rawValue], caseInsensitive: false)
        }
        setColors = []
        print("-----------------\(url.lastPathComponent)-----------------\n" + xml.description)
    }
}

processXML()
//xmls?.forEach {
//    enumerate($0)
//}

//unknownColors.forEach {
//    print(
//    """
//        key = \($0.attribute(by: "key")?.text ?? "")
//        red = \($0.red?.cgFloat.toRGB.int ?? 0)
//        green = \($0.green?.cgFloat.toRGB.int ?? 0)
//        blue = \($0.blue?.cgFloat.toRGB.int ?? 0)
//        \(toHexString(r: $0.red?.cgFloat ?? 0, g: $0.green?.cgFloat ?? 0, b: $0.blue?.cgFloat ?? 0))
//
//    """)
//}

