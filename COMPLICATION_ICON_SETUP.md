# How to Add Complication Icon

## Step-by-Step Instructions

### 1. Add the Image Set to Assets.xcassets

1. In Xcode, navigate to your Watch App target:
   - In the Project Navigator (left sidebar), find `ChatOnWristWatch Watch App`
   - Expand it and find `Assets.xcassets`
   - Click on `Assets.xcassets` to open it

2. Create a new Image Set:
   - Right-click anywhere in the Assets catalog (the empty area on the right)
   - Select **"New Image Set"** from the context menu
   - OR click the **"+"** button at the bottom of the Assets catalog window
   - Name it exactly: **`ComplicationIcon`** (case-sensitive)

### 2. Add Your Icon Image

1. Drag your icon image file into the `ComplicationIcon` image set
   - You can drag it into the "Universal" slot (works for all sizes)
   - Or add specific sizes: 1x, 2x, 3x
   - Recommended: Use a single image in the "Universal" slot

2. Your icon should be:
   - Simple, single-color design (black/white)
   - Square format (e.g., 1024x1024 pixels)
   - PNG format recommended

### 3. Set "Render As" to Template Image

**Method 1: Using Attributes Inspector**

1. Click on the `ComplicationIcon` image set in the Assets catalog (select it)
2. Look at the right side of Xcode - you should see the **Attributes Inspector** panel
3. If you don't see it:
   - Go to **View** → **Inspectors** → **Show Attributes Inspector**
   - Or press **⌥⌘4** (Option + Command + 4)
4. In the Attributes Inspector, find the **"Render As"** dropdown menu
5. Change it from **"Default"** to **"Template Image"**

**Method 2: Using the Image Set Editor**

1. Select the `ComplicationIcon` image set
2. In the main editor area (center), you'll see the image slots
3. Look for a dropdown or settings icon near the image
4. Find the "Render As" option and set it to "Template Image"

**Visual Guide:**
```
Assets.xcassets
├── AppIcon.appiconset
├── AccentColor.colorset
└── ComplicationIcon (← Select this)
    └── [Your icon image here]
    
Attributes Inspector (right panel):
┌─────────────────────────┐
│ Render As:             │
│ [Template Image ▼]     │ ← Change this dropdown
└─────────────────────────┘
```

### 4. Verify It's Set Correctly

- The image set should show "Template Image" in the Attributes Inspector
- Your icon will now be tinted with your app's accent color (#1995fe)

### 5. Build and Test

- Build your project (⌘B)
- Run on your Apple Watch
- Add the complication to your watch face
- Your custom icon should appear instead of the microphone symbol

## Troubleshooting

**If you can't find "Render As":**
- Make sure you've selected the Image Set itself (not just the image)
- Try clicking directly on the `ComplicationIcon` name in the Assets catalog
- The Attributes Inspector should show image set properties, not image properties

**If the icon doesn't appear:**
- Make sure the image set is named exactly `ComplicationIcon` (case-sensitive)
- Make sure the image is added to the Watch App target (not the iOS app target)
- Check that the image file is actually in the image set (you should see it in the preview)

**Alternative: Use SF Symbol Instead**
If you prefer to use an SF Symbol instead of a custom image, you can change the code to use a different symbol name in `ComplicationController.swift`.




