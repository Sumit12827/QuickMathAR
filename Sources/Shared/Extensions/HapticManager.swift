//
//  HapticManager.swift
//  QuickMathsAR
//
//  Centralized haptic feedback manager.
//  Generators are pre-warmed for zero-latency response.
//

#if os(iOS)
import UIKit
import CoreHaptics

public enum HapticFeedbackStyle {
    case tap
    case light
    case medium
    case heavy
    case success
    case error
    case warning
    case selection
    case continuous(intensity: Float, sharpness: Float)
}

public final class HapticManager {
    public static let shared = HapticManager()
    
    // Legacy generators
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // Core Haptics engine
    private var engine: CHHapticEngine?
    
    private init() {
        UserDefaults.standard.register(defaults: ["hapticFeedback": true])
        prepare()
        createEngine()
    }
    
    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "hapticFeedback")
    }
    
    public func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    private func createEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Re-start engine if it stops (e.g. backgrounding)
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            print("Haptic Engine Error: \(error)")
        }
    }
    
    // MARK: - Public API
    
    public func play(_ style: HapticFeedbackStyle) {
        guard isEnabled else { return }
        
        switch style {
        case .tap:
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
            
        case .light:
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
            
        case .medium:
            mediumGenerator.impactOccurred()
            mediumGenerator.prepare()
            
        case .heavy:
            heavyGenerator.impactOccurred()
            heavyGenerator.prepare()
            
        case .success:
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
            
        case .error:
            notificationGenerator.notificationOccurred(.error)
            notificationGenerator.prepare()
            
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
            
        case .selection:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
            
        case .continuous(let intensity, let sharpness):
            playContinuous(intensity: intensity, sharpness: sharpness)
        }
    }
    
    // MARK: - Core Haptics Implementation
    
    private func playContinuous(intensity: Float, sharpness: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = engine else { return }
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play continuous haptic: \(error)")
        }
    }
    
    // MARK: - Legacy Support (Deprecating slowly)
    
    public func tap() { play(.tap) }
    public func light() { play(.light) }
    public func medium() { play(.medium) }
    public func heavy() { play(.heavy) }
    public func success() { play(.success) }
    public func error() { play(.error) }
    public func selection() { play(.selection) }
}


#endif
