import UIKit.UIGestureRecognizerSubclass

extension UIApplication {
    
    override open var next: UIResponder? {
        DispatchQueue.once {
            func replace(_ method: Selector, with anotherMethod: Selector, for clаss: AnyClass) {
                let original = class_getInstanceMethod(clаss, method)
                let swizzled = class_getInstanceMethod(clаss, anotherMethod)
                switch class_addMethod(clаss, method, method_getImplementation(swizzled!), method_getTypeEncoding(swizzled!)) {
                case true:
                    class_replaceMethod(clаss, anotherMethod, method_getImplementation(original!), method_getTypeEncoding(original!))
                case false:
                    method_exchangeImplementations(original!, swizzled!)
                }
            }
            let selector1 = #selector(UIPanGestureRecognizer.touchesBegan(_:with:))
            let selector2 = #selector(UIPanGestureRecognizer.swizzling_touchesBegan(_:with:))
            replace(selector1, with: selector2, for: UIPanGestureRecognizer.self)
            let selector3 = #selector(UIPanGestureRecognizer.touchesMoved(_:with:))
            let selector4 = #selector(UIPanGestureRecognizer.swizzling_touchesMoved(_:with:))
            replace(selector3, with: selector4, for: UIPanGestureRecognizer.self)
        }
        return super.next
    }
}

extension UIPanGestureRecognizer {
    
    @objc func swizzling_touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        self.swizzling_touchesBegan(touches, with: event)
        guard direction != .all else { return }
        touchesBegan = true
    }
    
    @objc func swizzling_touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.swizzling_touchesMoved(touches, with: event)
        guard touchesBegan == true else { return }
        let directions = touches
            .map({ $0.location(in: $0.view) - $0.previousLocation(in: $0.view) })
            .map({ $0.direction })
        guard directions.filter({ $0 != .none }).count > 0 else { return }
        defer {
            touchesBegan = false
        }
        guard directions.filter({ direction.contains($0) == false }).count > 0 else { return }
        state = .failed
    }
}

public extension UIPanGestureRecognizer {
    
    public struct Direction: OptionSet {
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let none  = Direction(rawValue: 1 << 0)
        public static let up    = Direction(rawValue: 1 << 1)
        public static let down  = Direction(rawValue: 1 << 2)
        public static let left  = Direction(rawValue: 1 << 3)
        public static let right = Direction(rawValue: 1 << 4)
        
        public static let all: Direction = [.up, .down, .left, .right]
        public static let horizontal: Direction = [.left, .right]
        public static let vertical: Direction = [.up, .down]
    }

    public var currentDirection: UIPanGestureRecognizer.Direction {
        get {
            return velocity(in: view).direction
        }
    }
    
    public var direction: UIPanGestureRecognizer.Direction {
        get {
            return holder.direction
        }
        set {
            holder.direction = newValue
        }
    }
    
    var touchesBegan: Bool {
        get {
            return holder.touchesBegan
        }
        set {
            holder.touchesBegan = newValue
        }
    }
}

extension CGPoint {
    
    var direction: UIPanGestureRecognizer.Direction {
        if self == .zero {
            return UIPanGestureRecognizer.Direction.none
        }
        switch fabs(x) > fabs(y) {
        case true:
            switch x > 0 {
            case true:
                return UIPanGestureRecognizer.Direction.right
            case false:
                return UIPanGestureRecognizer.Direction.left
            }
        case false:
            switch y > 0 {
            case true:
                return UIPanGestureRecognizer.Direction.down
            case false:
                return UIPanGestureRecognizer.Direction.up
            }
        }
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
