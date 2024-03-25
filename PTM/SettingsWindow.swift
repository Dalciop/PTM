import Foundation
import SwiftUI

import Foundation
import SwiftUI

struct SettingsWindow: View {
    @Binding var isShowingSettingsWindow: Bool
    
    @State private var isPopupPresent: Bool = false
    @State private var accountSelection: UUID?
    
    @State private var accountsList = [Account]()
    
    init(isShowingSettingsWindow: Binding<Bool>) {
        self._isShowingSettingsWindow = isShowingSettingsWindow
        self._accountsList = State(initialValue: AccountDataStore.shared.retrieveAccounts() ?? [])
    }
    
    var body: some View {
        let waList = convertToWebsiteList(accounts: accountsList)
        HStack {
            VStack {
                AccountListView(singleSelection: $accountSelection, waList: waList)
                HStack {
                    Button(action: { isPopupPresent = true }) {
                        Image(systemName: "plus")
                    }.popover(isPresented: $isPopupPresent) {
                        addAccountDialog(isPopupPresent: $isPopupPresent)
                    }
                    Button(action: {
                        if(accountSelection != nil) {
                            AccountDataStore.shared.removeAccount(accountsList.first(where: { $0.id == accountSelection })!)
                        }
                    }) {
                        Image(systemName: "minus")
                    }
                    .disabled(false)
                }
                Button(action: {
                     isShowingSettingsWindow = false
                }, label: {
                    Text("Ok")
                }).padding()
            }
//            List(PreferenceDataStore.shared.retrievePreference()) { preference in
//                Toggle(preference.name, isOn: preference.$enabled).onChange(of: preference.enabled) { newValue in
//                    preference.enabled = newValue
//                    PreferenceDataStore.shared.changePreference(preference)
//                }
//            }
        }
    }
}


var supportedWebsites: [Website] = [
    Website(website: "ex-torrenty.org", requireLogin: true),
    Website(website: "thepiratebay.org", requireLogin: false)
]

struct addAccountDialog: View {
    @Binding var isPopupPresent: Bool
    @State private var selectedWebsite = Website(website:"Wybierz serwis", requireLogin: true)
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            Menu(selectedWebsite.website) {
                ForEach(supportedWebsites) { website in
                    if(website.requireLogin) {
                        Button(website.website) {
                            selectedWebsite = website
                        }
                    }
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(2)
            
            TextField("Login", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(2)
            
            SecureField("Hasło", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(2)
            
            Button(action: {
                AccountDataStore.shared.saveAccount(Account(login: username, password: password, website: selectedWebsite))
                print("dodaj konto", username, password, selectedWebsite)
                print("konta w bazie", AccountDataStore.shared.retrieveAccounts() ?? "Nie ma nic")
                isPopupPresent = false
            }) {
                Text("Dodaj konto")
                    .padding()
            }
            .disabled(!supportedWebsites.contains { $0 == selectedWebsite } && !(username != "" && password != ""))
            .padding(2)
        }
        .padding()
    }
}

struct Website: Identifiable, Equatable, Codable, Hashable {
    var id = UUID()
    var website: String
    var requireLogin: Bool
    var accounts: [Account]?
}

struct Account: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var login: String
    var password: String
    var website: Website
}

class AccountDataStore {
    private let accountsKey = "Accounts"
    static let shared = AccountDataStore()

    // Private initializer to enforce singleton pattern
    private init() {}
    
    func saveAccount(_ account: Account) {
        var existingAccounts: [Account] = self.retrieveAccounts() ?? []
        existingAccounts.append(account)
        let data = try? JSONEncoder().encode(existingAccounts)
        UserDefaults.standard.set(data, forKey: accountsKey)
    }
    
    func retrieveAccounts() -> [Account]? {
        guard let accountDataArray = UserDefaults.standard.data(forKey: accountsKey) else {
            return nil
        }
        return try? JSONDecoder().decode([Account].self, from: accountDataArray) 
    }
    
    func removeAccount(_ account: Account) {
        print("remove ", account)
        var existingAccounts: [Account] = self.retrieveAccounts() ?? []
        existingAccounts.removeAll { $0 == account }
        let data = try? JSONEncoder().encode(existingAccounts)
        UserDefaults.standard.set(data, forKey: accountsKey)
    }
}

class PreferenceDataStore {
    private let preferenceKey = "Preferences"
    static let shared = PreferenceDataStore()
    
    // Private initializer to enforce singleton pattern
    private init() {}
    
    func changePreference(_ preference: Preference) {
        var existingPreferences: [Preference] = self.retrievePreference() ?? []
        if(existingPreferences.contains(where: { preference.id == $0.id })) {
            var existingPreference = existingPreferences.first(where: { preference.id == $0.id })!
            existingPreference.enabled = preference.enabled
            existingPreferences.removeAll(where: { $0.id == existingPreference.id })
            existingPreferences.append(existingPreference)
        } else {
            existingPreferences.append(preference)
        }
        let data = try? JSONEncoder().encode(existingPreferences)
        UserDefaults.standard.set(data, forKey: preferenceKey)
    }
    
    func retrievePreference() -> [Preference]? {
        guard let preferenceDataArray = UserDefaults.standard.data(forKey: preferenceKey) else {
            return [
                Preference(name: "Hide pornography", enabled: false),
                Preference(name: "Hide CAM Videos", enabled: true)
            ]
        }
        return try? JSONDecoder().decode([Preference].self, from: preferenceDataArray)
    }
}

struct Preference: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var enabled: Bool
}

func convertToWebsiteList(accounts: [Account]) -> [Website] {
    var websitesDict = [Website: [Account]]()

    for account in accounts {
        if var existingAccounts = websitesDict[account.website] {
            existingAccounts.append(account)
            websitesDict[account.website] = existingAccounts
        } else {
            websitesDict[account.website] = [account]
        }
    }

    var websites: [Website] = []
    for (website, websiteAccounts) in websitesDict {
        let website = Website(id: website.id, website: website.website, requireLogin: website.requireLogin, accounts: websiteAccounts)
        websites.append(website)
    }

    return websites
}

func AccountListView(singleSelection: Binding<UUID?>, waList: [Website]) -> some View {
    NavigationView {
        List(selection: singleSelection) {
            ForEach(waList) { website in
                if(website.accounts != nil) {
                    Section(header: Text(website.website)) {
                        ForEach(website.accounts!) { account in
                            Text(account.login).tag(account.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Konta")
        .frame(width: 500, height: 300)
    }
}
