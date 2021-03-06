import Foundation
import PromiseKit

enum Network {
    static func dataTask(request: URLRequest) -> Promise<Data> {
        return Promise { fulfill, reject in
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {
                    reject(error!)
                    return
                }

                guard
                    let response = response as? HTTPURLResponse,
                    let data = data
                else {
                    reject(APOError.network)
                    return
                }

                guard response.statusCode / 100 == 2 else {
                    reject(APOError.server(statusCode: response.statusCode))
                    return
                }

                fulfill(data)
            }.resume()
        }
    }

    static func dataTask<T: Decodable>(request: URLRequest) -> Promise<T> {
        return dataTask(request: request).then { data -> Promise<T> in
            do {
                let decoder = JSONDecoder()
                if #available(OSX 10.12, *) {
                    decoder.dateDecodingStrategy = .iso8601
                }
                let decoded = try decoder.decode(T.self, from: data)
                return Promise(value: decoded)
            } catch let error {
                return Promise(error: error)
            }
        }
    }
}
