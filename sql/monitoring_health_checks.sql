-- ============================================
-- EMOWED DATABASE MONITORING & HEALTH CHECKS
-- ============================================
-- Purpose: Monitor database health and performance
-- Usage: Run these queries regularly to check system health
-- Frequency: Daily (automated) or as needed
-- ============================================

-- ============================================
-- QUICK HEALTH CHECK DASHBOARD
-- ============================================
-- Run this for a quick overview of database health

DO $$
DECLARE
  v_total_tables INTEGER;
  v_total_users INTEGER;
  v_total_weddings INTEGER;
  v_total_guests INTEGER;
  v_db_size TEXT;
BEGIN
  -- Count tables
  SELECT COUNT(*) INTO v_total_tables
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

  -- Count users
  SELECT COUNT(*) INTO v_total_users FROM users;

  -- Count weddings
  SELECT COUNT(*) INTO v_total_weddings FROM weddings;

  -- Count guests
  SELECT COUNT(*) INTO v_total_guests FROM guests;

  -- Database size
  SELECT pg_size_pretty(pg_database_size(current_database())) INTO v_db_size;

  RAISE NOTICE '==========================================';
  RAISE NOTICE 'EMOWED DATABASE HEALTH CHECK';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'Database: %', current_database();
  RAISE NOTICE 'Timestamp: %', NOW();
  RAISE NOTICE '';
  RAISE NOTICE 'Tables: %', v_total_tables;
  RAISE NOTICE 'Users: %', v_total_users;
  RAISE NOTICE 'Weddings: %', v_total_weddings;
  RAISE NOTICE 'Guests: %', v_total_guests;
  RAISE NOTICE 'Database Size: %', v_db_size;
  RAISE NOTICE '==========================================';
END $$;

-- ============================================
-- 1. DATABASE SIZE MONITORING
-- ============================================

-- Overall database size
SELECT
  current_database() as database_name,
  pg_size_pretty(pg_database_size(current_database())) as database_size,
  pg_database_size(current_database()) as size_bytes;

-- Table sizes (top 20 largest tables)
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size,
  pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY size_bytes DESC
LIMIT 20;

-- Storage breakdown
SELECT
  'Tables' as object_type,
  COUNT(*) as count,
  pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))) as total_size
FROM pg_tables
WHERE schemaname = 'public'
UNION ALL
SELECT
  'Indexes' as object_type,
  COUNT(*) as count,
  pg_size_pretty(SUM(pg_relation_size(indexrelid))) as total_size
FROM pg_index
JOIN pg_class ON pg_index.indexrelid = pg_class.oid
WHERE pg_class.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY object_type;

-- ============================================
-- 2. RECORD COUNT MONITORING
-- ============================================

-- Record counts for all major tables
SELECT
  'users' as table_name,
  COUNT(*) as record_count,
  pg_size_pretty(pg_total_relation_size('users')) as table_size
FROM users
UNION ALL
SELECT 'couples', COUNT(*), pg_size_pretty(pg_total_relation_size('couples')) FROM couples
UNION ALL
SELECT 'weddings', COUNT(*), pg_size_pretty(pg_total_relation_size('weddings')) FROM weddings
UNION ALL
SELECT 'events', COUNT(*), pg_size_pretty(pg_total_relation_size('events')) FROM events
UNION ALL
SELECT 'guests', COUNT(*), pg_size_pretty(pg_total_relation_size('guests')) FROM guests
UNION ALL
SELECT 'rsvps', COUNT(*), pg_size_pretty(pg_total_relation_size('rsvps')) FROM rsvps
UNION ALL
SELECT 'vendor_profiles', COUNT(*), pg_size_pretty(pg_total_relation_size('vendor_profiles')) FROM vendor_profiles
UNION ALL
SELECT 'vendor_bookings', COUNT(*), pg_size_pretty(pg_total_relation_size('vendor_bookings')) FROM vendor_bookings
UNION ALL
SELECT 'media_items', COUNT(*), pg_size_pretty(pg_total_relation_size('media_items')) FROM media_items
UNION ALL
SELECT 'notifications', COUNT(*), pg_size_pretty(pg_total_relation_size('notifications')) FROM notifications
ORDER BY record_count DESC;

