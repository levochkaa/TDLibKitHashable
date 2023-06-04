// ContentView.swift

import SwiftUI
import TDLibKit

struct ContentView: View {
    @StateObject var vm = ContentViewModel()
    
    var body: some View {
        if vm.loggedIn {
            NavigationStack(path: $vm.path) {
                /// Without Identifiable
                // List(vm.chats, id: \.id) { chat in
                /// Identifiable simple usage
                List(vm.chats) { chat in
                    NavigationLink(value: chat) {
                        Text(chat.title)
                    }
                }
                .navigationTitle("Chats")
                /// Hashable most possible usage
                .navigationDestination(for: Chat.self) { chat in
                    ChatView(chat: chat)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Open random chat", action: vm.openRandomChat)
                    }
                }
            }
            .environmentObject(vm)
        } else {
            VStack {
                Text("Hint: \(vm.hint)")
                TextField("Phone", text: $vm.phone)
                TextField("Code", text: $vm.code)
                SecureField("2FA", text: $vm.twofa)
                Button("Submit") {
                    Task {
                        try await vm.submit()
                    }
                }
            }
        }
    }
}

struct ChatView: View {
    @State var chat: Chat
    
    @EnvironmentObject var vm: ContentViewModel
    
    var body: some View {
        Text(chat.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open random chat", action: vm.openRandomChat)
                }
            }
    }
}

class ContentViewModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var loggedIn = false
    @Published var phone = ""
    @Published var code = ""
    @Published var twofa = ""
    @Published var hint = ""
    
    /// Of course, that would be hard to use these simple models,
    /// that TDLib sends to clients and if you build an app bigger,
    /// that just a list of chat titles,
    /// you would have to create your own custom models,
    /// that would contain more relevant data, fetch something, etc.
    @Published var chats = [Chat]()
    
    init() {
        setPublishers()
    }
    
    func openRandomChat() {
        guard let randomChat = chats.randomElement() else { return }
        /// To manage path in iOS 16 new navigation, you also have to use Hashable models
        ///
        /// All new navigation stands on Hashable...
        path.append(randomChat)
    }
    
    func submit() async throws {
        switch try await tdApi.getAuthorizationState() {
            case .authorizationStateWaitPhoneNumber:
                _ = try await tdApi.setAuthenticationPhoneNumber(phoneNumber: phone, settings: nil)
            case .authorizationStateWaitCode:
                _ = try await tdApi.checkAuthenticationCode(code: code)
            case .authorizationStateWaitPassword:
                _ = try await tdApi.checkAuthenticationPassword(password: twofa)
            default:
                break
        }
    }
    
    func setPublishers() {
        nc.publisher(for: .waitPassword) { _ in
            hint = "waitPassword"
        }
        
        nc.publisher(for: .waitCode) { _ in
            hint = "waitCode"
        }
        
        nc.mergeMany([
            nc.publisher(for: .waitPhoneNumber),
            nc.publisher(for: .closed),
            nc.publisher(for: .closing),
            nc.publisher(for: .loggingOut)
        ]) { _ in
            hint = "waitPhoneNumber (or restart app)"
        }
        
        nc.mergeMany([.closed, .closing, .loggingOut, .waitPhoneNumber, .waitCode, .waitPassword]) { _ in
            Task.main {
                loggedIn = false
            }
        }
        
        nc.publisher(for: .ready) { _ in
            Task.main {
                loggedIn = true
                try await loadChats()
            }
        }
    }
    
    @MainActor func loadChats() async throws {
        let chatIds = try await tdApi.getChats(chatList: .chatListMain, limit: 200).chatIds
        let chats = try await chatIds.asyncCompactMap { try await tdApi.getChat(chatId: $0) }
        self.chats = chats
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
