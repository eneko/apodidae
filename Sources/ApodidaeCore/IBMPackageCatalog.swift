import Foundation
import PromiseKit

struct PCResponse: Decodable {
    let packages: [PCPackage]

    private enum RootKeys: String, CodingKey {
        case data
    }

    private enum DataKeys: String, CodingKey {
        case hits
    }

    private enum HitsKeys: String, CodingKey {
        case hits
    }

    public init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootKeys.self)
        let dataContainer = try rootContainer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        let hitsContainer = try dataContainer.nestedContainer(keyedBy: HitsKeys.self, forKey: .hits)
        self.packages = try hitsContainer.decode([PCPackage].self, forKey: .hits)
    }
}

public struct PCPackage: Decodable {
    public let name: String
    public let description: String
    public let repository: URL
    public let latestVersion: String?
    public let stars: Int

    private enum CodingKeys: String, CodingKey {
        case name = "package_full_name"
        case description
        case repository = "git_clone_url"
        case latestVersion = "latest_version"
        case stars = "stargazers_count"
    }

    private enum SourceKeys: String, CodingKey {
        case source = "_source"
    }

    public init(from decoder: Decoder) throws {
        let sourceContainer = try decoder.container(keyedBy: SourceKeys.self)
        let container = try sourceContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .source)

        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.repository = try container.decode(URL.self, forKey: .repository)
        self.latestVersion = try container.decodeIfPresent(String.self, forKey: .latestVersion)
        self.stars = try container.decode(Int.self, forKey: .stars)
    }
}

public enum PackageCatalog {
    public static func search(query: String) -> Promise<[PCPackage]> {
        guard
            let escaped = query.urlHostEscaped,
            let url = URL(string: "https://packagecatalog.com/api/search/\(escaped)?page=1&items=100&chart=moststarred")
        else {
            return Promise(error: Error.invalidQuery)
        }

        let request = URLRequest(url: url)
        return Network.dataTask(request: request).then { (response: PCResponse) in
            response.packages
        }
    }
}