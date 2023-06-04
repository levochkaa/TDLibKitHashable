// TdApi.swift

import UIKit
import TDLibKit

let tdApi: TdApi = .shared

extension TdApi {
    static var shared = TdApi(client: TdClientImpl(completionQueue: .global(qos: .userInitiated)))
    
    var modelName: String {
        var simulator = false
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        var identifier = machineMirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
        
        if ["i386", "x86_64", "arm64"].contains(identifier) {
            identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"
            simulator = true
        }
        
        switch identifier {
            case "iPhone10,1", "iPhone10,4": identifier = "iPhone 8"
            case "iPhone10,2", "iPhone10,5": identifier = "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6": identifier = "iPhone X"
            case "iPhone11,2": identifier = "iPhone XS"
            case "iPhone11,4", "iPhone11,6": identifier = "iPhone XS Max"
            case "iPhone11,8": identifier = "iPhone XR"
            case "iPhone12,1": identifier = "iPhone 11"
            case "iPhone12,3": identifier = "iPhone 11 Pro"
            case "iPhone12,5": identifier = "iPhone 11 Pro Max"
            case "iPhone13,1": identifier = "iPhone 12 mini"
            case "iPhone13,2": identifier = "iPhone 12"
            case "iPhone13,3": identifier = "iPhone 12 Pro"
            case "iPhone13,4": identifier = "iPhone 12 Pro Max"
            case "iPhone14,4": identifier = "iPhone 13 mini"
            case "iPhone14,5": identifier = "iPhone 13"
            case "iPhone14,2": identifier = "iPhone 13 Pro"
            case "iPhone14,3": identifier = "iPhone 13 Pro Max"
            case "iPhone14,7": identifier = "iPhone 14"
            case "iPhone14,8": identifier = "iPhone 14 Plus"
            case "iPhone15,2": identifier = "iPhone 14 Pro"
            case "iPhone15,3": identifier = "iPhone 14 Pro Max"
            case "iPhone8,4":  identifier = "iPhone SE"
            case "iPhone12,8": identifier = "iPhone SE (2nd)"
            case "iPhone14,6": identifier = "iPhone SE (3rd)"
            default: break
        }
        return simulator ? "Simulator \(identifier)" : identifier
    }
    
    func startTdLibUpdateHandler() {
        setPublishers()
        
        client.run { data in
            do {
                let update = try TdApi.shared.decoder.decode(Update.self, from: data)
                self.update(update)
            } catch {
                print("Error TdLibUpdateHandler: \(error)")
            }
        }
    }
    
    func setPublishers() {
        nc.publisher(for: .waitTdlibParameters) { _ in
            Task {
                var url = try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                url.append(path: "td")
                let dir = url.path()
                
                // TODO: UPDATE Secret.swift file with your api_id and api_hash, obtained at https://my.telegram.org/
                _ = try await self.setTdlibParameters(
                    apiHash: Secret.apiHash,
                    apiId: Secret.apiId,
                    applicationVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    databaseDirectory: dir,
                    databaseEncryptionKey: Data(),
                    deviceModel: modelName,
                    enableStorageOptimizer: true,
                    filesDirectory: dir,
                    ignoreFileNames: false,
                    systemLanguageCode: "en-US",
                    systemVersion: UIDevice.current.systemVersion,
                    useChatInfoDatabase: true,
                    useFileDatabase: true,
                    useMessageDatabase: true,
                    useSecretChats: true,
                    useTestDc: false
                )
            }
        }
        
        nc.publisher(for: .closed) { _ in
            TdApi.shared = TdApi(client: TdClientImpl(completionQueue: .global(qos: .userInitiated)))
            TdApi.shared.startTdLibUpdateHandler()
        }
    }
    