-- Growth rate (compare with previous day)
-- Store this in a monitoring table for trend analysis
CREATE TABLE IF NOT EXISTS monitoring_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  snapshot_date DATE DEFAULT CURRENT_DATE,
  table_name TEXT,
  record_count INTEGER,
  table_size_bytes BIGINT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(snapshot_date, table_name)
);

-- Insert daily snapshot
INSERT INTO monitoring_snapshots (table_name, record_count, table_size_bytes)
SELECT 'users', COUNT(*), pg_total_relation_size('users') FROM users
ON CONFLICT (snapshot_date, table_name) DO UPDATE
SET record_count = EXCLUDED.record_count,
    table_size_bytes = EXCLUDED.table_size_bytes;

-- View growth over time
SELECT
  snapshot_date,
  table_name,
  record_count,
  pg_size_pretty(table_size_bytes) as size,
  record_count - LAG(record_count) OVER (PARTITION BY table_name ORDER BY snapshot_date) as daily_growth
FROM monitoring_snapshots
WHERE table_name IN ('users', 'weddings', 'guests')
ORDER BY table_name, snapshot_date DESC
LIMIT 30;

-- ============================================
-- 3. PERFORMANCE MONITORING
-- ============================================

-- Slow queries (if pg_stat_statements is enabled)
-- Enable with: CREATE EXTENSION pg_stat_statements;
SELECT
  calls,
  mean_exec_time::NUMERIC(10,2) as avg_time_ms,
  max_exec_time::NUMERIC(10,2) as max_time_ms,
  total_exec_time::NUMERIC(10,2) as total_time_ms,
  LEFT(query, 100) as query_preview
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Table statistics (most accessed tables)
SELECT
  schemaname,
  tablename,
  seq_scan as sequential_scans,
  seq_tup_read as rows_read_sequentially,
  idx_scan as index_scans,
  idx_tup_fetch as rows_fetched_by_index,
  n_tup_ins as inserts,
  n_tup_upd as updates,
  n_tup_del as deletes,
  n_live_tup as live_rows,
  n_dead_tup as dead_rows,
  last_vacuum,
  last_autovacuum,
  last_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY seq_scan + idx_scan DESC
LIMIT 20;

-- Index usage statistics
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched,
  pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;

-- Unused indexes (candidates for removal)
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan as times_used,
  pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
  pg_relation_size(indexrelid) as size_bytes
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND idx_scan = 0
AND indexrelid NOT IN (
  SELECT indexrelid FROM pg_index WHERE indisprimary OR indisunique
)
ORDER BY size_bytes DESC;

-- ============================================
-- 4. CONNECTION MONITORING
-- ============================================

-- Current connections
SELECT
  COUNT(*) as total_connections,
  COUNT(*) FILTER (WHERE state = 'active') as active,
  COUNT(*) FILTER (WHERE state = 'idle') as idle,
  COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity
WHERE datname = current_database();

-- Connections by user/application
SELECT
  usename,
  application_name,
  COUNT(*) as connections,
  COUNT(*) FILTER (WHERE state = 'active') as active
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY usename, application_name
ORDER BY connections DESC;

-- Long-running queries
SELECT
  pid,
  now() - query_start as duration,
  state,
  LEFT(query, 100) as query_preview
FROM pg_stat_activity
WHERE state != 'idle'
AND query NOT LIKE '%pg_stat_activity%'
AND (now() - query_start) > interval '1 minute'
ORDER BY duration DESC;

-- ============================================
-- 5. DATA INTEGRITY CHECKS
-- ============================================

-- Check for orphaned records (guests without weddings)
SELECT COUNT(*) as orphaned_guests
FROM guests g
WHERE NOT EXISTS (SELECT 1 FROM weddings w WHERE w.id = g.wedding_id);

-- Check for invalid foreign keys
SELECT COUNT(*) as invalid_rsvps
FROM rsvps r
WHERE NOT EXISTS (SELECT 1 FROM guests g WHERE g.id = r.guest_id);

-- Check for expired invitations not marked as expired
SELECT COUNT(*) as expired_but_pending
FROM partner_invitations
WHERE status = 'pending'
AND expires_at < NOW();

-- Check for couples with missing users
SELECT COUNT(*) as invalid_couples
FROM couples c
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = c.user1_id)
   OR NOT EXISTS (SELECT 1 FROM users WHERE id = c.user2_id);

