//
//  OpenAIManager.swift
//  ECGAnalyzer
//
//  Created by Ali Kaan Karagözgil on 13.05.2025.
//


import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()

    private init() {}

    func generateECGComment(ecgCSV: String, height: Double?, weight: Double?, sex: String?, completion: @escaping (String?) -> Void) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String else {
            print("Missing API Key")
            completion(nil)
            return
        }

        let userInfo = """
        Sex: \(sex ?? "Unknown")
        Height: \(String(format: "%.2f", height ?? 0)) meters
        Weight: \(String(format: "%.1f", weight ?? 0)) kilograms
        """

        let prompt = """
        You are a medical assistant with expertise in interpreting ECG signals. Based on the following ECG data and the patient's personal metrics, provide a brief, clear, and professional summary of any key observations. If abnormalities are suspected, include a gentle suggestion to consult a cardiologist.

        Patient information:
        \(userInfo)

        ECG data (Lead I, millivolts, sampled over time):
        \(ecgCSV.prefix(2000))

        Please write the result in plain English using 2–4 sentences.
        Avoid overly technical terms unless necessary, and do not give a diagnosis.
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-4o",
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
