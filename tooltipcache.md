## Complete Plan for Toggleable Caching Solution

I've developed a comprehensive plan for implementing a toggleable caching solution that addresses slow Lute server issues while preserving the current flow:

### Key Requirements Met:
1. **Preserves Current Flow**: When caching is disabled, behavior is identical to current implementation
2. **Handles Terms Without Data**: No tooltips shown for terms without data, regardless of cache setting
3. **Manages Frequent Updates**: Extended TTL (48 hours) with event-based invalidation and manual refresh option ensure data freshness
4. **Provides Fallback**: Users with slow servers get immediate responses from cache

### Implementation Approach:
- Use hive_ce for persistent caching (already integrated in the project)
- Create a dedicated Hive box for tooltip caching with wordId as key
- Add TTL metadata to manage cache expiration
- Implement cache size management with 200MB limit and LRU eviction
- Integrate toggle setting in the app's settings
- Modify provider layer to conditionally use cache when enabled
- Implement smart cache invalidation: update specific term immediately after save
- Follow correct page load sequence: Load page → Load tooltip cache → Fetch new tooltip data → Preload next pages
- Use unified cache for both ReaderScreen tooltips and SentenceReader termforms
- Add manual "Refresh tooltip cache" option in settings when caching is enabled
- Include basic cache statistics for monitoring (size, hit rate)
- Maintain complete backward compatibility when caching is disabled

This solution provides users with slow Lute servers a significant performance improvement while maintaining the exact same behavior for users who prefer the current direct-server approach.