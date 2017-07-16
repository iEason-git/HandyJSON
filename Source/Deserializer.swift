/*
 * Copyright 1999-2101 Alibaba Group.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//  Created by zhouzhuo on 7/7/16.
//

import Foundation

public extension HandyJSON {

    /// Finds the internal NSDictionary in `dict` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func deserialize(from dict: NSDictionary?, designatedPath: String? = nil) -> Self? {
        return JSONDeserializer<Self>.deserializeFrom(dict: dict, designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func deserialize(from json: String?, designatedPath: String? = nil) -> Self? {
        return JSONDeserializer<Self>.deserializeFrom(json: json, designatedPath: designatedPath)
    }
}

public extension Array where Element: HandyJSON {

    /// if the JSON field finded by `designatedPath` in `json` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method converts it to a Models array
    public static func deserialize(from json: String?, designatedPath: String? = nil) -> [Element?]? {
        return JSONDeserializer<Element>.deserializeModelArrayFrom(json: json, designatedPath: designatedPath)
    }

    /// deserialize model array from NSArray
    public static func deserialize(from array: NSArray?) -> [Element?]? {
        return JSONDeserializer<Element>.deserializeModelArrayFrom(array: array)
    }
}

public class JSONDeserializer<T: HandyJSON> {

    /// Finds the internal NSDictionary in `dict` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func deserializeFrom(dict: NSDictionary?, designatedPath: String? = nil) -> T? {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = extractInnerObject(inside: targetDict, by: path) as? NSDictionary
        }
        if let _dict = targetDict {
            return T._transform(dict: _dict, toType: T.self) as? T
        }
        return nil
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func deserializeFrom(json: String?, designatedPath: String? = nil) -> T? {
        guard let _json = json else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonDict = jsonObject as? NSDictionary {
                return self.deserializeFrom(dict: jsonDict, designatedPath: designatedPath)
            }
        } catch let error {
            InternalLogger.logError(error)
        }
        return nil
    }

    /// if the JSON field found by `designatedPath` in `json` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method converts it to a Models array
    public static func deserializeModelArrayFrom(json: String?, designatedPath: String? = nil) -> [T?]? {
        guard let _json = json else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonArray = extractInnerObject(inside: jsonObject as? NSObject, by: designatedPath) as? NSArray {
                return jsonArray.map({ (item) -> T? in
                    return self.deserializeFrom(dict: item as? NSDictionary)
                })
            }
        } catch let error {
            InternalLogger.logError(error)
        }
        return nil
    }

    /// if the object found by `designatedPath` in `json` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method converts it to a Models array
    public static func deserializeModelArrayFrom(array: NSArray?) -> [T?]? {
        guard let _arr = array else {
            return nil
        }
        return _arr.map({ (item) -> T? in
            return self.deserializeFrom(dict: item as? NSDictionary)
        })
    }
}

fileprivate func extractInnerObject(inside jsonObject: NSObject?, by designatedPath: String?) -> NSObject? {
    var nodeValue: NSObject? = jsonObject
    var abort = false
    if let paths = designatedPath?.components(separatedBy: "."), paths.count > 0 {
        paths.forEach({ (seg) in
            if seg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" || abort {
                return
            }
            if let next = (nodeValue as? NSDictionary)?.object(forKey: seg) as? NSObject {
                nodeValue = next
            } else {
                abort = true
            }
        })
    }
    return abort ? nil : nodeValue
}
