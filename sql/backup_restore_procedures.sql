-- ============================================
-- EMOWED DATABASE BACKUP & RESTORE PROCEDURES
-- ============================================
-- Purpose: Comprehensive backup and restore strategies
-- Covers: Full backups, incremental, table-specific, PITR
-- Platform: Supabase + PostgreSQL
-- ============================================

-- ============================================
-- TABLE OF CONTENTS
-- ============================================
/*
1. BACKUP STRATEGIES
   - Full database backups
   - Table-specific backups
   - Incremental backups
   - Schema-only backups

2. RESTORE PROCEDURES
   - Full database restore
   - Table-specific restore
   - Point-in-time recovery (PITR)
   - Selective data restore

3. SUPABASE-SPECIFIC PROCEDURES
   - Dashboard backups
   - CLI backups
   - Storage bucket backups

4. AUTOMATED BACKUP FUNCTIONS
   - Scheduled backup scripts
   - Backup verification
   - Backup cleanup

5. DISASTER RECOVERY
   - Recovery plan
   - Failover procedures
   - Data validation after restore

6. BEST PRACTICES
   - Backup frequency
   - Retention policies
   - Security considerations
*/

-- ============================================
-- SECTION 1: FULL DATABASE BACKUP
-- ============================================

-- ============================================
-- 1.1: SUPABASE DASHBOARD BACKUP (RECOMMENDED)
-- ============================================
/*
EASIEST METHOD - Use Supabase Dashboard:

1. Go to Supabase Dashboard
   https://app.supabase.com/project/YOUR_PROJECT_ID

2. Navigate to Database → Backups
   - Daily automatic backups (free tier)
   - Hourly backups (Pro tier)

3. Manual Backup:
   - Click "Create Backup" button
   - Enter backup name (e.g., "pre-deployment-2025-01-15")
   - Wait for completion (~2-10 minutes)

4. Download Backup:
   - Click "..." menu on backup
   - Select "Download"
   - Save as .sql file

IMPORTANT:
- Free tier: 7 daily backups retained
- Pro tier: 30 daily backups + hourly for 7 days
- Backups include: schema + data + RLS policies
- Excludes: storage bucket files (backup separately)
*/

-- ============================================
-- 1.2: COMMAND LINE BACKUP (USING pg_dump)
-- ============================================
/*
ADVANCED METHOD - Direct PostgreSQL backup:

PREREQUISITES:
1. Install PostgreSQL tools (pg_dump included)
2. Get connection string from Supabase:
   Settings → Database → Connection String → URI

BACKUP COMMAND:
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --format=custom \
  --file=emowed_backup_$(date +%Y%m%d_%H%M%S).dump \
  --verbose \
  --no-owner \
  --no-acl

EXPLANATION:
- --format=custom: Compressed binary format (smaller, faster)
- --file: Output filename with timestamp
- --verbose: Show progress
- --no-owner: Don't include ownership commands
- --no-acl: Don't include access privileges

ALTERNATIVE - SQL FORMAT:
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --format=plain \
  --file=emowed_backup_$(date +%Y%m%d_%H%M%S).sql \
  --verbose

SQL format is human-readable but larger file size.
*/

-- ============================================
-- 1.3: SCHEMA-ONLY BACKUP
-- ============================================
/*
Backup structure without data (useful for migrations):

pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --schema-only \
  --format=plain \
  --file=emowed_schema_only.sql \
  --verbose

USE CASES:
- Create new environment with same structure
- Version control for schema
- Compare schema differences
*/

-- ============================================
-- 1.4: DATA-ONLY BACKUP
-- ============================================
/*
Backup data without structure:

pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --data-only \
  --format=custom \
  --file=emowed_data_only.dump \
  --verbose

USE CASES:
- Migrate data to existing schema
- Refresh test data
- Export for analytics
*/

-- ============================================
-- SECTION 2: TABLE-SPECIFIC BACKUPS
-- ============================================