-- Check for future dates in past (data consistency)
SELECT COUNT(*) as past_future_weddings
FROM weddings
WHERE date < CURRENT_DATE
AND status = 'planning';

-- ============================================
-- 6. BUSINESS METRICS MONITORING
-- ============================================

-- User growth metrics
SELECT
  DATE_TRUNC('day', created_at) as date,
  COUNT(*) as new_users,
  relationship_status,
  SUM(COUNT(*)) OVER (PARTITION BY relationship_status ORDER BY DATE_TRUNC('day', created_at)) as cumulative_users
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at), relationship_status
ORDER BY date DESC, relationship_status;

-- Wedding statistics
SELECT
  status,
  COUNT(*) as count,
  ROUND(AVG(guest_limit), 0) as avg_guest_limit,
  ROUND(AVG(budget_limit), 0) as avg_budget,
  MIN(date) as earliest_wedding,
  MAX(date) as latest_wedding
FROM weddings
GROUP BY status;

-- RSVP completion rate
SELECT
  w.name as wedding_name,
  COUNT(DISTINCT g.id) as total_guests,
  COUNT(DISTINCT r.id) as responded_guests,
  ROUND(100.0 * COUNT(DISTINCT r.id) / NULLIF(COUNT(DISTINCT g.id), 0), 2) as completion_percentage
FROM weddings w
LEFT JOIN guests g ON w.id = g.wedding_id
LEFT JOIN rsvps r ON g.id = r.guest_id
GROUP BY w.id, w.name
ORDER BY completion_percentage DESC
LIMIT 10;

-- Vendor booking metrics
SELECT
  vp.category,
  COUNT(DISTINCT vb.id) as total_bookings,
  COUNT(DISTINCT vb.wedding_id) as unique_weddings,
  ROUND(AVG(vb.final_price), 2) as avg_price,
  SUM(vb.final_price) as total_revenue
FROM vendor_profiles vp
JOIN vendor_bookings vb ON vp.id = vb.vendor_id
WHERE vb.booking_status = 'confirmed'
GROUP BY vp.category
ORDER BY total_revenue DESC;

-- Gift statistics
SELECT
  gift_type,
  COUNT(*) as total_gifts,
  SUM(gift_amount) as total_value,
  AVG(gift_amount) as avg_value,
  SUM(commission_amount) as total_commission
FROM guest_gifts
WHERE payment_status = 'completed'
GROUP BY gift_type
ORDER BY total_value DESC;

-- ============================================
-- 7. SECURITY MONITORING
-- ============================================

-- RLS policy coverage
SELECT
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY policy_count;

-- Tables without RLS enabled
SELECT
  schemaname,
  tablename
FROM pg_tables
WHERE schemaname = 'public'
AND tablename NOT IN (
  SELECT tablename FROM pg_policies WHERE schemaname = 'public'
)
ORDER BY tablename;

-- Failed authentication attempts (if logged)
-- This would require custom logging table

-- ============================================
-- 8. STORAGE QUOTA MONITORING
-- ============================================

-- Check against Supabase Free Tier limits
-- Free tier: 500 MB database, 1 GB storage

SELECT
  'Database Size' as metric,
  pg_size_pretty(pg_database_size(current_database())) as current_size,
  '500 MB' as free_tier_limit,
  CASE
    WHEN pg_database_size(current_database()) > 500 * 1024 * 1024 THEN 'OVER LIMIT'
    WHEN pg_database_size(current_database()) > 400 * 1024 * 1024 THEN 'WARNING'
    ELSE 'OK'
  END as status;

-- Table growth trend (last 7 days)
SELECT
  table_name,
  MIN(record_count) as min_records,
  MAX(record_count) as max_records,
  MAX(record_count) - MIN(record_count) as growth,
  ROUND((MAX(record_count)::NUMERIC - MIN(record_count)) / NULLIF(MIN(record_count), 0) * 100, 2) as growth_percentage
FROM monitoring_snapshots
WHERE snapshot_date >= CURRENT_DATE - 7
GROUP BY table_name
ORDER BY growth DESC;

-- ============================================
-- 9. CLEANUP RECOMMENDATIONS
-- ============================================

-- Old notifications (candidates for archival)
SELECT COUNT(*) as old_notifications,
       SUM(pg_column_size(notifications.*)) as estimated_space
