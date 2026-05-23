//
//  TargetType.swift
//  
//
//  Created by Zaghloul on 10/04/2025.
//

import Foundation
import Alamofire

public enum NetworkTask {

    /// A request with no additional data.
    case requestPlain
    
    /// A requests body set with encoded parameters.
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
}

protocol TargetType {
    
    /// The target's base `URL`.
    var baseURL: String { get }
    
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }
    
    /// The HTTP method used in the request.
    var method: HTTPMethod { get }
    
    /// The type of HTTP task to be performed.
    var task: NetworkTask { get }
    
    /// The headers to be used in the request.
    var headers: [String: String]? { get }
}

