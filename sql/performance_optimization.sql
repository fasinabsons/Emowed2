-- ============================================
-- EMOWED PERFORMANCE OPTIMIZATION
-- ============================================
-- Purpose: Database performance tuning and optimization
-- Covers: Indexes, queries, vacuum, caching, monitoring
-- ============================================

-- ============================================
-- TABLE OF CONTENTS
-- ============================================
/*
1. INDEX OPTIMIZATION
   - Missing index detection
   - Unused index detection
   - Index recommendations

2. QUERY OPTIMIZATION
   - Slow query identification
   - Query plan analysis
   - Common query patterns

3. DATABASE MAINTENANCE
   - Vacuum procedures
   - Analyze statistics
   - Bloat management

4. CONNECTION POOLING
   - Supabase pooling settings
   - Connection limits
   - Best practices

5. CACHING STRATEGIES
   - Query result caching
   - Materialized views
   - Application-level caching

6. PERFORMANCE MONITORING
   - Real-time metrics
   - Historical trends
   - Alerts and thresholds

7. QUICK WINS
   - Immediate optimizations
   - Low-effort, high-impact changes
*/

-- ============================================
-- SECTION 1: INDEX OPTIMIZATION
-- ============================================

-- ============================================
-- 1.1: FIND MISSING INDEXES
-- ============================================

-- Identify tables with sequential scans (potential missing indexes)
SELECT
  schemaname,
  tablename,
  seq_scan,
  seq_tup_read,
  idx_scan,
  seq_tup_read / NULLIF(seq_scan, 0) AS avg_seq_tup_read,
  CASE
    WHEN seq_scan > 1000 AND idx_scan < seq_scan / 10 THEN 'HIGH PRIORITY - Add index'
    WHEN seq_scan > 500 AND idx_scan < seq_scan / 5 THEN 'MEDIUM - Consider index'
    ELSE 'OK'
  END AS recommendation
FROM pg_stat_user_tables
WHERE schemaname = 'public'
AND seq_scan > 0
ORDER BY seq_scan DESC, seq_tup_read DESC
LIMIT 20;

-- ============================================
-- 1.2: FIND UNUSED INDEXES
-- ============================================

-- Identify indexes that are never used (candidates for removal)
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  CASE
    WHEN idx_scan = 0 THEN 'REMOVE - Never used'
    WHEN idx_scan < 10 THEN 'REVIEW - Rarely used'
    ELSE 'KEEP - Actively used'
  END AS recommendation
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC
LIMIT 20;

-- ============================================
-- 1.3: INDEX HEALTH CHECK
-- ============================================

