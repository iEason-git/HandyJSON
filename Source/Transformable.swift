//
//  Transformable.swift
//  HandyJSON
//
//  Created by zhouzhuo on 15/07/2017.
//  Copyright © 2017 aliyun. All rights reserved.
//

import Foundation

public protocol _Transformable: _Measurable {}

extension _Transformable {

    public static func transform(from object: NSObject) -> Self? {
        switch self {
        case let type as _BuiltInBridgeType.Type:
            return type._transform(from: object) as? Self
        case let type as _BuiltInBasicType.Type:
            return type._transform(from: object) as? Self
        case let type as _RawEnumProtocol.Type:
            return type._transform(from: object) as? Self
        case let type as _ExtendCustomType.Type:
            return type._transform(from: object) as? Self
        default:
            return nil
        }
    }

    public func plainValue() -> Any? {
        switch self {
        case let rawValue as _BuiltInBridgeType:
            return rawValue._plainValue()
        case let rawValue as _BuiltInBasicType:
            return rawValue._plainValue()
        case let rawValue as _RawEnumProtocol:
            return rawValue._plainValue()
        case let rawValue as _ExtendCustomType:
            return rawValue._plainValue()
        default:
            return nil
        }
    }
}