-- ============================================
-- 2.1: BACKUP SINGLE TABLE
-- ============================================
/*
Backup specific table with data:

pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --table=users \
  --format=custom \
  --file=users_backup.dump

Backup multiple specific tables:

pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --table=users \
  --table=couples \
  --table=weddings \
  --format=custom \
  --file=core_tables_backup.dump
*/

-- ============================================
-- 2.2: EXPORT TABLE TO CSV
-- ============================================
/*
Export table data to CSV (for Excel, analytics):

COPY users TO '/tmp/users_export.csv' DELIMITER ',' CSV HEADER;
COPY weddings TO '/tmp/weddings_export.csv' DELIMITER ',' CSV HEADER;

Or using psql:
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  -c "\COPY users TO 'users_export.csv' WITH (FORMAT CSV, HEADER)"

USE CASES:
- Share data with non-technical stakeholders
- Import to Excel/Google Sheets
- Data analysis
*/

-- ============================================
-- 2.3: BACKUP CRITICAL TABLES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION backup_critical_tables()
RETURNS TABLE (
  table_name TEXT,
  record_count BIGINT,
  backup_status TEXT
) AS $$
DECLARE
  v_critical_tables TEXT[] := ARRAY[
    'users', 'couples', 'weddings', 'guests',
    'rsvps', 'vendor_bookings', 'matchmaking_profiles'
  ];
  v_table TEXT;
  v_count BIGINT;
BEGIN
  FOREACH v_table IN ARRAY v_critical_tables LOOP
    EXECUTE format('SELECT COUNT(*) FROM %I', v_table) INTO v_count;

    RETURN QUERY SELECT
      v_table,
      v_count,
      CASE
        WHEN v_count = 0 THEN 'EMPTY - No backup needed'
        WHEN v_count < 1000 THEN 'OK - Small table'
        WHEN v_count < 10000 THEN 'OK - Medium table'
        ELSE 'LARGE - Schedule separate backup'
      END;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION backup_critical_tables IS 'Identify critical tables and recommend backup strategy';

-- Run to see critical table status:
-- SELECT * FROM backup_critical_tables();

-- ============================================
-- SECTION 3: RESTORE PROCEDURES
-- ============================================

-- ============================================
-- 3.1: RESTORE FULL DATABASE (SUPABASE DASHBOARD)
-- ============================================
/*
EASIEST METHOD:

1. Go to Database → Backups
2. Find backup to restore
3. Click "..." menu
4. Select "Restore"
5. Confirm (WARNING: This will overwrite current data!)
6. Wait for completion (~5-20 minutes)

IMPORTANT:
- All current data will be replaced
- Application will be unavailable during restore
- Inform users before restore
- Test in staging environment first
*/

-- ============================================
-- 3.2: RESTORE FROM pg_dump FILE
-- ============================================
/*
RESTORE CUSTOM FORMAT (.dump file):

pg_restore \
  --dbname="postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl \
  --verbose \
  emowed_backup_20250115.dump

EXPLANATION:
- --clean: Drop existing objects before restore
- --if-exists: Don't error if object doesn't exist
- --no-owner: Skip ownership restoration
- --verbose: Show progress

RESTORE SQL FORMAT (.sql file):

psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  < emowed_backup_20250115.sql

ALTERNATIVE - Via Supabase SQL Editor:
1. Open backup .sql file
2. Copy contents
3. Paste in SQL Editor
4. Run (WARNING: May timeout on large files)
*/

-- ============================================
-- 3.3: RESTORE SINGLE TABLE
-- ============================================
/*
Restore specific table from backup:

pg_restore \
  --dbname="postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --table=users \
  --clean \
  --if-exists \
  --no-owner \
  --verbose \
  emowed_backup.dump

IMPORTANT:
- This will replace the table completely
- Foreign key constraints must be considered
- May need to restore dependent tables too
*/

-- ============================================
-- 3.4: RESTORE FROM CSV
-- ============================================
/*
Import CSV data into existing table:

COPY users FROM '/tmp/users_export.csv' DELIMITER ',' CSV HEADER;

Or using psql:
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  -c "\COPY users FROM 'users_export.csv' WITH (FORMAT CSV, HEADER)"

PREREQUISITES:
- Table must already exist
- CSV columns must match table structure
- May need to disable triggers temporarily
*/