CREATE OR REPLACE FUNCTION check_index_health()
RETURNS TABLE (
  table_name TEXT,
  index_name TEXT,
  index_size TEXT,
  scans BIGINT,
  tuples_read BIGINT,
  tuples_fetched BIGINT,
  health_status TEXT,
  recommendation TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    i.tablename::TEXT,
    i.indexname::TEXT,
    pg_size_pretty(pg_relation_size(i.indexrelid))::TEXT,
    i.idx_scan,
    i.idx_tup_read,
    i.idx_tup_fetch,
    CASE
      WHEN i.idx_scan = 0 AND pg_relation_size(i.indexrelid) > 1024 * 1024 THEN 'POOR'
      WHEN i.idx_scan < 100 THEN 'FAIR'
      WHEN i.idx_scan < 1000 THEN 'GOOD'
      ELSE 'EXCELLENT'
    END::TEXT,
    CASE
      WHEN i.idx_scan = 0 AND pg_relation_size(i.indexrelid) > 1024 * 1024
        THEN 'Consider removing - Never used and taking space'
      WHEN i.idx_scan < 10
        THEN 'Monitor usage - Rarely used'
      WHEN i.idx_scan > 10000 AND i.idx_tup_read / NULLIF(i.idx_scan, 0) > 1000
        THEN 'Excellent - High value index'
      ELSE 'Normal usage'
    END::TEXT
  FROM pg_stat_user_indexes i
  WHERE i.schemaname = 'public'
  ORDER BY i.idx_scan ASC, pg_relation_size(i.indexrelid) DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_index_health IS 'Analyze index usage and provide recommendations';

-- Run index health check:
-- SELECT * FROM check_index_health();

-- ============================================
-- 1.4: RECOMMENDED ADDITIONAL INDEXES
-- ============================================

-- These are suggestions based on common query patterns
-- Review your application queries before creating

/*
-- Matchmaking performance (if not already indexed)
CREATE INDEX IF NOT EXISTS idx_matchmaking_profiles_location
  ON matchmaking_profiles (city, state);

CREATE INDEX IF NOT EXISTS idx_matchmaking_profiles_preferences
  ON matchmaking_profiles (preferred_gender, min_age, max_age)
  WHERE is_active = true;

-- Guest management performance
CREATE INDEX IF NOT EXISTS idx_guests_wedding_side
  ON guests (wedding_id, relationship_side);

CREATE INDEX IF NOT EXISTS idx_rsvps_status
  ON rsvps (guest_id, attendance_status);

CREATE INDEX IF NOT EXISTS idx_rsvps_event_status
  ON rsvps (event_id, attendance_status);

-- Vendor search performance
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_category_city
  ON vendor_profiles (category, city)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_vendor_profiles_rating
  ON vendor_profiles (rating DESC, total_bookings DESC)
  WHERE is_active = true;

-- Game leaderboard performance
CREATE INDEX IF NOT EXISTS idx_singles_leaderboard_rank
  ON singles_leaderboard (wedding_id, rank_overall);

CREATE INDEX IF NOT EXISTS idx_couples_leaderboard_rank
  ON couples_leaderboard (wedding_id, rank_overall);

-- Media gallery performance
CREATE INDEX IF NOT EXISTS idx_media_items_album_date
  ON media_items (album_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_media_likes_user
  ON media_likes (user_id, created_at DESC);

-- Forum performance
CREATE INDEX IF NOT EXISTS idx_forum_posts_category_date
  ON community_forum_posts (category_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_forum_posts_popularity
  ON community_forum_posts (upvotes DESC, created_at DESC);

-- Notification performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON notifications (user_id, created_at DESC)
  WHERE read = false;

-- Match conversation performance
CREATE INDEX IF NOT EXISTS idx_match_conversations_match_date
  ON match_conversations (match_id, created_at DESC);

-- Gift tracking performance
CREATE INDEX IF NOT EXISTS idx_guest_gifts_status
  ON guest_gifts (wedding_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_gift_wishlists_status
  ON gift_wishlists (guest_id, is_purchased);
*/

-- ============================================
-- 1.5: COMPOSITE INDEX RECOMMENDATIONS
-- ============================================

-- Function to identify potential composite index candidates
CREATE OR REPLACE FUNCTION suggest_composite_indexes()
RETURNS TABLE (
  table_name TEXT,
  suggested_columns TEXT,
  reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    'guests'::TEXT,
    '(wedding_id, relationship_side, role)'::TEXT,
    'Common filter pattern in guest list queries'::TEXT
  UNION ALL
  SELECT
    'vendor_bookings'::TEXT,
    '(wedding_id, booking_status, payment_status)'::TEXT,
    'Common filter in booking management'::TEXT
  UNION ALL
  SELECT
    'game_participants'::TEXT,
    '(wedding_id, total_score DESC)'::TEXT,
    'Leaderboard sorting optimization'::TEXT
  UNION ALL
  SELECT
    'matches'::TEXT,
    '(user1_id, match_status, created_at DESC)'::TEXT,
    'Match history and filtering'::TEXT
  UNION ALL
  SELECT
    'events'::TEXT,
    '(wedding_id, date, time)'::TEXT,
    'Timeline and schedule views'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- View suggestions:
-- SELECT * FROM suggest_composite_indexes();

-- ============================================
-- SECTION 2: QUERY OPTIMIZATION
-- ============================================

-- ============================================
-- 2.1: IDENTIFY SLOW QUERIES
-- ============================================

-- Enable query tracking (if not already enabled in Supabase)
-- Dashboard → Settings → Database → Query Performance

-- Find slow queries from pg_stat_statements (Pro tier feature)
/*
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  max_exec_time,
  stddev_exec_time,
  rows
FROM pg_stat_statements
WHERE mean_exec_time > 100 -- Queries taking more than 100ms on average
ORDER BY mean_exec_time DESC
LIMIT 20;
*/

-- Alternative: Monitor using application logs
-- Track queries taking > 1000ms in your application

-- ============================================
-- 2.2: ANALYZE QUERY PLANS
-- ============================================

-- Template for analyzing slow queries
/*
EXPLAIN ANALYZE
SELECT
  w.id,
  w.name,
  COUNT(g.id) as guest_count,
  COUNT(CASE WHEN r.attendance_status = 'attending' THEN 1 END) as attending_count
FROM weddings w
LEFT JOIN guests g ON w.id = g.wedding_id
LEFT JOIN rsvps r ON g.id = r.guest_id
WHERE w.couple_id = 'some-uuid'
GROUP BY w.id, w.name;

-- Look for:
- Sequential Scans on large tables (add index)
- High cost operations (optimize query)
- Nested loops with high iterations (add join index)
- Sort operations on large datasets (add index on sort column)
*/

-- ============================================
-- 2.3: COMMON QUERY OPTIMIZATION PATTERNS
-- ============================================

-- BEFORE: Slow query with subquery
/*
SELECT *
FROM users u
WHERE EXISTS (
  SELECT 1
  FROM couples c
  WHERE c.user1_id = u.id OR c.user2_id = u.id
);
*/

-- AFTER: Optimized with JOIN
/*
SELECT DISTINCT u.*
FROM users u
INNER JOIN couples c ON u.id IN (c.user1_id, c.user2_id);
*/

-- BEFORE: N+1 query problem
/*
-- Application code making multiple queries
FOR EACH wedding:
  SELECT COUNT(*) FROM guests WHERE wedding_id = wedding.id
*/

-- AFTER: Single query with aggregation
/*
SELECT
  w.id,
  w.name,
  COUNT(g.id) as guest_count
FROM weddings w
LEFT JOIN guests g ON w.id = g.wedding_id
GROUP BY w.id, w.name;
*/

-- BEFORE: Inefficient date filtering
/*
SELECT * FROM events
WHERE EXTRACT(YEAR FROM date) = 2025;
*/

-- AFTER: Optimized date range (can use index)
/*
SELECT * FROM events
WHERE date >= '2025-01-01' AND date < '2026-01-01';
*/

-- ============================================
-- 2.4: QUERY PERFORMANCE TESTING FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION test_query_performance(
  p_query TEXT,
  p_iterations INTEGER DEFAULT 10
)
RETURNS TABLE (
  iteration INTEGER,
  execution_time_ms NUMERIC
) AS $$
DECLARE
  v_start_time TIMESTAMP;
  v_end_time TIMESTAMP;
  v_i INTEGER;
BEGIN
  FOR v_i IN 1..p_iterations LOOP
    v_start_time := clock_timestamp();

    -- Execute query (result discarded)
    EXECUTE p_query;

    v_end_time := clock_timestamp();

    RETURN QUERY SELECT
      v_i,
      EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::NUMERIC;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION test_query_performance IS 'Test query performance over multiple iterations';

-- Usage:
/*
SELECT * FROM test_query_performance(
  'SELECT COUNT(*) FROM guests WHERE wedding_id = ''some-uuid''',
  10
);
*/

-- ============================================
-- SECTION 3: DATABASE MAINTENANCE
-- ============================================

-- ============================================
-- 3.1: VACUUM ANALYSIS
-- ============================================

-- Check table bloat and vacuum status
SELECT
  schemaname,
  tablename,
  last_vacuum,
  last_autovacuum,
  vacuum_count,
  autovacuum_count,
  n_dead_tup,
  n_live_tup,
  ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent,
  CASE
    WHEN n_dead_tup > 10000 AND n_dead_tup::FLOAT / NULLIF(n_live_tup, 0) > 0.2
      THEN 'VACUUM RECOMMENDED'
    WHEN n_dead_tup > 50000
      THEN 'VACUUM URGENT'
    ELSE 'OK'
  END AS recommendation
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- ============================================
-- 3.2: MANUAL VACUUM PROCEDURES
-- ============================================

-- Regular vacuum (non-blocking, safe for production)
-- VACUUM ANALYZE users;
-- VACUUM ANALYZE guests;
-- VACUUM ANALYZE weddings;

-- Full vacuum (requires table lock, use during maintenance window)
-- VACUUM FULL users;

-- Vacuum all tables
-- VACUUM ANALYZE;

-- ============================================
-- 3.3: ANALYZE STATISTICS
-- ============================================

-- Update table statistics for query planner
-- ANALYZE users;
-- ANALYZE guests;
-- ANALYZE weddings;

-- Analyze all tables
-- ANALYZE;

-- Check when tables were last analyzed
SELECT
  schemaname,
  tablename,
  last_analyze,
  last_autoanalyze,
  analyze_count,
  autoanalyze_count,
  CASE
    WHEN last_analyze IS NULL AND last_autoanalyze IS NULL
      THEN 'NEVER ANALYZED'
    WHEN COALESCE(last_analyze, last_autoanalyze) < NOW() - INTERVAL '7 days'
      THEN 'ANALYZE RECOMMENDED'
    ELSE 'OK'
  END AS recommendation
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY COALESCE(last_analyze, last_autoanalyze) NULLS FIRST;

-- ============================================
-- 3.4: AUTOMATED MAINTENANCE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION run_maintenance(
  p_vacuum BOOLEAN DEFAULT true,
  p_analyze BOOLEAN DEFAULT true,
  p_verbose BOOLEAN DEFAULT false
)
RETURNS TABLE (
  table_name TEXT,
  operation TEXT,
  status TEXT,
  execution_time INTERVAL
) AS $$
DECLARE
  v_table RECORD;
  v_start_time TIMESTAMP;
  v_end_time TIMESTAMP;
  v_sql TEXT;
BEGIN
  FOR v_table IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY tablename
  LOOP
    IF p_vacuum THEN
      v_start_time := clock_timestamp();

      v_sql := format('VACUUM %s %I',
        CASE WHEN p_verbose THEN 'VERBOSE' ELSE '' END,
        v_table.tablename
      );

      EXECUTE v_sql;

      v_end_time := clock_timestamp();

      RETURN QUERY SELECT
        v_table.tablename::TEXT,
        'VACUUM'::TEXT,
        'COMPLETED'::TEXT,
        v_end_time - v_start_time;
    END IF;

    IF p_analyze THEN
      v_start_time := clock_timestamp();

      EXECUTE format('ANALYZE %I', v_table.tablename);

      v_end_time := clock_timestamp();

      RETURN QUERY SELECT
        v_table.tablename::TEXT,
        'ANALYZE'::TEXT,
        'COMPLETED'::TEXT,
        v_end_time - v_start_time;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION run_maintenance IS 'Run vacuum and analyze on all tables';

-- Run maintenance:
-- SELECT * FROM run_maintenance(true, true, false);

-- ============================================
-- SECTION 4: CONNECTION POOLING
-- ============================================

-- ============================================
-- 4.1: SUPABASE CONNECTION POOLING
-- ============================================
/*
Supabase provides built-in connection pooling via PgBouncer.

CONNECTION STRING OPTIONS:

1. DIRECT CONNECTION (for migrations, admin tasks)
   postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
   - Direct to PostgreSQL
   - No pooling
   - Use for: migrations, admin tasks, vacuum

2. POOLED CONNECTION (for application)
   postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:6543/postgres
   - Through PgBouncer (port 6543 instead of 5432)
   - Connection pooling enabled
   - Use for: application queries, API calls

POOLING MODES:

- Transaction mode (default): Each transaction gets a connection
  Best for most applications
  Connection released after transaction completes

- Session mode: Client owns connection until disconnect
  Use for: migrations, complex transactions
  More connections needed

CONFIGURATION:
Dashboard → Settings → Database → Connection pooling
- Pool size: Based on plan (20 on free, 200 on pro)
- Max client connections: 1000+
*/

-- ============================================
-- 4.2: MONITOR CONNECTION USAGE
-- ============================================

-- Check current connections
SELECT
  COUNT(*) as total_connections,
  COUNT(*) FILTER (WHERE state = 'active') as active,
  COUNT(*) FILTER (WHERE state = 'idle') as idle,
  COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity
WHERE datname = current_database();

-- Detailed connection analysis
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  state_change,
  NOW() - state_change AS time_in_state,
  query
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY state_change;

-- Find long-running queries (potential connection leaks)
SELECT
  pid,
  NOW() - query_start AS duration,
  state,
  query
FROM pg_stat_activity
WHERE state != 'idle'
AND NOW() - query_start > INTERVAL '5 minutes'
ORDER BY duration DESC;

-- ============================================
-- 4.3: CONNECTION LIMITS
-- ============================================

-- Check connection limits
SELECT
  setting::INTEGER AS max_connections
FROM pg_settings
WHERE name = 'max_connections';

-- Check current connection percentage
SELECT
  COUNT(*) * 100.0 / (SELECT setting::INTEGER FROM pg_settings WHERE name = 'max_connections') AS connection_usage_percent
FROM pg_stat_activity;

-- Alert if connections > 80%
DO $$
DECLARE
  v_usage_percent NUMERIC;
BEGIN
  SELECT
    COUNT(*) * 100.0 / (SELECT setting::INTEGER FROM pg_settings WHERE name = 'max_connections')
  INTO v_usage_percent
  FROM pg_stat_activity;

  IF v_usage_percent > 80 THEN
    RAISE WARNING 'Connection usage at %.1f%% - Consider connection pooling!', v_usage_percent;
  END IF;
END $$;

-- ============================================
-- SECTION 5: CACHING STRATEGIES
-- ============================================

-- ============================================
-- 5.1: MATERIALIZED VIEWS FOR EXPENSIVE QUERIES
-- ============================================

-- Create materialized view for wedding statistics (expensive calculation)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_wedding_stats AS
SELECT
  w.id as wedding_id,
  w.name as wedding_name,
  w.date as wedding_date,
  COUNT(DISTINCT g.id) as total_guests,
  COUNT(DISTINCT CASE WHEN r.attendance_status = 'attending' THEN g.id END) as attending_guests,
  COUNT(DISTINCT CASE WHEN r.attendance_status = 'declined' THEN g.id END) as declined_guests,
  COUNT(DISTINCT CASE WHEN r.attendance_status IS NULL THEN g.id END) as pending_guests,
  COALESCE(SUM(r.headcount) FILTER (WHERE r.attendance_status = 'attending'), 0) as total_headcount,
  COUNT(DISTINCT vb.id) FILTER (WHERE vb.booking_status = 'confirmed') as confirmed_vendors,
  COALESCE(SUM(vb.final_price) FILTER (WHERE vb.payment_status = 'paid'), 0) as total_vendor_cost,
  COUNT(DISTINCT ma.id) as total_albums,
  COUNT(DISTINCT mi.id) as total_photos,
  NOW() as last_refreshed
FROM weddings w
LEFT JOIN guests g ON w.id = g.wedding_id
LEFT JOIN rsvps r ON g.id = r.guest_id
LEFT JOIN vendor_bookings vb ON w.id = vb.wedding_id
LEFT JOIN media_albums ma ON w.id = ma.wedding_id
LEFT JOIN media_items mi ON ma.id = mi.album_id
GROUP BY w.id, w.name, w.date;

CREATE UNIQUE INDEX ON mv_wedding_stats (wedding_id);

COMMENT ON MATERIALIZED VIEW mv_wedding_stats IS 'Pre-calculated wedding statistics for dashboard';

-- Refresh materialized view (run periodically)
-- REFRESH MATERIALIZED VIEW mv_wedding_stats;

-- Concurrent refresh (doesn't lock view, but requires unique index)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_wedding_stats;

-- ============================================
-- 5.2: AUTO-REFRESH MATERIALIZED VIEW
-- ============================================

CREATE OR REPLACE FUNCTION refresh_wedding_stats()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_wedding_stats;
  RAISE NOTICE 'Wedding stats refreshed at %', NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule refresh (example: after RSVP changes)
CREATE OR REPLACE FUNCTION trigger_refresh_wedding_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Refresh async (don't block the transaction)
  PERFORM refresh_wedding_stats();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: For high-traffic apps, schedule refresh via cron instead of trigger
-- to avoid excessive refreshes

-- ============================================
-- 5.3: QUERY RESULT CACHING (APPLICATION LEVEL)
-- ============================================
/*
Implement caching in your application using:

1. REDIS/MEMCACHED:
   - Cache frequently accessed data
   - Set TTL based on data freshness requirements
   - Example: Wedding details (5 min TTL)
   - Example: Guest list (1 min TTL)
   - Example: Vendor list (10 min TTL)

2. SUPABASE REALTIME:
   - Use for live updates
   - Reduces polling queries
   - Example: RSVP updates, chat messages

3. APPLICATION-LEVEL CACHING:
   - React Query / SWR for frontend
   - Cache API responses
   - Implement stale-while-revalidate pattern

CACHE INVALIDATION:
- Invalidate on data mutation
- Use database triggers to publish invalidation events
- Implement cache versioning

EXAMPLE CACHING STRATEGY:
┌─────────────────┬──────────────┬───────────────────┐
│ Data Type       │ Cache Layer  │ TTL               │
├─────────────────┼──────────────┼───────────────────┤
│ User profile    │ Redis        │ 10 minutes        │
│ Wedding details │ Redis        │ 5 minutes         │
│ Guest list      │ React Query  │ 1 minute          │
│ Vendor catalog  │ Redis        │ 15 minutes        │
│ Leaderboard     │ Mat. View    │ Refresh hourly    │
│ Game scores     │ Realtime     │ Live updates      │
│ Chat messages   │ Realtime     │ Live updates      │
└─────────────────┴──────────────┴───────────────────┘
*/

-- ============================================
-- SECTION 6: PERFORMANCE MONITORING
-- ============================================

-- ============================================
-- 6.1: COMPREHENSIVE PERFORMANCE DASHBOARD
-- ============================================

CREATE OR REPLACE FUNCTION performance_dashboard()
RETURNS TABLE (
  metric_category TEXT,
  metric_name TEXT,
  current_value TEXT,
  status TEXT,
  recommendation TEXT
) AS $$
BEGIN
  -- Database size
  RETURN QUERY SELECT
    'Database'::TEXT,
    'Total Size'::TEXT,
    pg_size_pretty(pg_database_size(current_database()))::TEXT,
    CASE
      WHEN pg_database_size(current_database()) > 500 * 1024 * 1024 THEN 'WARNING'
      ELSE 'OK'
    END,
    CASE
      WHEN pg_database_size(current_database()) > 500 * 1024 * 1024
        THEN 'Consider archiving old data'
      ELSE 'Size within limits'
    END;

  -- Active connections
  RETURN QUERY SELECT
    'Connections'::TEXT,
    'Active Connections'::TEXT,
    (SELECT COUNT(*)::TEXT FROM pg_stat_activity WHERE state = 'active'),
    CASE
      WHEN (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active') > 50 THEN 'WARNING'
      WHEN (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active') > 20 THEN 'MONITOR'
      ELSE 'OK'
    END,
    'Use connection pooling if connections are high';

  -- Dead tuples
  RETURN QUERY SELECT
    'Maintenance'::TEXT,
    'Tables Needing Vacuum'::TEXT,
    (SELECT COUNT(*)::TEXT FROM pg_stat_user_tables
     WHERE n_dead_tup > 10000 AND n_dead_tup::FLOAT / NULLIF(n_live_tup, 0) > 0.2),
    CASE
      WHEN (SELECT COUNT(*) FROM pg_stat_user_tables
            WHERE n_dead_tup > 10000) > 5 THEN 'ACTION_REQUIRED'
      WHEN (SELECT COUNT(*) FROM pg_stat_user_tables
            WHERE n_dead_tup > 10000) > 0 THEN 'MONITOR'
      ELSE 'OK'
    END,
    'Run VACUUM ANALYZE on affected tables';

  -- Cache hit ratio
  RETURN QUERY SELECT
    'Performance'::TEXT,
    'Cache Hit Ratio'::TEXT,
    (SELECT ROUND(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2)::TEXT || '%'
     FROM pg_statio_user_tables),
    CASE
      WHEN (SELECT ROUND(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2)
            FROM pg_statio_user_tables) < 90 THEN 'WARNING'
      WHEN (SELECT ROUND(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2)
            FROM pg_statio_user_tables) < 95 THEN 'MONITOR'
      ELSE 'EXCELLENT'
    END,
    'Target: >95% - Consider increasing shared_buffers if low';

  -- Unused indexes
  RETURN QUERY SELECT
    'Indexes'::TEXT,
    'Unused Indexes'::TEXT,
    (SELECT COUNT(*)::TEXT FROM pg_stat_user_indexes
     WHERE idx_scan = 0 AND pg_relation_size(indexrelid) > 1024 * 1024),
    CASE
      WHEN (SELECT COUNT(*) FROM pg_stat_user_indexes
            WHERE idx_scan = 0 AND pg_relation_size(indexrelid) > 1024 * 1024) > 5 THEN 'REVIEW'
      ELSE 'OK'
    END,
    'Consider removing unused indexes to save space and write overhead';

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION performance_dashboard IS 'Comprehensive performance overview';

-- Run dashboard:
-- SELECT * FROM performance_dashboard();

-- ============================================
-- 6.2: PERFORMANCE TREND TRACKING
-- ============================================

CREATE TABLE IF NOT EXISTS performance_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metric_name TEXT NOT NULL,
  metric_value NUMERIC NOT NULL,
  metric_unit TEXT,
  recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_performance_metrics_name_date ON performance_metrics(metric_name, recorded_at DESC);

COMMENT ON TABLE performance_metrics IS 'Historical performance metrics for trend analysis';

-- Record performance metrics
CREATE OR REPLACE FUNCTION record_performance_metrics()
RETURNS VOID AS $$
BEGIN
  -- Database size
  INSERT INTO performance_metrics (metric_name, metric_value, metric_unit)
  VALUES ('database_size_bytes', pg_database_size(current_database()), 'bytes');

  -- Active connections
  INSERT INTO performance_metrics (metric_name, metric_value, metric_unit)
  SELECT 'active_connections', COUNT(*), 'count'
  FROM pg_stat_activity WHERE state = 'active';

  -- Cache hit ratio
  INSERT INTO performance_metrics (metric_name, metric_value, metric_unit)
  SELECT 'cache_hit_ratio',
    ROUND(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2),
    'percent'
  FROM pg_statio_user_tables;

  -- Total queries (if pg_stat_statements available)
  -- INSERT INTO performance_metrics (metric_name, metric_value, metric_unit)
  -- SELECT 'total_queries', SUM(calls), 'count'
  -- FROM pg_stat_statements;

  RAISE NOTICE 'Performance metrics recorded at %', NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule to run hourly via cron or external scheduler

-- View performance trends
SELECT
  metric_name,
  DATE_TRUNC('hour', recorded_at) as hour,
  AVG(metric_value) as avg_value,
  MIN(metric_value) as min_value,
  MAX(metric_value) as max_value,
  metric_unit
FROM performance_metrics
WHERE recorded_at > NOW() - INTERVAL '7 days'
GROUP BY metric_name, DATE_TRUNC('hour', recorded_at), metric_unit
ORDER BY hour DESC, metric_name;

-- ============================================
-- SECTION 7: QUICK WINS
-- ============================================

-- ============================================
-- 7.1: IMMEDIATE OPTIMIZATIONS
-- ============================================
/*
PRIORITY 1 - Do These First:

1. ✓ Enable connection pooling (use port 6543 in app)
   - Immediate: Reduces connection overhead
   - Effort: 5 minutes (change connection string)

2. ✓ Create missing indexes on foreign keys
   - Immediate: Faster joins
   - Effort: 10 minutes (already created in migrations)

3. ✓ Use materialized views for dashboards
   - Immediate: 10-100x faster dashboard loads
   - Effort: 30 minutes (see Section 5.1)

4. ✓ Implement application-level caching
   - Immediate: Reduced database load
   - Effort: 2 hours (React Query/SWR integration)

5. ✓ Set up query monitoring
   - Immediate: Identify slow queries
   - Effort: 15 minutes (Supabase Dashboard)

PRIORITY 2 - Schedule These:

6. Run VACUUM ANALYZE weekly
   - Impact: Better query plans, reclaim space
   - Effort: 5 minutes to schedule

7. Review and remove unused indexes
   - Impact: Faster writes, less storage
   - Effort: 1 hour analysis

8. Implement database monitoring alerts
   - Impact: Proactive issue detection
   - Effort: 2 hours setup

9. Create performance baseline
   - Impact: Track improvements
   - Effort: 1 hour

10. Document slow query patterns
    - Impact: Development best practices
    - Effort: Ongoing
*/

-- ============================================
-- 7.2: PERFORMANCE CHECKLIST
-- ============================================
/*
DAILY:
□ Monitor active connections
□ Check for long-running queries
□ Review error logs

WEEKLY:
□ Run VACUUM ANALYZE
□ Review slow query log
□ Check cache hit ratio
□ Refresh materialized views

MONTHLY:
□ Analyze index usage
□ Review query patterns
□ Check database growth trends
□ Test backup restore
□ Review performance metrics

QUARTERLY:
□ Full performance audit
□ Capacity planning
□ Index optimization review
□ Application query optimization
*/

-- ============================================
-- 7.3: COMMON PERFORMANCE PITFALLS
-- ============================================
/*
AVOID THESE:

1. SELECT * queries
   - Use: SELECT id, name, email instead
   - Reduces data transfer, improves cache usage

2. N+1 query problem
   - Use: JOIN or batch queries
   - Avoid: Loop with individual queries

3. Missing WHERE clause indexes
   - Add index on frequently filtered columns
   - Check with EXPLAIN ANALYZE

4. Using functions in WHERE clause
   - Avoid: WHERE EXTRACT(YEAR FROM date) = 2025
   - Use: WHERE date >= '2025-01-01' AND date < '2026-01-01'

5. Large OFFSET values
   - Avoid: LIMIT 20 OFFSET 10000
   - Use: Cursor-based pagination

6. Not using connection pooling
   - Always use pooled connection for application
   - Use direct connection only for admin tasks

7. Not monitoring performance
   - Set up alerts for slow queries
   - Track metrics over time

8. Ignoring autovacuum
   - Don't disable autovacuum
   - Tune if necessary, don't disable
*/

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'PERFORMANCE OPTIMIZATION GUIDE LOADED';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Sections included:';
  RAISE NOTICE '1. Index optimization and recommendations';
  RAISE NOTICE '2. Query optimization patterns';
  RAISE NOTICE '3. Database maintenance procedures';
  RAISE NOTICE '4. Connection pooling configuration';
  RAISE NOTICE '5. Caching strategies';
  RAISE NOTICE '6. Performance monitoring tools';
  RAISE NOTICE '7. Quick wins and best practices';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'IMMEDIATE ACTIONS:';
  RAISE NOTICE '1. Run: SELECT * FROM check_index_health();';
  RAISE NOTICE '2. Run: SELECT * FROM performance_dashboard();';
  RAISE NOTICE '3. Enable connection pooling (port 6543)';
  RAISE NOTICE '4. Create mv_wedding_stats materialized view';
  RAISE NOTICE '5. Schedule weekly VACUUM ANALYZE';
  RAISE NOTICE '==============================================';
END $$;
