import SwiftUI

struct Websites {    
    let apibay = Website(website: "apibay.org", requireLogin: false)
    let extorrenty = Website(website: "ex-torrenty.org", requireLogin: true)
    let ytsmx = Website(website: "yts.mx", requireLogin: false)
}

struct Result {
    var website: Website
    var torrents: [Torrent]
}

struct Torrent: Hashable, Codable {
    var website: Website
    var category: String
    var link: String
    var name: String
    var size: String
    var seed: String
    var peer: String
    var uploader: String
}

struct ContentView: View {
    @State private var query: String = ""
    @State private var searchQuery: String = ""
    @State private var torrents: [Torrent] = []
    @State private var currentPage: Int = 0

    var body: some View {
        HStack {
            NavigationView {
                VStack {
                    TextField(
                        "Wyszukaj torrent",
                        text: $query
                    ).cornerRadius(5)
                    .onSubmit {
                        torrents = []
                        Extorrenty().search(query: query) { torrents in
                            self.torrents.append(contentsOf: torrents!)
                        }
                        Apibay().search(query: query) { torrents in
                            self.torrents.append(contentsOf: torrents)
                        }
                        searchQuery = query
                    }
                    .disableAutocorrection(true)
                    .padding(10)
                    List(torrents.sorted(by: { (Int($0.seed)! + Int($0.peer)!) > (Int($1.seed)! + Int($1.peer)!) }), id: \.self) { torrent in
                        NavigationLink(torrent.name,
                            destination:
                                        Text(.init("Strona: \(torrent.website.website)\n\n Nazwa: \(torrent.name)\n Link: [Pobierz](\(torrent.link))\n Kategoria: \(torrent.category)\n Waga: \(torrent.size)\n Przesyłający: \(torrent.uploader)\n Seed: \(torrent.seed)\n Peer: \(torrent.peer)"))
                        .frame(idealWidth:  500, maxWidth: .infinity, idealHeight: 300, maxHeight: .infinity)
                        ).onAppear {
                            if(!torrents.isEmpty) {
                                if(torrents.firstIndex(of: torrent) == torrents.count - 1) {
                                    currentPage+=1
                                    Extorrenty().search(query: searchQuery, page: currentPage) { torrents in
                                        self.torrents.append(contentsOf: torrents!)
                                    }
                                }
                            }
                        }
                    }.listStyle(.sidebar)
                    .refreshable {
                        Extorrenty().search(query: searchQuery) { torrents in
                            self.torrents.append(contentsOf: torrents!)
                        }
                    }
                }
            }.navigationViewStyle(DefaultNavigationViewStyle())
        }
        .onAppear {
            login()
        }
    }
}
