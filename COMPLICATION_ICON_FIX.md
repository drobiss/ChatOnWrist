# Complication Icon Display Issues - Fix Guide

## Problem
The complication icon appears "messed up" or distorted on the watch face.

## Root Cause
Complication icons need to be **simple, single-color silhouettes** for template rendering to work properly.

## Requirements for Complication Icons

### ✅ **Correct Format:**
- **Simple black silhouette** on transparent background
- **No gradients, shadows, or complex details**
- **Single solid color** (black) - the system will tint it
- **Square format** (e.g., 1024x1024px)
- **PNG format**

### ❌ **Wrong Format:**
- Multi-color images
- Images with gradients
- Images with shadows or effects
- Complex detailed images
- Images with transparency issues

## How to Fix

### Option 1: Use SF Symbol Instead (Easiest)
If your custom icon isn't working, you can temporarily use an SF Symbol:

The code already falls back to `mic.fill` if the custom icon isn't found or doesn't display properly.

### Option 2: Fix Your Custom Icon

1. **Open your icon image** in an image editor (Photoshop, Sketch, etc.)

2. **Convert to silhouette:**
   - Make it **pure black** (#000000) on **transparent background**
   - Remove all colors, gradients, shadows
   - Keep it simple - just the outline/shape

3. **Export:**
   - PNG format
   - 1024x1024px (or larger, square)
   - Transparent background
   - Black icon only

4. **Replace in Xcode:**
   - Open `Assets.xcassets` → `ComplicationIcon`
   - Delete old images
   - Drag in your new black silhouette
   - Make sure "Render As" is set to "Template Image"

### Option 3: Use a Different SF Symbol

You can change the fallback symbol in `ComplicationController.swift`:

```swift
Image(systemName: "message.fill")  // Instead of "mic.fill"
Image(systemName: "bubble.left.and.bubble.right.fill")
Image(systemName: "text.bubble.fill")
```

## Testing

1. Build and run on your Apple Watch
2. Add complication to watch face
3. If it still looks wrong, the image itself needs to be fixed
4. Try the SF Symbol fallback to confirm the code works

## Current Status

- ✅ Code is correct and will display custom icon if properly formatted
- ✅ Falls back to SF Symbol if custom icon has issues
- ⚠️ Your custom icon image may need to be simplified/reformatted

