//
//  ExplanationCache.swift
//  QuickMathsAR
//
//  Thread-safe cache for AI-generated explanations.
//  Uses NSCache for automatic memory management — evicts
//  entries under memory pressure without manual intervention.
//

#if os(iOS)
import Foundation

/// Caches `StepExplanation` results keyed by equation + step + level.
/// Thread-safe via NSCache's internal locking.
public final class ExplanationCache: @unchecked Sendable {
    
    // MARK: - Internal Key Wrapper
    
    /// NSCache requires NSObject keys, so we wrap our value-type StepKey.
    private final class CacheKey: NSObject {
        let key: StepKey
        
        init(_ key: StepKey) {
            self.key = key
            super.init()
        }
        
        override var hash: Int {
            key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CacheKey else { return false }
            return key == other.key
        }
    }
    
    /// NSCache requires NSObject values.
    private final class CacheEntry: NSObject {
        let explanation: StepExplanation
        let timestamp: Date
        
        init(_ explanation: StepExplanation) {
            self.explanation = explanation
            self.timestamp = Date()
            super.init()
        }
    }
    
    // MARK: - Properties
    
    private let cache: NSCache<CacheKey, CacheEntry>
    
    // MARK: - Initialization
    
    public init(countLimit: Int = 50) {
        cache = NSCache<CacheKey, CacheEntry>()
        cache.countLimit = countLimit
    }
    
    // MARK: - Public API
    
    /// Retrieve a cached explanation for the given key.
    public func get(for key: StepKey) -> StepExplanation? {
        cache.object(forKey: CacheKey(key))?.explanation
    }
    
    /// Store an explanation in the cache.
    public func set(_ explanation: StepExplanation, for key: StepKey) {
        cache.setObject(CacheEntry(explanation), forKey: CacheKey(key))
    }
    
    /// Check if a cached explanation exists for the given key.
    public func contains(_ key: StepKey) -> Bool {
        cache.object(forKey: CacheKey(key)) != nil
    }
    
    /// Clear all cached explanations.
    public func clearAll() {
        cache.removeAllObjects()
    }
}
#endif
