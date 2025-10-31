#!/usr/bin/env swift

import Foundation

// Clear conversations from UserDefaults
let userDefaults = UserDefaults.standard
let conversationsKey = "savedConversations"

// Clear the conversations data
userDefaults.removeObject(forKey: conversationsKey)
userDefaults.synchronize()

print("🗑️ All conversations cleared from UserDefaults")
print("✅ You can now start fresh!")
