import UIKit.UIGestureRecognizerSubclass

extension UIApplication {
    
    override open var next: UIResponder? {
        guard let mutex = Once.mutex else {
            return super.next
        }
        mutex.sync {
            Once.mutex = nil
            let selector1 = #selector(UIPanGestureRecognizer.touchesBegan(_:with:))
            let selector2 = #selector(UIPanGestureRecognizer.swizzling_touchesBegan(_:with:))
            replace(UIPanGestureRecognizer.self, selectorOriginal: selector1, selectorSwizzled: selector2)
            let selector3 = #selector(UIPanGestureRecognizer.touchesMoved(_:with:))
            let selector4 = #selector(UIPanGestureRecognizer.swizzling_touchesMoved(_:with:))
            replace(UIPanGestureRecognizer.self, selectorOriginal: selector3, selectorSwizzled: selector4)
        }
        return super.next
    }
}

extension UIPanGestureRecognizer {
    
    @objc func swizzling_touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        self.swizzling_touchesBegan(touches, with: event)
        guard self.direction != .all else {
            return
        }
        self.touchesBegan = true
    }
    
    @objc func swizzling_touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.swizzling_touchesMoved(touches, with: event)
        guard self.touchesBegan == true else {
            return
        }
        let directions = touches
            .map({ (touch: UITouch) -> UIPanGestureRecognizer.Direction in
                let locationCurrent = touch.location(in: touch.view)
                let locationPrevious = touch.previousLocation(in: touch.view)
                return UIPanGestureRecognizer.Direction(locationCurrent: locationCurrent, locationPrevious: locationPrevious)
            })
        guard directions.filter({ $0 != .none }).count > 0 else {
            return
        }
        defer {
            touchesBegan = false
        }
        guard directions.filter({ self.direction.contains($0) == false }).count > 0 else {
            return
        }
        state = .failed
    }
}

public extension UIPanGestureRecognizer {
    
    struct Direction: OptionSet {
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let all: Direction = [.up, .down, .left, .right]
        public static let down = Direction(rawValue: 1 << 2)
        public static let horizontal: Direction = [.left, .right]
        public static let left = Direction(rawValue: 1 << 3)
        public static let none = Direction(rawValue: 1 << 0)
        public static let right = Direction(rawValue: 1 << 4)
        public static let up = Direction(rawValue: 1 << 1)
        public static let vertical: Direction = [.up, .down]

        public init(locationCurrent: CGPoint, locationPrevious: CGPoint) {
            let vector = CGPoint(
                x: locationCurrent.x - locationPrevious.x,
                y: locationCurrent.y - locationPrevious.x
            )
            self.init(vector: vector)
        }

        public init(vector: CGPoint) {
            switch vector {
            case .zero:
                self = UIPanGestureRecognizer.Direction.none
            default:
                switch abs(vector.x) > abs(vector.y) {
                case true:
                    switch vector.x > 0 {
                    case true:
                        self = UIPanGestureRecognizer.Direction.right
                    case false:
                        self = UIPanGestureRecognizer.Direction.left
                    }
                case false:
                    switch vector.y > 0 {
                    case true:
                        self = UIPanGestureRecognizer.Direction.down
                    case false:
                        self = UIPanGestureRecognizer.Direction.up
                    }
                }
            }
        }
    }

    var directionCurrent: UIPanGestureRecognizer.Direction {
        get {
            let vector = self.velocity(in: self.view)
            return UIPanGestureRecognizer.Direction(vector: vector)
        }
    }
    
    var direction: UIPanGestureRecognizer.Direction {
        get {
            return self.holder.direction
        }
        set {
            self.holder.direction = newValue
        }
    }
    
    private var touchesBegan: Bool {
        get {
            return self.holder.touchesBegan
        }
        set {
            self.holder.touchesBegan = newValue
        }
    }
}

// MARK: - Holder

fileprivate extension UIPanGestureRecognizer {

    var holder: Holder {
        if let holder = objc_getAssociatedObject(self, &UIPANGESTURERECOGNIZER_FRAMEWORK_HOLDER_ASSOCIATED_OBJECT_KEY) as? Holder {
            return holder
        } else {
            let holder = Holder()
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, &UIPANGESTURERECOGNIZER_FRAMEWORK_HOLDER_ASSOCIATED_OBJECT_KEY, holder, policy)
            return holder
        }
    }
}

fileprivate var UIPANGESTURERECOGNIZER_FRAMEWORK_HOLDER_ASSOCIATED_OBJECT_KEY: UInt8 = 0

fileprivate final class Holder {

    var direction: UIPanGestureRecognizer.Direction = .all
    var touchesBegan: Bool = false
}

// MARK: - Mutex

fileprivate final class Mutex {

    private var mutex = pthread_mutex_t()

    init?(recursive: Bool = false) {
        var attributes = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attributes) == 0 else {
            return nil
        }
        pthread_mutexattr_settype(&attributes, recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL)
        guard pthread_mutex_init(&mutex, &attributes) == 0 else {
            return nil
        }
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    private func lock() {
        pthread_mutex_lock(&mutex)
    }

    private func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    func sync<R>(block: () throws -> R) rethrows -> R {
        lock()
        defer {
            unlock()
        }
        return try block()
    }
}

// MARK: - Once

fileprivate final class Once {

    static var mutex: Mutex? = Mutex()
}

// MARK: - Replace

fileprivate func replace(_ anyClass: AnyClass, selectorOriginal: Selector, selectorSwizzled: Selector) {
    guard let original = class_getInstanceMethod(anyClass, selectorOriginal) else {
        return
    }
    guard let swizzled = class_getInstanceMethod(anyClass, selectorSwizzled) else {
        return
    }
    switch class_addMethod(anyClass, selectorOriginal, method_getImplementation(swizzled), method_getTypeEncoding(swizzled)) {
    case true:
        class_replaceMethod(anyClass, selectorSwizzled, method_getImplementation(original), method_getTypeEncoding(original))
    case false:
        method_exchangeImplementations(original, swizzled)
    }
}
