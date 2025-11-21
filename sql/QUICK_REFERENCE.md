# Emowed Database Quick Reference Guide

**Quick access to common database operations, queries, and utilities**

---

## 📋 Table of Contents

1. [Connection Strings](#connection-strings)
2. [Common Queries](#common-queries)
3. [Frequently Used Functions](#frequently-used-functions)
4. [Daily Operations](#daily-operations)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)
7. [Emergency Procedures](#emergency-procedures)

---

## 🔌 Connection Strings

### Supabase Connections

```bash
# PRODUCTION (Pooled) - Use in Application
postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:6543/postgres

# PRODUCTION (Direct) - Use for Admin/Migrations
postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres

# Development (Local)
postgresql://postgres:postgres@localhost:54322/postgres
```

### Connection via psql

```bash
# Connect to production (replace placeholders)
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

# Connect to local development
psql -h localhost -p 54322 -U postgres -d postgres
```

---

## 🔍 Common Queries

### User Queries

```sql
-- Find user by email
SELECT * FROM users WHERE email = 'user@example.com';

-- Get user with couple and wedding info
SELECT
  u.id, u.email, u.full_name,
  c.id as couple_id,
  w.id as wedding_id, w.name as wedding_name
FROM users u
LEFT JOIN couples c ON u.id IN (c.user1_id, c.user2_id)
LEFT JOIN weddings w ON c.id = w.couple_id
WHERE u.email = 'user@example.com';

-- Find inactive users (90+ days)
SELECT * FROM find_inactive_users(90);

-- Count users by relationship status
SELECT relationship_status, COUNT(*)
FROM users
GROUP BY relationship_status;
```

### Wedding Queries

```sql
-- Get wedding with full details
SELECT * FROM vw_wedding_details WHERE wedding_id = 'your-uuid-here';

-- Get wedding guest statistics
SELECT * FROM vw_wedding_guest_stats WHERE wedding_id = 'your-uuid-here';

-- Find upcoming weddings (next 30 days)
SELECT id, name, date, venue, city
FROM weddings
WHERE date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY date;

-- Get RSVP status for a wedding
SELECT
  COUNT(*) FILTER (WHERE r.attendance_status = 'attending') as attending,
  COUNT(*) FILTER (WHERE r.attendance_status = 'declined') as declined,
  COUNT(*) FILTER (WHERE r.attendance_status IS NULL) as pending
FROM guests g
LEFT JOIN rsvps r ON g.id = r.guest_id
WHERE g.wedding_id = 'your-uuid-here';
```

### Guest Management

```sql
-- Search guests by name
SELECT * FROM search_guests('wedding-uuid', 'john');

-- Get guest list with RSVP status
SELECT * FROM vw_guest_list_with_rsvp WHERE wedding_id = 'your-uuid-here';

-- Calculate total headcount
SELECT calculate_total_headcount('wedding-uuid');

-- Get RSVP completion rate
SELECT get_rsvp_completion_rate('wedding-uuid');
```

### Vendor Queries

```sql
-- Get vendor summary
SELECT * FROM vw_vendor_summary WHERE is_active = true;

-- Search vendors by category and city
SELECT * FROM vendor_profiles
WHERE category = 'photographer'
AND city = 'Mumbai'
AND is_active = true
ORDER BY rating DESC;

-- Get recommended vendors for a wedding
SELECT * FROM get_recommended_vendors('wedding-uuid', 'photographer', 5);

-- Vendor booking details
SELECT * FROM vw_vendor_bookings_detail WHERE wedding_id = 'your-uuid-here';
```

### Matchmaking Queries

```sql
-- Get active matchmaking profiles
SELECT * FROM vw_matchmaking_profiles_active
WHERE city = 'Mumbai'
AND gender = 'male';

-- Get matches for a user
SELECT * FROM vw_matches_with_profiles
WHERE user_id = 'your-uuid-here'
AND match_status = 'matched';

-- Calculate match probability
SELECT * FROM calculate_match_probability('user-uuid', true);
```

---

## ⚙️ Frequently Used Functions

### Utility Functions

```sql
-- Generate random code (6 characters)
SELECT generate_random_code(6);

-- Slugify text (URL-friendly)
SELECT slugify('My Wedding 2025!');
-- Returns: my-wedding-2025

-- Calculate age from date of birth
SELECT calculate_age('1995-05-15');

-- Days until a future date
SELECT days_until('2025-12-25');

-- Check if date is in future
SELECT is_future_date('2025-12-25');
```

### Validation Functions

```sql
-- Check if user can create wedding
SELECT can_create_wedding('user-uuid');

-- Check if user can invite partner
SELECT can_invite_partner('user-uuid');

-- Check if in cooldown period
SELECT is_in_cooldown('user-uuid', 'invitation');
```

### Statistics Functions

```sql
-- Get user statistics
SELECT * FROM get_user_stats('user-uuid');

-- Get wedding progress percentage
SELECT get_wedding_progress('wedding-uuid');

-- Get wedding budget summary
SELECT * FROM get_wedding_budget_summary('wedding-uuid');
```

### Notification Functions

```sql
-- Create notification for user
SELECT create_notification(
  'user-uuid',
  'invitation',
  'New Partner Request',
  'You have received a partner invitation',
  '/invitations'
);

-- Mark all notifications as read
SELECT mark_all_notifications_read('user-uuid');
```

---

## 📅 Daily Operations

### Morning Routine

```sql
-- 1. Check database health
SELECT * FROM run_health_check();

-- 2. Check active connections
SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';

-- 3. Check for errors (last 24 hours)
-- (Check application logs)

-- 4. Update wedding statuses
SELECT * FROM update_wedding_statuses();
```

### Weekly Maintenance

```sql
-- 1. Clean up expired items
SELECT * FROM cleanup_expired_items();

-- 2. Check for orphaned records (dry run first)
SELECT * FROM cleanup_orphaned_records(true);

-- 3. Run VACUUM ANALYZE
SELECT * FROM run_maintenance(true, true, false);

-- 4. Check index health
SELECT * FROM check_index_health();

-- 5. Review performance dashboard
SELECT * FROM performance_dashboard();
```

### Monthly Tasks

```sql
-- 1. Generate user activity report
SELECT * FROM user_activity_report(30);

-- 2. Generate wedding report
SELECT * FROM generate_wedding_report(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE
);

-- 3. Vendor performance report
SELECT * FROM vendor_performance_report();

-- 4. Archive old weddings (1+ year old)
SELECT * FROM archive_old_weddings(
  CURRENT_DATE - INTERVAL '1 year',
  true  -- dry run first
);

-- 5. Fix data inconsistencies
SELECT * FROM fix_data_inconsistencies();
```

---

## 🔧 Troubleshooting

### Performance Issues

```sql
-- Check slow queries
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check table bloat (needs vacuum)
SELECT
  schemaname, tablename,
  n_dead_tup,
  n_live_tup,
  ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- Check cache hit ratio (should be >95%)
SELECT
  ROUND(100.0 * sum(heap_blks_hit) /
    NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Find missing indexes
SELECT * FROM pg_stat_user_tables
WHERE seq_scan > 1000 AND idx_scan < seq_scan / 10
ORDER BY seq_scan DESC;
```

### Connection Issues

```sql
-- Check current connections
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE state = 'active') as active,
  COUNT(*) FILTER (WHERE state = 'idle') as idle
FROM pg_stat_activity;

-- Find long-running queries
SELECT
  pid,
  NOW() - query_start AS duration,
  state,
  query
FROM pg_stat_activity
WHERE state != 'idle'
AND NOW() - query_start > INTERVAL '5 minutes';

-- Kill a stuck query (use with caution!)
-- SELECT pg_terminate_backend(pid);
```

### Data Issues

```sql
-- Find orphaned records
SELECT * FROM cleanup_orphaned_records(true);

-- Check for data inconsistencies
SELECT * FROM fix_data_inconsistencies();

-- Verify foreign key constraints
SELECT
  'couples with missing users' as issue,
  COUNT(*)
FROM couples c
LEFT JOIN users u1 ON c.user1_id = u1.id
WHERE u1.id IS NULL;
```

### Application Errors

```sql
-- Check recent failed invitations
SELECT * FROM partner_invitations
WHERE status = 'failed'
ORDER BY created_at DESC
LIMIT 10;

-- Check failed vendor bookings
SELECT * FROM vendor_bookings
WHERE booking_status = 'cancelled'
ORDER BY created_at DESC
LIMIT 10;

-- Check notification delivery
SELECT type, COUNT(*),
  COUNT(*) FILTER (WHERE read = true) as read_count
FROM notifications
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY type;
```

---

## ✅ Best Practices

### Query Optimization

```sql
-- ❌ BAD: SELECT *
SELECT * FROM users;

-- ✅ GOOD: Select only needed columns
SELECT id, email, full_name FROM users;

-- ❌ BAD: Function in WHERE clause
SELECT * FROM events WHERE EXTRACT(YEAR FROM date) = 2025;

-- ✅ GOOD: Use range for indexable query
SELECT * FROM events
WHERE date >= '2025-01-01' AND date < '2026-01-01';

-- ❌ BAD: N+1 queries in application
FOR EACH wedding:
  SELECT COUNT(*) FROM guests WHERE wedding_id = wedding.id

-- ✅ GOOD: Single query with JOIN
SELECT w.id, w.name, COUNT(g.id) as guest_count
FROM weddings w
LEFT JOIN guests g ON w.id = g.wedding_id
GROUP BY w.id, w.name;
```

### Connection Management

```bash
# ✅ GOOD: Use pooled connection in application
DATABASE_URL=postgresql://postgres:pass@db.ref.supabase.co:6543/postgres

# ❌ BAD: Use direct connection in application (exhausts connections)
DATABASE_URL=postgresql://postgres:pass@db.ref.supabase.co:5432/postgres

# ✅ GOOD: Use direct connection for migrations/admin
psql "postgresql://postgres:pass@db.ref.supabase.co:5432/postgres"
```

### Data Operations

```sql
-- ✅ ALWAYS use transactions for multiple operations
BEGIN;
  UPDATE users SET relationship_status = 'engaged' WHERE id = 'uuid1';
  INSERT INTO couples (user1_id, user2_id) VALUES ('uuid1', 'uuid2');
  UPDATE users SET relationship_status = 'engaged' WHERE id = 'uuid2';
COMMIT;

-- ✅ ALWAYS test destructive operations with dry_run
SELECT * FROM cleanup_orphaned_records(true);  -- dry run
-- Verify results, then:
SELECT * FROM cleanup_orphaned_records(false); -- execute

-- ✅ ALWAYS backup before major changes
-- Dashboard → Database → Backups → Create Backup
```

### Security

```sql
-- ✅ ALWAYS use parameterized queries (in application)
-- DON'T: "SELECT * FROM users WHERE email = '" + userInput + "'"
-- DO: Use prepared statements with $1, $2 parameters

-- ✅ ALWAYS respect RLS policies
-- Queries run through Supabase client automatically enforce RLS
-- Direct psql queries bypass RLS (admin only)

-- ✅ NEVER log sensitive data
-- Avoid logging: passwords, tokens, personal info
```

---

## 🚨 Emergency Procedures

### Database Down

```bash
# 1. Check Supabase status
# https://status.supabase.com

# 2. Check connection
psql "postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres" -c "SELECT 1;"

# 3. Contact Supabase support
# Dashboard → Support
```

### Accidental Data Deletion

```sql
-- 1. STOP - Don't make more changes!

-- 2. Check if PITR available (Pro tier)
-- Dashboard → Database → Backups → Point in Time Recovery

-- 3. Or restore from latest backup
-- Dashboard → Database → Backups → Restore

-- 4. For specific records, check backup_logs
SELECT * FROM backup_logs ORDER BY created_at DESC LIMIT 5;
```

### Performance Degradation

```sql
-- 1. Check active connections
SELECT COUNT(*) FROM pg_stat_activity;

-- 2. Check for long-running queries
SELECT pid, NOW() - query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- 3. Kill problematic queries if necessary
-- SELECT pg_terminate_backend(pid);

-- 4. Run VACUUM if high dead tuples
SELECT schemaname, tablename, n_dead_tup
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- VACUUM ANALYZE tablename;
```

### Spam Attack

```sql
-- 1. Identify spam pattern
SELECT email FROM users
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- 2. Ban spam users (dry run first)
SELECT * FROM ban_spam_users('spampattern', 'Spam attack', true);

-- 3. Execute ban
-- SELECT * FROM ban_spam_users('spampattern', 'Spam attack', false);

-- 4. Create emergency snapshot
SELECT create_emergency_snapshot();
```

---

## 📚 Quick Command Reference

### Database Info

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Table sizes
SELECT
  schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Row counts
SELECT
  schemaname, tablename,
  n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;
```

### Index Management

```sql
-- List all indexes
SELECT
  schemaname, tablename, indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find unused indexes
SELECT * FROM check_index_health()
WHERE health_status = 'POOR';
```

### Views

```sql
-- List all materialized views
SELECT
  schemaname, matviewname,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) AS size
FROM pg_matviews
WHERE schemaname = 'public';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_wedding_stats;
```

---

## 🎯 Pro Tips

1. **Always use connection pooling** (port 6543) in your application
2. **Test queries with EXPLAIN ANALYZE** before deploying
3. **Use views** for complex queries instead of repeating logic
4. **Set up monitoring** - don't wait for users to report issues
5. **Backup before migrations** - always have a rollback plan
6. **Use indexes wisely** - too many indexes slow down writes
7. **Monitor cache hit ratio** - should be >95%
8. **Clean up regularly** - run cleanup functions weekly
9. **Document custom queries** - future you will thank you
10. **Test in development first** - never experiment in production

---

## 📖 Additional Resources

- **Full Documentation**: See `sql/README.md`
- **Deployment Guide**: See `howtobackend.txt`
- **Migration Scripts**: See `sql/phase*.sql`
- **Monitoring**: See `sql/monitoring_health_checks.sql`
- **Performance**: See `sql/performance_optimization.sql`
- **Backup/Restore**: See `sql/backup_restore_procedures.sql`
- **Admin Tools**: See `sql/admin_utilities.sql`

---

## 🆘 Getting Help

1. **Check this guide first** - most common operations are covered
2. **Review error logs** - Supabase Dashboard → Logs
3. **Check Supabase docs** - https://supabase.com/docs
4. **Check PostgreSQL docs** - https://www.postgresql.org/docs/
5. **Team chat** - Ask in team channel
6. **Supabase support** - Dashboard → Support (for infrastructure issues)

---

**Last Updated**: January 2025
**Maintained By**: Emowed Development Team

---

## Quick Cheat Sheet

```bash
# Connect to database
psql "postgresql://postgres:PASSWORD@db.REF.supabase.co:5432/postgres"

# Common tasks
\dt                          # List tables
\d tablename                 # Describe table
\df                          # List functions
\dv                          # List views
\l                           # List databases
\q                           # Quit

# SQL shortcuts
SELECT * FROM users LIMIT 10;
SELECT * FROM weddings WHERE date > CURRENT_DATE;
SELECT * FROM run_health_check();
SELECT * FROM performance_dashboard();
```

**Remember**: When in doubt, use `dry_run=true` first! 🛡️
