//
//  BaseAPI 2.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 24/04/2025.
//

import Alamofire
import Combine
import Foundation

// MARK: - Base API

class BaseAPI<T: TargetType> {
    public init() {}
}

// MARK: - Build Params

extension BaseAPI {
    private func buildParams(task: NetworkTask) -> ([String: Any], ParameterEncoding) {
        switch task {
        case .requestPlain:
            return ([:], URLEncoding.default)
        case .requestParameters(let parameters, let encoding):
            return (parameters, encoding)
        }
    }
}

// MARK: - Base API Service with Combine

extension BaseAPI {
    
    func connectWithServerPublisher<M: Decodable>(target: T) -> AnyPublisher<DomainWrapper<M>, Never> {
        let url = target.baseURL + target.path
        let method = HTTPMethod(rawValue: target.method.rawValue)
        let headers = Header.shared.createHeader()
        let params = buildParams(task: target.task)

        return AF.request(url, method: method, parameters: params.0, encoding: params.1, headers: headers)
            .validate()
            .publishData()
            .tryMap { response -> Data in
                if let url = response.request?.url {
                    print("🌐 URL: \(url.absoluteString)")
                }

                if let statusCode = response.response?.statusCode {
                    print("📟 Status Code: \(statusCode)")
                }

                if let headers = response.request?.headers {
                    print("📬 Headers: \(headers)")
                }

                if let data = response.data {
                    let body = String(data: data, encoding: .utf8) ?? "Unreadable body"
                    print("📦 Response Body: \(body)")
                }

                if let error = response.error {
                    print("🚫 Alamofire Validation Error: \(error)")
                    throw error
                }

                guard let data = response.data else {
                    throw URLError(.badServerResponse)
                }

                return data
            }
            .decode(type: APIResponse<M>.self, decoder: JSONDecoder())
            .map { apiResponse -> DomainWrapper<M> in
                if apiResponse.success {
                    return DomainWrapper.success(
                        data: apiResponse.data,
                        message: apiResponse.message,
                        statusDescription: apiResponse.statusDescription
                    )
                } else {
                    let statusCode = apiResponse.status ?? 500
                    let message = apiResponse.message
                    let statusDescription = apiResponse.statusDescription
                    
                    let hasCustomBackendMessage = !message.isEmpty
                    if hasCustomBackendMessage {
                        return DomainWrapper.failure(
                            statusCode: statusCode,
                            statusDescription: statusDescription,
                            message: message
                        )
                    } else {
                        let errorMessage: String
                        switch statusCode {
                        case 401:
                            errorMessage = "Session expired. Please login again."
                        case 403:
                            errorMessage = "You are not authorized to perform this action."
                        case 400, 422:
                            errorMessage = "Validation error occurred."
                        case 404:
                            errorMessage = "Requested resource was not found."
                        case 503:
                            errorMessage = "Service is temporarily unavailable. Please try later."
                        default:
                            errorMessage = "An unknown server error occurred."
                        }

                        return DomainWrapper.failure(
                            statusCode: statusCode,
                            statusDescription: statusDescription,
                            message: errorMessage
                        )
                    }
                }
            }
            .catch { error -> Just<DomainWrapper<M>> in
                return Just(
                    DomainWrapper.failure(
                        statusCode: 500,
                        statusDescription: "Internal Server Error",
                        message: error.localizedDescription
                    )
                )
            }
            .eraseToAnyPublisher()
    }
    
