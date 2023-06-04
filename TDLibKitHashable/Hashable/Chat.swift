// Chat.swift

import Foundation
import TDLibKit

/// If TDLibKit doesn't has conformance to Hashable, you would have to this for almost every model
//extension Chat: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.canBeDeletedForAllUsers)
//        hasher.combine(self.canBeDeletedOnlyForSelf)
//        hasher.combine(self.canBeReported)
//        hasher.combine(self.clientData)
//        hasher.combine(self.defaultDisableNotification)
//        hasher.combine(self.hasProtectedContent)
//        hasher.combine(self.hasScheduledMessages)
//        hasher.combine(self.id)
//        hasher.combine(self.isBlocked)
//        hasher.combine(self.isMarkedAsUnread)
//        hasher.combine(self.isTranslatable)
//        hasher.combine(self.lastReadInboxMessageId)
//        hasher.combine(self.lastReadOutboxMessageId)
//        hasher.combine(self.messageAutoDeleteTime)
//        hasher.combine(self.replyMarkupMessageId)
//        hasher.combine(self.themeName)
//        hasher.combine(self.title)
//        hasher.combine(self.unreadCount)
//        hasher.combine(self.unreadMentionCount)
//        hasher.combine(self.unreadReactionCount)
//        hasher.combine(self.actionBar)
//        hasher.combine(self.availableReactions)
//        hasher.combine(self.background)
//        hasher.combine(self.draftMessage)
//        hasher.combine(self.lastMessage)
//        hasher.combine(self.messageSenderId)
        /// Everything looks simple, just boring, until this moment (for Chat model),
        /// because from now, you have to go to ChatNotificationSettings, then ChatJoinRequestsInfo,
        /// then ChatPermissions, etc... and all their td models..
//        hasher.combine(self.notificationSettings)
//        hasher.combine(self.pendingJoinRequests)
//        hasher.combine(self.permissions)
//        hasher.combine(self.photo)
//        hasher.combine(self.positions)
//        hasher.combine(self.type)
//        hasher.combine(self.videoChat)
//    }
//}
