import Foundation

func login() {
    // Define your login credentials and URL
    let account = AccountDataStore.shared.retrieveAccounts()?.first(where: { $0.website.website == Websites().extorrenty.website })
    let loginURL = URL(string: "https://\(Websites().extorrenty.website)/takelogin.php")!

    // Create a session configuration
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig)

    // Create the login request
    var loginRequest = URLRequest(url: loginURL)
    loginRequest.httpMethod = "POST"

    // Create the login parameters
    let loginParams = "username=\(account!.login)&password=\(account!.password)"
    loginRequest.httpBody = loginParams.data(using: .utf8)

    // Create a task to perform the login request
    let loginTask = session.dataTask(with: loginRequest) { (data, response, error) in
        guard let _ = data, let response = response as? HTTPURLResponse, error == nil else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        if response.statusCode != 200 {
            print("Login failed with status code \(response.statusCode)")
        }
    }

    // Start the login task
    loginTask.resume()
}
