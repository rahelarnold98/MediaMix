import Foundation

struct AppConfig: Codable {
    let apiBaseURL: String
}

class ConfigurationManager {
    static let shared = ConfigurationManager()
    private var config: AppConfig?

    private init() {
        loadConfig()
    }

    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Config file not found or invalid")
        }

        do {
            config = try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            fatalError("Failed to decode config file: \(error)")
        }
    }

    var apiBaseURL: String {
        config?.apiBaseURL ?? ""
    }
}
