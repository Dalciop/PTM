//
//  extorrenty.swift
//  PTM
//
//  Created by Dominik Grandys on 20/03/2024.
//

import Foundation
import SwiftSoup

class Extorrenty {
    func search(query: String, page: Int = 0, completion: @escaping ([Torrent]?) -> Void) {
        guard let url = URL(string: "https://\(Websites().extorrenty.website)/szukaj.php?page=\(page)&search=\(query.replacingOccurrences(of: " ", with: "+"))") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let html = String(data: data, encoding: .utf8)
                completion(self.parseHTML(html))
            }
        }.resume()
    }

    private func parseHTML(_ html: String?) -> [Torrent]? {
        guard let html = html else {
            return nil
        }

        do {
            let doc = try SwiftSoup.parse(html)
            var torrents: [Torrent] = []
            try doc.select("div#content-position table tbody tr").forEach { element in
                if(try element.html().contains("colhead")) {
                    let _element = try element.select("td")
                    torrents.append(Torrent(
                        website: Websites().extorrenty,
                        category: try _element[0].text(),
                        link: try "https://" + Websites().extorrenty.website + "/" + _element[1].select("a")[0].attr("href"),
                        name: try _element[1].select("a")[0].text(),
                        size: try _element[2].text(),
                        seed: try _element[3].text(),
                        peer: try _element[4].text(),
                        uploader: try _element[5].text()
                    ))

                }
            }
            return torrents
        } catch {
            print("Błąd parsowania HTML: \(error)")
        }
        return nil
    }
}


