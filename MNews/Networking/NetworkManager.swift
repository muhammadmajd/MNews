
import Foundation

// This struct matches the JSON structure from the API.
//PostAPIModel: A Codable struct to easily decode the JSON response.
struct PostAPIModel: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

//NetworkError: A custom enum for better error handling.

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Error)
}

//NetworkManager: A singleton class to provide a single point of access for network calls.
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

   // private let baseURL = "https://jsonplaceholder.typicode.com"
    private let baseURL = "https://jsonplaceholder.typicode.com/posts"
    //
    
    //fetchPosts: Uses URLSession to fetch data. It takes page and limit for pagination (bonus task!). It uses a Result type in its completion handler, which is a modern Swift pattern for handling success or failure.
    func fetchPosts(page: Int, limit: Int = 20, completion: @escaping (Result<[PostAPIModel], NetworkError>) -> Void) {
        let urlString = "\(baseURL)/posts?_page=\(page)&_limit=\(limit)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.serverError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let posts = try JSONDecoder().decode([PostAPIModel].self, from: data)
                completion(.success(posts))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
}
