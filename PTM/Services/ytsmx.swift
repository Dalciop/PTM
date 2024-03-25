//
//  ytsmx.swift
//  PTM
//
//  Created by Dominik Grandys on 25/03/2024.
//

import Foundation
import SwiftSoup

struct YtsmxResult {
    var link: String
    var name: String
    var year: String
    var img: String
    var tags = [Tag]()
    var torrents = [YtsmxTorrent]()
}

struct Tag {
    var link: String
    var name: String
}

struct YtsmxTorrent {
    var quality: String
    var link: String
    var size: String
    var resolution: String
    var audio: String
    var age_rating: String
    var framerate: String
    var time: String
    var seed: String
}

class Ytsmx {
    func search(query: String, completion: @escaping ([YtsmxResult]?) -> Void) {
        guard let url = URL(string: "https://\(Websites().ytsmx.website)/browse-movies/\(query.replacingOccurrences(of: " ", with: "%20"))/all/all/0/latest/0/all") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let html = String(data: data, encoding: .utf8)
                completion(self.parseSearchHTML(html))
            }
        }.resume()
    }
    
    func details(result: YtsmxResult, completion: @escaping (YtsmxResult?) -> Void) {
        guard let url = URL(string: result.link) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let html = String(data: data, encoding: .utf8)
                completion(self.parseDetailsHTML(html, result: result))
            }
        }.resume()
    }
    
    private func parseDetailsHTML(_ html: String?, result: YtsmxResult) -> YtsmxResult? {
        guard let html = html else {
            return nil
        }

        do {
            let doc = try SwiftSoup.parse(html)
            var _result = YtsmxResult(link: result.link, name: result.name, year: result.year, img: result.img)
            try doc.select("div#movie-content div.row p span a").forEach { element in
                _result.tags.append(Tag(link: try element.attr("href").replacingOccurrences(of: " ", with: "%20"), name: try element.html()))
            }
            try doc.select("div#movie-tech-specs span.tech-quality").enumerated().forEach { index, element in
                let spec = try doc.select("div#movie-tech-specs div.tech-spec-info")[index].children()
                let fd = spec.first()?.children()
                let sd = spec.last()?.children()
                _result.torrents.append(YtsmxTorrent(
                    quality: try element.html(),
                    link: try doc.select("div#movie-info p").first?.select("a")[index].attr("href") ?? "",
                    size: try fd?.select("div").first()?.text() ?? "",
                    resolution: try fd?.select("div")[2].text() ?? "",
                    audio: try fd?.select("div")[4].text() ?? "",
                    age_rating: try fd?.select("div")[6].text() ?? "",
                    framerate: try sd?.select("div")[2].text() ?? "",
                    time: try sd?.select("div")[4].text() ?? "",
                    seed: try sd?.select("div").last()?.text().components(separatedBy: " ")[1] ?? ""
                ))
            }
            return _result
        } catch {
            print("Błąd parsowania HTML: \(error)")
        }
        return nil
    }

    private func parseSearchHTML(_ html: String?) -> [YtsmxResult]? {
        guard let html = html else {
            return nil
        }

        do {
            let doc = try SwiftSoup.parse(html)
            var results: [YtsmxResult] = []
            try doc.select("div.browse-movie-wrap").forEach { element in
                results.append(YtsmxResult(
                    link: try element.select("div.browse-movie-bottom a").first?.attr("href") ?? "",
                    name: try element.select("div.browse-movie-bottom a").first?.select("span").first?.html() ?? "",
                    year: try element.select("div.browse-movie-year").first?.html() ?? "",
                    img: try element.select("img").first?.attr("src") ?? ""
                ))
            }
            return results
        } catch {
            print("Błąd parsowania HTML: \(error)")
        }
        return nil
    }
}
