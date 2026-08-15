import { LRUCache } from "lru-cache";

// Configure LRU Cache (max 1000 entries, default 5 minute TTL)
const cacheInstance = new LRUCache<string, any>({
  max: 1000,
  ttl: 1000 * 60 * 5, // 5 minutes
  ttlAutopurge: true,
});

export class CacheManager {
  /**
   * Fetch item from cache
   */
  static get<T>(key: string): T | undefined {
    return cacheInstance.get(key) as T | undefined;
  }

  /**
   * Set item in cache with optional TTL in ms
   */
  static set(key: string, value: any, ttlMs?: number): void {
    cacheInstance.set(key, value, { ttl: ttlMs });
  }

  /**
   * Delete specific key
   */
  static del(key: string): void {
    cacheInstance.delete(key);
  }

  /**
   * Invalidate all cache entries matching a user prefix (e.g. user:60d5ec...)
   */
  static invalidateUser(userId: string): void {
    const userPrefix = `user:${userId}:`;
    const keysToDelete: string[] = [];
    for (const key of cacheInstance.keys()) {
      if (typeof key === "string" && key.startsWith(userPrefix)) {
        keysToDelete.push(key);
      }
    }
    for (const key of keysToDelete) {
      cacheInstance.delete(key);
    }
  }

  /**
   * Flush entire cache
   */
  static clearAll(): void {
    cacheInstance.clear();
  }
}
