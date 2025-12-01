//
//  ComplicationController.swift
//  ChatOnWristWatch Watch App
//
//  Created for Complication Support
//

import ClockKit
import SwiftUI
import UIKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        // Use families that are available in all watchOS versions
        let families: [CLKComplicationFamily] = [
            .graphicCircular,
            .graphicCorner,
            .graphicRectangular,
            .circularSmall,
            .modularSmall,
            .utilitarianSmall
        ]
        
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.chatonwrist.quickdictation",
                displayName: "Quick Dictation",
                supportedFamilies: families,
                userInfo: ["action": "dictate"] // Pass action info
            )
        ]
        handler(descriptors)
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let template = getTemplate(for: complication.family)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = getTemplate(for: complication.family)
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createMicImageProvider() -> CLKImageProvider {
        // Simple SF Symbol - always works perfectly
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .medium)
        guard let messageImage = UIImage(systemName: "message.fill", withConfiguration: config) else {
            // Fallback to mic if message.fill not available
            let micConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .medium)
            guard let micImage = UIImage(systemName: "mic.fill", withConfiguration: micConfig) else {
                // Ultimate fallback - create a simple circle
                let size = CGSize(width: 20, height: 20)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                defer { UIGraphicsEndImageContext() }
                let context = UIGraphicsGetCurrentContext()!
                context.setFillColor(UIColor(red: 25/255, green: 149/255, blue: 254/255, alpha: 1.0).cgColor)
                context.fillEllipse(in: CGRect(origin: .zero, size: size))
                return CLKImageProvider(onePieceImage: UIGraphicsGetImageFromCurrentImageContext() ?? UIImage())
            }
            let imageProvider = CLKImageProvider(onePieceImage: micImage)
            imageProvider.tintColor = UIColor(red: 25/255, green: 149/255, blue: 254/255, alpha: 1.0)
            return imageProvider
        }
        
        let imageProvider = CLKImageProvider(onePieceImage: messageImage)
        imageProvider.tintColor = UIColor(red: 25/255, green: 149/255, blue: 254/255, alpha: 1.0)
        return imageProvider
    }
    
    private func getTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate {
        switch family {
        // Graphic families (watchOS 7.0+)
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularView(
                ComplicationViewCircular()
            )
            
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerCircularView(
                ComplicationViewCorner()
            )
            
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularFullView(
                ComplicationViewRectangular()
            )
            
        // Legacy families - use image provider with system icon
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: createMicImageProvider())
            
        case .modularSmall:
            return CLKComplicationTemplateModularSmallSimpleImage(imageProvider: createMicImageProvider())
            
        case .utilitarianSmall:
            return CLKComplicationTemplateUtilitarianSmallFlat(
                textProvider: CLKSimpleTextProvider(text: ""),
                imageProvider: createMicImageProvider()
            )
            
        default:
            // Fallback to circular graphic
            return CLKComplicationTemplateGraphicCircularView(
                ComplicationViewCircular()
            )
        }
    }
    
    // MARK: - Complication Actions
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        // When complication is tapped, post notification to start dictation
        if let userInfo = userActivity.userInfo,
           let action = userInfo["action"] as? String,
           action == "dictate" {
            NotificationCenter.default.post(
                name: NSNotification.Name("ComplicationTapped"),
                object: nil,
                userInfo: ["action": "dictate"]
            )
        }
    }
}

// MARK: - Complication Views

// Note: Complications run in a separate process, so we define colors directly here
private let complicationAccentColor = Color(red: 25/255, green: 149/255, blue: 254/255) // #1995fe

struct ComplicationViewCircular: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(complicationAccentColor.opacity(0.2))
            
            // Simple SF Symbol - always works perfectly
            Image(systemName: "message.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(complicationAccentColor)
        }
    }
}

struct ComplicationViewCorner: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(complicationAccentColor.opacity(0.2))
            
            // Simple SF Symbol - always works perfectly
            Image(systemName: "message.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(complicationAccentColor)
        }
    }
}

struct ComplicationViewRectangular: View {
    var body: some View {
        // Simple SF Symbol - always works perfectly
        Image(systemName: "message.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(complicationAccentColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