    func update(_ update: Update) {
        switch update {
            case .updateAuthorizationState(let updateAuthorizationState):
                self.updateAuthorizationState(updateAuthorizationState.authorizationState)
            case .updateNewMessage(let updateNewMessage):
                Task.main { nc.post(name: .newMessage, object: updateNewMessage) }
            case .updateMessageSendSucceeded(let updateMessageSendSucceeded):
                nc.post(name: .messageSendSucceeded, object: updateMessageSendSucceeded)
            case .updateMessageSendFailed(let updateMessageSendFailed):
                nc.post(name: .messageSendFailed, object: updateMessageSendFailed)
            case .updateMessageContent(let updateMessageContent):
                nc.post(name: .messageSendContent, object: updateMessageContent)
            case .updateMessageEdited(let updateMessageEdited):
                Task.main { nc.post(name: .messageEdited, object: updateMessageEdited) }
            case .updateNewChat(let updateNewChat):
                nc.post(name: .newChat, object: updateNewChat)
            case .updateChatLastMessage(let updateChatLastMessage):
                nc.post(name: .chatLastMessage, object: updateChatLastMessage)
            case .updateChatPosition(let updateChatPosition):
                nc.post(name: .chatPosition, object: updateChatPosition)
            case .updateChatReadInbox(let updateChatReadInbox):
                Task.main { nc.post(name: .chatReadInbox, object: updateChatReadInbox) }
            case .updateChatDraftMessage(let updateChatDraftMessage):
                nc.post(name: .chatDraftMessage, object: updateChatDraftMessage)
            case .updateChatUnreadMentionCount(let updateChatUnreadMentionCount):
                nc.post(name: .chatUnreadMentionCount, object: updateChatUnreadMentionCount)
            case .updateChatUnreadReactionCount(let updateChatUnreadReactionCount):
                nc.post(name: .chatUnreadReactionCount, object: updateChatUnreadReactionCount)
            case .updateDeleteMessages(let updateDeleteMessages):
                nc.post(name: .deleteMessages, object: updateDeleteMessages)
            case .updateChatAction(let updateChatAction):
                nc.post(name: .chatAction, object: updateChatAction)
            case .updateUserStatus(let updateUserStatus):
                nc.post(name: .userStatus, object: updateUserStatus)
            case .updateUser(let updateUser):
                nc.post(name: .user, object: updateUser)
            case .updateFile(let updateFile):
                Task.main { nc.post(name: .file, object: updateFile) }
            default:
                break
        }
    }
    
    func updateAuthorizationState(_ authorizationState: AuthorizationState) {
        switch authorizationState {
            case .authorizationStateWaitTdlibParameters:
                nc.post(name: .waitTdlibParameters)
            case .authorizationStateWaitPhoneNumber:
                nc.post(name: .waitPhoneNumber)
            case .authorizationStateWaitEmailAddress(let authorizationStateWaitEmailAddress):
                nc.post(name: .waitEmailAddress, object: authorizationStateWaitEmailAddress)
            case .authorizationStateWaitEmailCode(let authorizationStateWaitEmailCode):
                nc.post(name: .waitEmailCode, object: authorizationStateWaitEmailCode)
            case .authorizationStateWaitCode(let authorizationStateWaitCode):
                nc.post(name: .waitCode, object: authorizationStateWaitCode)
            case .authorizationStateWaitOtherDeviceConfirmation(let authorizationStateWaitOtherDeviceConfirmation):
                nc.post(name: .waitOtherDeviceConfirmation, object: authorizationStateWaitOtherDeviceConfirmation)
            case .authorizationStateWaitRegistration(let authorizationStateWaitRegistration):
                nc.post(name: .waitRegistration, object: authorizationStateWaitRegistration)
            case .authorizationStateWaitPassword(let authorizationStateWaitPassword):
                nc.post(name: .waitPassword, object: authorizationStateWaitPassword)
            case .authorizationStateReady:
                nc.post(name: .ready)
            case .authorizationStateLoggingOut:
                nc.post(name: .loggingOut)
            case .authorizationStateClosing:
                nc.post(name: .closing)
            case .authorizationStateClosed:
                nc.post(name: .closed)
        }
    }
}
