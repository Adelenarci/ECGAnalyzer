import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()

    private init() {}

    func generateECGComment(from prompt: String, completion: @escaping (String?) -> Void) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
            print("Missing API Key")
            completion(nil)
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful medical assistant."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("OpenAI response parsing failed")
                completion(nil)
                return
            }
            completion(content)
        }.resume()
    }
}