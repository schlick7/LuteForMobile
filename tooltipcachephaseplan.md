# Tooltip Cache Implementation Phase Plan

## Phase 1: Cache Infrastructure Setup
- Set up Hive box for tooltip caching
- Create cache service with basic CRUD operations
- Implement extended TTL (48 hours) functionality
- Add cache size management with 200MB limit and LRU eviction
- Initialize Hive box during app startup (no current usage)
- Add error handling for cache operations

## Phase 2: Settings Integration
- Add toggle option in settings for "Enable tooltip caching"
- Store setting in existing settings provider
- Add explanatory text about the feature
- Add "Refresh tooltip cache" option in hamburger menu when caching is enabled

## Phase 3: Provider Layer Integration
- Modify reader provider to conditionally use cache based on settings
- Create wrapper methods that check cache first when enabled
- Maintain backward compatibility when disabled

## Phase 4: Cache Invalidation Logic
- Implement cache update on term save (immediate refresh)
- Add cache invalidation for affected parent/child terms
- Implement page-level cache preloading

## Phase 5: Page Load Sequence Implementation
- Implement correct sequence: Load page → Load tooltip cache → Fetch new tooltip data → Preload next pages
- Ensure background refresh of cached data
- Add next-page preloading functionality

## Phase 6: Unified Cache Implementation
- Extend cache to work with both ReaderScreen tooltips and SentenceReader termforms
- Ensure consistency across both contexts
- Test synchronization between contexts

## Phase 7: Testing and Validation
- Verify current flow remains unchanged when caching is disabled
- Test performance improvements with caching enabled
- Validate cache invalidation works correctly
- Ensure terms without tooltip data behave correctly
- Test that existing SentenceReader termform update flow still works properly
- Test cache size management and LRU eviction
- Test app startup with cache initialization
- Test behavior when cache reaches size limits
- Test error handling for cache operations