    func uploadImagePublisher<M: Decodable>(target: T, image: Data?) -> AnyPublisher<DomainWrapper<M>, Never> {
        let url = target.baseURL + target.path
        let method = HTTPMethod(rawValue: target.method.rawValue)
        let headers = Header.shared.createHeader()
        let params = buildParams(task: target.task).0
        
        return Future<DomainWrapper<M>, Never> { promise in
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(image ?? Data(), withName: "image", fileName: "image.jpeg", mimeType: "image/jpeg")
                for (key, value) in params {
                    multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
                }
            }, to: url, method: method, headers: headers)
            .validate()
            .responseDecodable(of: APIResponse<M>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    if apiResponse.success {
                        promise(.success(DomainWrapper.success(
                            data: apiResponse.data,
                            message: apiResponse.message,
                            statusDescription: apiResponse.statusDescription
                        )))
                    } else {
                        promise(.success(DomainWrapper.failure(
                            statusCode: apiResponse.status ?? 500,
                            statusDescription: apiResponse.statusDescription,
                            message: apiResponse.message
                        )))
                    }
                case .failure(let error):
                    promise(.success(DomainWrapper.failure(
                        statusCode: 500,
                        statusDescription: "Network Error",
                        message: error.localizedDescription
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func uploadImagesPublisher<M: Decodable>(target: T, images: [ImageRequest]) -> AnyPublisher<DomainWrapper<M>, Never> {
        let url = target.baseURL + target.path
        let method = HTTPMethod(rawValue: target.method.rawValue)
        let headers = Header.shared.createHeader()
        let params = buildParams(task: target.task).0
        
        return Future<DomainWrapper<M>, Never> { promise in
            AF.upload(multipartFormData: { multipartFormData in
                for image in images {
                    multipartFormData.append(image.imageData ?? Data(), withName: image.imageName, fileName: "\(image.imageName).jpeg", mimeType: "image/jpeg")
                }
                for (key, value) in params {
                    multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
                }
            }, to: url, method: method, headers: headers)
            .validate()
            .responseDecodable(of: APIResponse<M>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    if apiResponse.success {
                        promise(.success(DomainWrapper.success(
                            data: apiResponse.data,
                            message: apiResponse.message,
                            statusDescription: apiResponse.statusDescription
                        )))
                    } else {
                        promise(.success(DomainWrapper.failure(
                            statusCode: apiResponse.status ?? 500,
                            statusDescription: apiResponse.statusDescription,
                            message: apiResponse.message
                        )))
                    }
                case .failure(let error):
                    promise(.success(DomainWrapper.failure(
                        statusCode: 500,
                        statusDescription: "Network Error",
                        message: error.localizedDescription
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Legacy Callback-based API Methods (Keep for backward compatibility)

extension BaseAPI {
    func connectWithServer<M: Decodable>(target: T, completion: @escaping (Result<M?, Error>) -> Void) {
        let url = target.baseURL + target.path
        let method = Alamofire.HTTPMethod(rawValue: target.method.rawValue)
        let headers = Header.shared.createHeader()
        let params = buildParams(task: target.task)
        
        AF.request(url, method: method, parameters: params.0, encoding: params.1, headers: headers).validate().response { (response) in
            switch response.result {
            case .failure(let error):
                completion(.failure(error))
            case .success(_):
                guard let data = response.data else { return }
                do {
                    let json = try JSONDecoder().decode(M.self, from: data)
                    print(json)
                    completion(.success(json))
                } catch let error {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func uploadImages<M: Decodable>(target: T, images: [ImageRequest], completion: @escaping (Result<M?, Error>) -> Void) {
        let url = target.baseURL + target.path
        let method = Alamofire.HTTPMethod(rawValue: target.method.rawValue)
        let params = buildParams(task: target.task).0
        let headers = Header.shared.createHeader()
        
        AF.upload(multipartFormData: { (multipartFormData) in
            for image in images {
                multipartFormData.append(image.imageData ?? Data(), withName: "\(image.imageName)", fileName: "\(image.imageName).jpeg", mimeType: "\(image.imageName)/jpeg")
            }
            
            for (key, value) in params {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
            }
        }, to: url, method: method, headers: headers)
        .responseDecodable(of: M.self) { response in
            debugPrint(response)
            guard let data = response.data else { return }
            do {
                let json = try JSONDecoder().decode(M.self, from: data)
                completion(.success(json))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