-- ============================================
-- SECTION 4: STORAGE BUCKET BACKUP
-- ============================================

-- ============================================
-- 4.1: BACKUP STORAGE BUCKETS
-- ============================================
/*
Supabase Storage (images, documents, media) must be backed up separately!

METHOD 1 - Supabase CLI:

# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to project
supabase link --project-ref YOUR_PROJECT_REF

# Backup storage
supabase storage download --recursive wedding-photos ./backup/wedding-photos
supabase storage download --recursive guest-uploads ./backup/guest-uploads
supabase storage download --recursive vendor-portfolios ./backup/vendor-portfolios

METHOD 2 - Manual Download:
1. Dashboard → Storage
2. Select bucket
3. Download individual files (small projects)
4. Use Supabase API for bulk download (large projects)

METHOD 3 - Automated Backup Script:
(See Section 5 for automated scripts)
*/

-- ============================================
-- SECTION 5: AUTOMATED BACKUP SCRIPTS
-- ============================================

-- ============================================
-- 5.1: CREATE BACKUP TRACKING TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS backup_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  backup_type TEXT NOT NULL CHECK (backup_type IN ('full', 'incremental', 'table', 'storage')),
  backup_name TEXT NOT NULL,
  backup_size BIGINT,
  record_count BIGINT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  error_message TEXT,
  created_by UUID REFERENCES users(id),
  notes TEXT
);

CREATE INDEX idx_backup_logs_status ON backup_logs(status);
CREATE INDEX idx_backup_logs_created_at ON backup_logs(created_at DESC);

COMMENT ON TABLE backup_logs IS 'Track backup operations and status';

-- ============================================
-- 5.2: LOG BACKUP OPERATION
-- ============================================

