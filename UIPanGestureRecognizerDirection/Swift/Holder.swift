import UIKit

extension UIPanGestureRecognizer {
    
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

private var UIPANGESTURERECOGNIZER_FRAMEWORK_HOLDER_ASSOCIATED_OBJECT_KEY: UInt8 = 0

final class Holder {
    
    var direction: UIPanGestureRecognizer.Direction = .all
    var touchesBegan: Bool = false
}
