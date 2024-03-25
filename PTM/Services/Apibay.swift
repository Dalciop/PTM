import Foundation

private let baseURL = "https://apibay.org"

class Apibay {
    func search(query: String, category: String = "", completion: @escaping ([Torrent]) -> Void) {
        let urlString = "https://apibay.org/q.php?q=\(query.replacingOccurrences(of: " ", with: "+"))&cat=\(category)"
        
        print(urlString)
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([ApiBayTorrent].self, from: data)
                completion(decodedData.convertToTorrent())
            } catch {
                print("Error decoding JSON: \(error)")
                completion([])
            }
        }
        task.resume()
    }    
}

private struct ApiBayTorrent: Identifiable, Codable {
    let id: String
    let name: String
    let info_hash: String
    let leechers: String
    let seeders: String
    let num_files: String
    let size: String
    let username: String
    let added: String
    let status: String
    let category: String
    let imdb: String
}

extension Array where Element == ApiBayTorrent {
    func convertToTorrent() -> [Torrent] {
        var torrentList = [Torrent]()
        self.forEach { torrent in
            torrentList.append(Torrent(
                website: Websites().apibay,
                category: torrent.category,
                link: "magnet:?xt=urn:btih:\(torrent.info_hash)&dn=\(torrent.name)",
                name: torrent.name,
                size: bytesToReadableString(Int(torrent.size)!),
                seed: torrent.seeders,
                peer: torrent.leechers,
                uploader: torrent.username
            ))
        }
        return torrentList
    }
}

private func bytesToReadableString(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}