CREATE OR REPLACE FUNCTION log_backup_operation(
  p_backup_type TEXT,
  p_backup_name TEXT,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_backup_id UUID;
BEGIN
  INSERT INTO backup_logs (backup_type, backup_name, status, notes)
  VALUES (p_backup_type, p_backup_name, 'in_progress', p_notes)
  RETURNING id INTO v_backup_id;

  RETURN v_backup_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.3: COMPLETE BACKUP LOG
-- ============================================

CREATE OR REPLACE FUNCTION complete_backup_log(
  p_backup_id UUID,
  p_status TEXT,
  p_record_count BIGINT DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  UPDATE backup_logs
  SET
    status = p_status,
    record_count = p_record_count,
    completed_at = NOW(),
    error_message = p_error_message
  WHERE id = p_backup_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5.4: GET BACKUP HISTORY
-- ============================================

CREATE OR REPLACE FUNCTION get_backup_history(p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
  backup_name TEXT,
  backup_type TEXT,
  status TEXT,
  record_count BIGINT,
  duration INTERVAL,
  created_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    bl.backup_name,
    bl.backup_type,
    bl.status,
    bl.record_count,
    bl.completed_at - bl.started_at as duration,
    bl.started_at
  FROM backup_logs bl
  ORDER BY bl.started_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- View recent backups:
-- SELECT * FROM get_backup_history(10);

-- ============================================
-- SECTION 6: POINT-IN-TIME RECOVERY (PITR)
-- ============================================

-- ============================================
-- 6.1: SUPABASE PITR (PRO TIER ONLY)
-- ============================================
/*
Point-in-Time Recovery allows restore to ANY point in the last 7 days.

AVAILABLE ON:
- Pro tier and above
- Team tier and above

HOW TO USE:
1. Dashboard → Database → Backups
2. Click "Point in Time Recovery"
3. Select date and time
4. Preview restore point
5. Confirm restore

USE CASES:
- Recover from accidental deletion
- Undo bad migration
- Investigate data at specific time
- Compliance/audit requirements

IMPORTANT:
- Only available on paid tiers
- 7-day retention window
- Full database restore only (not table-specific)
*/

-- ============================================
-- 6.2: MANUAL PITR ALTERNATIVE
-- ============================================
/*
For free tier or custom PITR, use timestamped backups:

STRATEGY:
1. Create daily backups at fixed time (e.g., 2 AM UTC)
2. Create pre-deployment backups before changes
3. Create backup before risky operations
4. Keep backups for 30 days minimum

AUTOMATION:
Set up GitHub Actions or cron job to run daily:

#!/bin/bash
# daily_backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="emowed_backup_$DATE.dump"

pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" \
  --format=custom \
  --file="$BACKUP_FILE" \
  --verbose

# Upload to cloud storage (S3, Google Drive, Dropbox)
# Keep last 30 backups, delete older ones
*/

-- ============================================
-- SECTION 7: DISASTER RECOVERY PLAN
-- ============================================

-- ============================================
-- 7.1: RECOVERY TIME OBJECTIVE (RTO)
-- ============================================
/*
RTO: Maximum acceptable downtime

EMOWED RTO TARGETS:
- Critical failure: 4 hours
- Data corruption: 2 hours
- Accidental deletion: 1 hour

STEPS TO MEET RTO:
1. Keep latest backup readily accessible
2. Document restore procedure
3. Test restore monthly
4. Have backup Supabase project ready
5. Automate where possible
*/

-- ============================================
-- 7.2: RECOVERY POINT OBJECTIVE (RPO)
-- ============================================
/*
RPO: Maximum acceptable data loss

EMOWED RPO TARGETS:
- User data: 24 hours (daily backups)
- Critical transactions: 1 hour (Pro tier PITR)
- Configuration: 0 (version controlled)

STRATEGIES:
- Free tier: Daily backups (24-hour RPO)
- Pro tier: Hourly backups + PITR (1-hour RPO)
- Critical: Consider read replicas for near-zero RPO
*/

-- ============================================
-- 7.3: DISASTER RECOVERY PROCEDURE
-- ============================================
/*
STEP-BY-STEP RECOVERY PROCESS:

1. ASSESS SITUATION (5 minutes)
   - What failed? (Database, storage, full system)
   - What data is affected?
   - Is it recoverable without restore?

2. COMMUNICATE (5 minutes)
   - Notify team
   - Put up maintenance page
   - Inform key users if necessary

3. IDENTIFY BACKUP (10 minutes)
   - Find most recent valid backup
   - Verify backup integrity
   - Download if needed

4. PREPARE ENVIRONMENT (15 minutes)
   - Stop application to prevent writes
   - Document current state (screenshots)
   - Create snapshot of current state

5. RESTORE DATABASE (30-60 minutes)
   - Use Supabase dashboard or pg_restore
   - Monitor progress
   - Check for errors

6. RESTORE STORAGE (30-60 minutes)
   - Restore storage buckets if affected
   - Verify file integrity
   - Update file references if needed

7. VALIDATE DATA (30 minutes)
   - Run verification queries
   - Check critical user flows
   - Compare record counts
   - Test key features

8. RESUME SERVICE (15 minutes)
   - Start application
   - Monitor logs
   - Test user login
   - Verify core features

9. POST-MORTEM (24 hours later)
   - Document what happened
   - Update procedures
   - Implement preventive measures
   - Review backup strategy

TOTAL ESTIMATED TIME: 2-4 hours
*/

-- ============================================
-- 7.4: DATA VALIDATION AFTER RESTORE
-- ============================================

CREATE OR REPLACE FUNCTION validate_restore()
RETURNS TABLE (
  check_name TEXT,
  expected_result TEXT,
  actual_result TEXT,
  status TEXT
) AS $$
BEGIN
  -- Check 1: User count
  RETURN QUERY SELECT
    'Total Users'::TEXT,
    'Should match pre-restore count'::TEXT,
    (SELECT COUNT(*)::TEXT FROM users),
    'MANUAL_VERIFY'::TEXT;

  -- Check 2: Wedding count
  RETURN QUERY SELECT
    'Total Weddings'::TEXT,
    'Should match pre-restore count'::TEXT,
    (SELECT COUNT(*)::TEXT FROM weddings),
    'MANUAL_VERIFY'::TEXT;

  -- Check 3: Foreign key integrity
  RETURN QUERY SELECT
    'Foreign Key Integrity'::TEXT,
    'No orphaned records'::TEXT,
    (SELECT COUNT(*)::TEXT FROM couples c
     LEFT JOIN users u1 ON c.user1_id = u1.id
     WHERE u1.id IS NULL),
    CASE
      WHEN (SELECT COUNT(*) FROM couples c
            LEFT JOIN users u1 ON c.user1_id = u1.id
            WHERE u1.id IS NULL) = 0 THEN 'PASS'
      ELSE 'FAIL'
    END;

  -- Check 4: RLS policies
  RETURN QUERY SELECT
    'RLS Policies Active'::TEXT,
    'All tables should have RLS'::TEXT,
    (SELECT COUNT(*)::TEXT FROM pg_tables t
     WHERE t.schemaname = 'public'
     AND NOT EXISTS (
       SELECT 1 FROM pg_policies p
       WHERE p.tablename = t.tablename
     ))::TEXT,
    CASE
      WHEN (SELECT COUNT(*) FROM pg_tables t
            WHERE t.schemaname = 'public'
            AND NOT EXISTS (
              SELECT 1 FROM pg_policies p
              WHERE p.tablename = t.tablename
            )) = 0 THEN 'PASS'
      ELSE 'CHECK_REQUIRED'
    END;

  -- Check 5: Recent data exists
  RETURN QUERY SELECT
    'Recent User Activity'::TEXT,
    'Should have users created in last 30 days'::TEXT,
    (SELECT COUNT(*)::TEXT FROM users
     WHERE created_at > NOW() - INTERVAL '30 days'),
    CASE
      WHEN (SELECT COUNT(*) FROM users
            WHERE created_at > NOW() - INTERVAL '30 days') > 0 THEN 'PASS'
      ELSE 'WARNING - No recent activity'
    END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_restore IS 'Run after restore to validate data integrity';

-- Run after restore:
-- SELECT * FROM validate_restore();

-- ============================================
-- SECTION 8: BACKUP BEST PRACTICES
-- ============================================

-- ============================================
-- 8.1: 3-2-1 BACKUP RULE
-- ============================================
/*
RULE: Keep 3 copies, on 2 different media, with 1 offsite

EMOWED IMPLEMENTATION:

1. COPY 1 - Production Database (Supabase)
   - Live data
   - Not a backup!

2. COPY 2 - Supabase Automatic Backups
   - Daily/hourly backups
   - Same infrastructure
   - First line of defense

3. COPY 3 - Downloaded Backups
   - Weekly downloads to local machine
   - Different media (your computer)
   - Protection against Supabase issues

4. COPY 4 (RECOMMENDED) - Cloud Storage
   - Upload to AWS S3, Google Drive, or Dropbox
   - Offsite protection
   - Geographic redundancy

BACKUP SCHEDULE:
- Daily: Supabase automatic (Copy 2)
- Weekly: Download backup (Copy 3)
- Monthly: Upload to cloud storage (Copy 4)
- Pre-deployment: Manual backup (all copies)
*/

-- ============================================
-- 8.2: BACKUP RETENTION POLICY
-- ============================================
/*
HOW LONG TO KEEP BACKUPS:

DAILY BACKUPS:
- Keep: Last 7 days
- Purpose: Quick recovery from recent issues
- Storage: Supabase automatic

WEEKLY BACKUPS:
- Keep: Last 4 weeks
- Purpose: Medium-term recovery
- Storage: Downloaded, local machine

MONTHLY BACKUPS:
- Keep: Last 12 months
- Purpose: Long-term recovery, compliance
- Storage: Cloud storage (S3, Google Drive)

YEARLY BACKUPS:
- Keep: Last 3 years
- Purpose: Historical data, legal requirements
- Storage: Archived cloud storage

PRE-DEPLOYMENT BACKUPS:
- Keep: Until next deployment successful
- Purpose: Rollback safety
- Storage: Local + Supabase

EXAMPLE RETENTION:
- Total daily backups: 7
- Total weekly backups: 4
- Total monthly backups: 12
- Total yearly backups: 3
- Grand total: 26 backups kept at any time
*/

-- ============================================
-- 8.3: BACKUP SECURITY
-- ============================================
/*
PROTECT YOUR BACKUPS:

1. ENCRYPTION:
   - Encrypt backups at rest
   - Use GPG or similar: gpg -c emowed_backup.dump
   - Never store passwords in backup scripts

2. ACCESS CONTROL:
   - Limit who can download backups
   - Use Supabase team roles
   - Audit backup access

3. SECURE STORAGE:
   - Don't commit backups to Git
   - Add *.dump and *.sql to .gitignore
   - Use encrypted cloud storage

4. PASSWORD ROTATION:
   - Change database password after team changes
   - Update backup scripts accordingly
   - Invalidate old backups if compromised

5. TESTING:
   - Never test restore in production
   - Use separate test project
   - Verify restore works before you need it
*/

-- ============================================
-- 8.4: BACKUP CHECKLIST
-- ============================================
/*
DAILY:
□ Verify automatic backup completed
□ Check backup size (should be consistent)
□ Review backup logs for errors

WEEKLY:
□ Download full backup to local machine
□ Test restore in development environment
□ Verify storage bucket backup

MONTHLY:
□ Upload backup to offsite cloud storage
□ Review retention policy compliance
□ Clean up old backups per retention policy
□ Test disaster recovery procedure

QUARTERLY:
□ Full disaster recovery drill
□ Update documentation
□ Review backup strategy
□ Audit backup access logs

BEFORE DEPLOYMENT:
□ Create manual backup
□ Verify backup successful
□ Download backup locally
□ Document what's being deployed
□ Have rollback plan ready
*/

-- ============================================
-- SECTION 9: BACKUP AUTOMATION
-- ============================================

-- ============================================
-- 9.1: BASH BACKUP SCRIPT
-- ============================================
/*
Save as: backup_emowed.sh

#!/bin/bash
# Emowed Database Backup Script
# Run daily via cron

# Configuration
PROJECT_REF="YOUR_PROJECT_REF"
DB_PASSWORD="YOUR_PASSWORD"
BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="emowed_backup_$DATE.dump"
LOG_FILE="$BACKUP_DIR/backup.log"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Log start
echo "[$DATE] Starting backup..." >> "$LOG_FILE"

# Run backup
pg_dump "postgresql://postgres:$DB_PASSWORD@db.$PROJECT_REF.supabase.co:5432/postgres" \
  --format=custom \
  --file="$BACKUP_DIR/$BACKUP_FILE" \
  --verbose 2>> "$LOG_FILE"

# Check if successful
if [ $? -eq 0 ]; then
  echo "[$DATE] Backup successful: $BACKUP_FILE" >> "$LOG_FILE"

  # Get file size
  SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
  echo "[$DATE] Backup size: $SIZE" >> "$LOG_FILE"

  # Delete backups older than 30 days
  find "$BACKUP_DIR" -name "emowed_backup_*.dump" -mtime +30 -delete
  echo "[$DATE] Cleaned up old backups" >> "$LOG_FILE"
else
  echo "[$DATE] Backup FAILED!" >> "$LOG_FILE"
  # Send alert email or notification
fi

echo "[$DATE] Backup complete" >> "$LOG_FILE"

# Make executable:
# chmod +x backup_emowed.sh

# Schedule via cron (daily at 2 AM):
# crontab -e
# Add: 0 2 * * * /path/to/backup_emowed.sh
*/

-- ============================================
-- 9.2: GITHUB ACTIONS BACKUP
-- ============================================
/*
Save as: .github/workflows/backup.yml

name: Daily Database Backup

on:
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'
  workflow_dispatch: # Manual trigger

jobs:
  backup:
    runs-on: ubuntu-latest

    steps:
      - name: Install PostgreSQL client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Create backup
        env:
          DB_URL: ${{ secrets.SUPABASE_DB_URL }}
        run: |
          DATE=$(date +%Y%m%d_%H%M%S)
          pg_dump "$DB_URL" \
            --format=custom \
            --file="emowed_backup_$DATE.dump"

      - name: Upload to artifact
        uses: actions/upload-artifact@v3
        with:
          name: database-backup
          path: emowed_backup_*.dump
          retention-days: 30

      - name: Upload to S3 (optional)
        if: github.event_name == 'schedule'
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws s3 cp emowed_backup_*.dump s3://your-backup-bucket/

# Add SUPABASE_DB_URL to repository secrets:
# Settings → Secrets → Actions → New repository secret
# Name: SUPABASE_DB_URL
# Value: postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
*/

-- ============================================
-- SECTION 10: QUICK REFERENCE
-- ============================================

-- ============================================
-- 10.1: COMMON BACKUP COMMANDS
-- ============================================
/*
# Full backup
pg_dump "$DB_URL" -Fc -f backup.dump

# Schema only
pg_dump "$DB_URL" -s -f schema.sql

# Data only
pg_dump "$DB_URL" -a -Fc -f data.dump

# Specific tables
pg_dump "$DB_URL" -t users -t weddings -Fc -f tables.dump

# Compressed SQL
pg_dump "$DB_URL" | gzip > backup.sql.gz

# Backup with timestamp
pg_dump "$DB_URL" -Fc -f "backup_$(date +%Y%m%d).dump"
*/

-- ============================================
-- 10.2: COMMON RESTORE COMMANDS
-- ============================================
/*
# Restore from custom format
pg_restore -d "$DB_URL" --clean --if-exists backup.dump

# Restore from SQL
psql "$DB_URL" < backup.sql

# Restore from compressed SQL
gunzip -c backup.sql.gz | psql "$DB_URL"

# Restore specific table
pg_restore -d "$DB_URL" -t users --clean backup.dump

# Restore with verbose output
pg_restore -d "$DB_URL" --clean --verbose backup.dump
*/

-- ============================================
-- 10.3: VERIFICATION QUERIES
-- ============================================

-- Check backup completeness
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Count records in all tables
SELECT
  table_name,
  (xpath('/row/cnt/text()',
    xml_count))[1]::text::int AS row_count
FROM (
  SELECT table_name,
    query_to_xml(format('SELECT COUNT(*) AS cnt FROM %I.%I',
      table_schema, table_name), false, true, '') AS xml_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
) t
ORDER BY row_count DESC;

-- Check for orphaned records
SELECT
  'couples with missing users' as issue,
  COUNT(*) as count
FROM couples c
LEFT JOIN users u1 ON c.user1_id = u1.id
WHERE u1.id IS NULL
UNION ALL
SELECT
  'weddings with missing couples' as issue,
  COUNT(*) as count
FROM weddings w
LEFT JOIN couples c ON w.couple_id = c.id
WHERE c.id IS NULL;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'BACKUP & RESTORE PROCEDURES LOADED';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Documentation created for:';
  RAISE NOTICE '- Full database backups';
  RAISE NOTICE '- Table-specific backups';
  RAISE NOTICE '- Restore procedures';
  RAISE NOTICE '- Storage bucket backups';
  RAISE NOTICE '- Automated backup scripts';
  RAISE NOTICE '- Disaster recovery plan';
  RAISE NOTICE '- Best practices & checklists';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'RECOMMENDED IMMEDIATE ACTIONS:';
  RAISE NOTICE '1. Create first manual backup via Supabase Dashboard';
  RAISE NOTICE '2. Download backup to local machine';
  RAISE NOTICE '3. Test restore in development environment';
  RAISE NOTICE '4. Set up automated backup schedule';
  RAISE NOTICE '5. Create backup tracking table (see Section 5.1)';
  RAISE NOTICE '==============================================';
END $$;
