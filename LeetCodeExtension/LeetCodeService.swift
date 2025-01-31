import Foundation

class LeetCodeService {
    private let session = URLSession.shared
    private var csrfToken: String?
    
    func login(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://leetcode.com/accounts/login/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { [weak self] _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               let fields = httpResponse.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                self?.csrfToken = cookies.first(where: { $0.name == "csrftoken" })?.value
            }
            
            self?.performLogin(username: username, password: password, completion: completion)
        }.resume()
    }
    
    private func performLogin(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://leetcode.com/accounts/login/"),
              let csrfToken = csrfToken else {
            completion(.failure(NSError(domain: "Invalid URL or CSRF token", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        request.setValue("https://leetcode.com/accounts/login/", forHTTPHeaderField: "Referer")
        
        let body = "login=\(username)&password=\(password)&csrfmiddlewaretoken=\(csrfToken)"
        request.httpBody = body.data(using: .utf8)
        
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "Login failed", code: 0, userInfo: nil)))
            }
        }.resume()
    }
    
    func fetchProblem(titleSlug: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "https://leetcode.com/graphql") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let query = """
        query getQuestionDetail($titleSlug: String!) {
          question(titleSlug: $titleSlug) {
            questionId
            title
            content
            difficulty
          }
        }
        """
        
        let variables = ["titleSlug": titleSlug]
        let body = ["query": query, "variables": variables] as [String : Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let question = data["question"] as? [String: Any] {
                    completion(.success(question))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchRandomProblem(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "https://leetcode.com/api/problems/all/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let statStatusPairs = json["stat_status_pairs"] as? [[String: Any]] {
                    let randomProblem = statStatusPairs.randomElement()
                    if let stat = randomProblem?["stat"] as? [String: Any],
                       let titleSlug = stat["question__title_slug"] as? String {
                        self.fetchProblem(titleSlug: titleSlug, completion: completion)
                    } else {
                        completion(.failure(NSError(domain: "Invalid problem data", code: 0, userInfo: nil)))
                    }
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