FROM notifications
WHERE created_at < NOW() - INTERVAL '90 days'
AND read = true;

-- Expired invitations (can be deleted)
SELECT COUNT(*) as expired_invitations
FROM partner_invitations
WHERE status = 'pending'
AND expires_at < NOW();

-- Old monitoring snapshots (can be aggregated)
SELECT COUNT(*) as old_snapshots
FROM monitoring_snapshots
WHERE snapshot_date < CURRENT_DATE - 30;

-- ============================================
-- 10. AUTOMATED HEALTH CHECK FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION run_health_check()
RETURNS TABLE (
  check_name TEXT,
  status TEXT,
  details TEXT
) AS $$
BEGIN
  -- Check 1: Database size
  RETURN QUERY
  SELECT
    'Database Size'::TEXT,
    CASE
      WHEN pg_database_size(current_database()) > 500 * 1024 * 1024 THEN 'CRITICAL'
      WHEN pg_database_size(current_database()) > 400 * 1024 * 1024 THEN 'WARNING'
      ELSE 'OK'
    END,
    pg_size_pretty(pg_database_size(current_database()))::TEXT;

  -- Check 2: Table count
  RETURN QUERY
  SELECT
    'Total Tables'::TEXT,
    CASE
      WHEN COUNT(*) < 60 THEN 'WARNING'
      WHEN COUNT(*) > 70 THEN 'INFO'
      ELSE 'OK'
    END,
    COUNT(*)::TEXT
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

  -- Check 3: Active connections
  RETURN QUERY
  SELECT
    'Active Connections'::TEXT,
    CASE
      WHEN COUNT(*) > 50 THEN 'WARNING'
      WHEN COUNT(*) > 80 THEN 'CRITICAL'
      ELSE 'OK'
    END,
    COUNT(*)::TEXT
  FROM pg_stat_activity
  WHERE state = 'active';

  -- Check 4: Dead tuples
  RETURN QUERY
  SELECT
    'Dead Tuples'::TEXT,
    CASE
      WHEN SUM(n_dead_tup) > 10000 THEN 'WARNING'
      WHEN SUM(n_dead_tup) > 50000 THEN 'CRITICAL'
      ELSE 'OK'
    END,
    SUM(n_dead_tup)::TEXT
  FROM pg_stat_user_tables;

  -- Check 5: RLS enabled
  RETURN QUERY
  SELECT
    'RLS Coverage'::TEXT,
    CASE
      WHEN COUNT(*) < 60 THEN 'CRITICAL'
      ELSE 'OK'
    END,
    COUNT(*)::TEXT || ' tables with RLS'
  FROM pg_tables
  WHERE schemaname = 'public'
  AND rowsecurity = true;

END;
$$ LANGUAGE plpgsql;

-- Run health check
SELECT * FROM run_health_check();

-- ============================================
-- USAGE INSTRUCTIONS
-- ============================================
/*
DAILY MONITORING:
1. Run quick health check dashboard
2. Check database size
3. Review growth metrics
4. Check for slow queries

WEEKLY MONITORING:
1. Review table sizes
2. Check index usage
3. Review connection patterns
4. Run cleanup recommendations

MONTHLY MONITORING:
1. Analyze growth trends
2. Review unused indexes
3. Archive old data
4. Optimize slow queries

AUTOMATED MONITORING:
- Set up cron job to run health check daily
- Store results in monitoring table
- Alert on WARNING/CRITICAL status
- Generate weekly reports
*/

-- ============================================
-- ALERT SETUP (Example)
-- ============================================

CREATE TABLE IF NOT EXISTS monitoring_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alert_type TEXT,
  severity TEXT CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
  message TEXT,
  details JSONB,
  resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Function to create alert
CREATE OR REPLACE FUNCTION create_alert(
  p_type TEXT,
  p_severity TEXT,
  p_message TEXT,
  p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_alert_id UUID;
BEGIN
  INSERT INTO monitoring_alerts (alert_type, severity, message, details)
  VALUES (p_type, p_severity, p_message, p_details)
  RETURNING id INTO v_alert_id;

  RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'MONITORING & HEALTH CHECK QUERIES READY';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'Use these queries to monitor database health';
  RAISE NOTICE 'Run regularly for optimal performance';
  RAISE NOTICE 'Set up automated alerts for critical issues';
  RAISE NOTICE '==========================================';
END $$;
