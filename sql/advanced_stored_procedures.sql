-- ============================================
-- EMOWED ADVANCED STORED PROCEDURES
-- ============================================
-- Purpose: Complex workflows and business logic for frontend
-- Execute after all phase migrations are complete
-- ============================================

-- ============================================
-- PARTNER INVITATION WORKFLOWS
-- ============================================

-- Complete partner invitation generation workflow
CREATE OR REPLACE FUNCTION create_partner_invitation(
  p_sender_id UUID,
  p_receiver_email TEXT,
  p_message TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  code TEXT,
  error_message TEXT,
  expires_at TIMESTAMP
) AS $$
DECLARE
  v_code TEXT;
  v_expires_at TIMESTAMP;
  v_can_invite BOOLEAN;
  v_in_cooldown BOOLEAN;
  v_relationship_status TEXT;
  v_existing_invitation UUID;
BEGIN
  -- Validate: Check relationship status
  SELECT relationship_status INTO v_relationship_status
  FROM users WHERE id = p_sender_id;

  IF v_relationship_status NOT IN ('single', 'divorced', 'widowed') THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, 'User is already in a relationship'::TEXT, NULL::TIMESTAMP;
    RETURN;
  END IF;

  -- Validate: Check can_invite flag
  SELECT can_invite INTO v_can_invite FROM users WHERE id = p_sender_id;
  IF NOT v_can_invite THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, 'User is not allowed to send invitations'::TEXT, NULL::TIMESTAMP;
    RETURN;
  END IF;

  -- Validate: Check cooldown
  SELECT is_in_cooldown(p_sender_id, 'invitation') INTO v_in_cooldown;
  IF v_in_cooldown THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, 'User is in cooldown period'::TEXT, NULL::TIMESTAMP;
    RETURN;
  END IF;

  -- Validate: Check existing pending invitation
  SELECT id INTO v_existing_invitation
  FROM partner_invitations
  WHERE sender_id = p_sender_id
  AND status = 'pending'
  AND expires_at > NOW();

  IF v_existing_invitation IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, 'User already has a pending invitation'::TEXT, NULL::TIMESTAMP;
    RETURN;
  END IF;

  -- Validate: Check receiver email is not sender
  IF p_receiver_email = (SELECT email FROM users WHERE id = p_sender_id) THEN
    RETURN QUERY SELECT FALSE, NULL::TEXT, 'Cannot invite yourself'::TEXT, NULL::TIMESTAMP;
    RETURN;
  END IF;

  -- Generate unique code
  LOOP
    v_code := generate_invite_code();
    EXIT WHEN NOT EXISTS (SELECT 1 FROM partner_invitations WHERE code = v_code);
  END LOOP;

  -- Set expiry
  v_expires_at := NOW() + INTERVAL '48 hours';

  -- Insert invitation
  INSERT INTO partner_invitations (code, sender_id, receiver_email, message, expires_at)
  VALUES (v_code, p_sender_id, p_receiver_email, p_message, v_expires_at);

  -- Update user's last_invite_at
  UPDATE users SET last_invite_at = NOW() WHERE id = p_sender_id;

  -- Create notification for tracking
  PERFORM create_notification(
    p_sender_id,
    'invitation',
    'Partner Invitation Sent',
    'Your partner invitation has been sent to ' || p_receiver_email,
    NULL
  );

  -- Return success
  RETURN QUERY SELECT TRUE, v_code, NULL::TEXT, v_expires_at;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_partner_invitation IS 'Complete workflow for creating partner invitation with validation';

-- Accept partner invitation workflow
CREATE OR REPLACE FUNCTION accept_partner_invitation(
  p_receiver_id UUID,
  p_code TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  couple_id UUID,
  error_message TEXT
) AS $$
DECLARE
  v_invitation_id UUID;
  v_sender_id UUID;
  v_receiver_email TEXT;
  v_couple_id UUID;
  v_relationship_status TEXT;
BEGIN
  -- Get receiver email
  SELECT email INTO v_receiver_email FROM users WHERE id = p_receiver_id;

  -- Validate: Check relationship status
  SELECT relationship_status INTO v_relationship_status
  FROM users WHERE id = p_receiver_id;

  IF v_relationship_status NOT IN ('single', 'divorced', 'widowed') THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Receiver is already in a relationship'::TEXT;
    RETURN;
  END IF;

  -- Validate: Find invitation
  SELECT id, sender_id INTO v_invitation_id, v_sender_id
  FROM partner_invitations
  WHERE code = p_code
  AND receiver_email = v_receiver_email
  AND status = 'pending'
  AND expires_at > NOW();

  IF v_invitation_id IS NULL THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Invalid or expired invitation code'::TEXT;
    RETURN;
  END IF;

  -- Validate: Check sender is still single
  SELECT relationship_status INTO v_relationship_status
  FROM users WHERE id = v_sender_id;

  IF v_relationship_status NOT IN ('single', 'divorced', 'widowed') THEN
    -- Update invitation as expired
    UPDATE partner_invitations SET status = 'expired' WHERE id = v_invitation_id;
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Sender is no longer available'::TEXT;
    RETURN;
  END IF;

  -- Update invitation status
  UPDATE partner_invitations
  SET status = 'accepted', responded_at = NOW()
  WHERE id = v_invitation_id;

  -- Create couple record
  INSERT INTO couples (user1_id, user2_id, status, engaged_date)
  VALUES (v_sender_id, p_receiver_id, 'engaged', CURRENT_DATE)
  RETURNING id INTO v_couple_id;

  -- Note: Trigger will automatically update user relationship_status to 'engaged'

  -- Create notifications for both users
  PERFORM create_notification(
    v_sender_id,
    'acceptance',
    'Partner Invitation Accepted',
    'Your partner invitation has been accepted!',
    '/dashboard'
  );

  PERFORM create_notification(
    p_receiver_id,
    'acceptance',
    'You Are Now Engaged',
    'You have accepted the partner invitation!',
    '/dashboard'
  );

  -- Return success
  RETURN QUERY SELECT TRUE, v_couple_id, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION accept_partner_invitation IS 'Complete workflow for accepting partner invitation';

-- Reject partner invitation workflow
CREATE OR REPLACE FUNCTION reject_partner_invitation(
  p_receiver_id UUID,
  p_code TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_message TEXT
) AS $$
DECLARE
  v_invitation_id UUID;
  v_sender_id UUID;
  v_receiver_email TEXT;
  v_rejection_count INTEGER;
BEGIN
  -- Get receiver email
  SELECT email INTO v_receiver_email FROM users WHERE id = p_receiver_id;

  -- Find invitation
  SELECT id, sender_id, rejection_count INTO v_invitation_id, v_sender_id, v_rejection_count
  FROM partner_invitations
  WHERE code = p_code
  AND receiver_email = v_receiver_email
  AND status = 'pending'
  AND expires_at > NOW();

  IF v_invitation_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Invalid or expired invitation code'::TEXT;
    RETURN;
  END IF;

  -- Update invitation status
  UPDATE partner_invitations
  SET status = 'rejected',
      responded_at = NOW(),
      rejection_count = rejection_count + 1
  WHERE id = v_invitation_id;

  -- Check if reached rejection limit (3)
  IF (v_rejection_count + 1) >= 3 THEN
    -- Disable sender's invitation ability
    UPDATE users SET can_invite = FALSE WHERE id = v_sender_id;

    -- Create cooldown period (30 days)
    INSERT INTO cooldown_periods (user_id, type, expires_at)
    VALUES (v_sender_id, 'invitation', NOW() + INTERVAL '30 days');
  END IF;

  -- Create notification for sender
  PERFORM create_notification(
    v_sender_id,
    'rejection',
    'Partner Invitation Declined',
    'Your partner invitation was declined',
    NULL
  );

  -- Return success
  RETURN QUERY SELECT TRUE, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reject_partner_invitation IS 'Complete workflow for rejecting partner invitation';

-- ============================================
-- WEDDING CREATION WORKFLOWS
-- ============================================

-- Complete wedding creation workflow with event generation
CREATE OR REPLACE FUNCTION create_wedding_with_events(
  p_user_id UUID,
  p_name TEXT,
  p_date DATE,
  p_venue TEXT,
  p_city TEXT,
  p_mode TEXT DEFAULT 'combined',
  p_budget_limit DECIMAL DEFAULT NULL,
  p_guest_limit INTEGER DEFAULT 500
)
RETURNS TABLE (
  success BOOLEAN,
  wedding_id UUID,
  events_created INTEGER,
  error_message TEXT
) AS $$
DECLARE
  v_couple_id UUID;
  v_wedding_id UUID;
  v_relationship_status TEXT;
  v_existing_wedding UUID;
  v_events_count INTEGER;
BEGIN
  -- Validate: Check relationship status
  SELECT relationship_status INTO v_relationship_status
  FROM users WHERE id = p_user_id;

  IF v_relationship_status NOT IN ('engaged', 'married') THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0, 'User must be engaged or married to create a wedding'::TEXT;
    RETURN;
  END IF;

  -- Validate: Date must be in future
  IF p_date <= CURRENT_DATE THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0, 'Wedding date must be in the future'::TEXT;
    RETURN;
  END IF;

  -- Validate: Mode must be valid
  IF p_mode NOT IN ('combined', 'separate') THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0, 'Mode must be either combined or separate'::TEXT;
    RETURN;
  END IF;

  -- Get couple_id
  SELECT id INTO v_couple_id
  FROM couples
  WHERE user1_id = p_user_id OR user2_id = p_user_id;

  IF v_couple_id IS NULL THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0, 'User is not part of a couple'::TEXT;
    RETURN;
  END IF;

  -- Validate: Check if couple already has a wedding
  SELECT id INTO v_existing_wedding
  FROM weddings
  WHERE couple_id = v_couple_id
  AND status NOT IN ('cancelled', 'completed');

  IF v_existing_wedding IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0, 'Couple already has an active wedding'::TEXT;
    RETURN;
  END IF;

  -- Create wedding
  INSERT INTO weddings (
    couple_id, name, date, venue, city, mode,
    budget_limit, guest_limit, status
  )
  VALUES (
    v_couple_id, p_name, p_date, p_venue, p_city, p_mode,
    p_budget_limit, p_guest_limit, 'planning'
  )
  RETURNING id INTO v_wedding_id;

  -- Generate wedding events
  PERFORM generate_wedding_events(v_wedding_id, p_date, p_venue, p_city);

  -- Count generated events
  SELECT COUNT(*) INTO v_events_count
  FROM events WHERE wedding_id = v_wedding_id AND auto_generated = TRUE;

  -- Update couple record with wedding
  UPDATE couples SET updated_at = NOW() WHERE id = v_couple_id;

  -- Create notification for both partners
  PERFORM create_notification(
    p_user_id,
    'wedding_created',
    'Wedding Created Successfully',
    'Your wedding "' || p_name || '" has been created with ' || v_events_count::TEXT || ' events',
    '/wedding/' || v_wedding_id::TEXT
  );

  -- Notify the other partner
  DECLARE
    v_partner_id UUID;
  BEGIN
    SELECT CASE WHEN user1_id = p_user_id THEN user2_id ELSE user1_id END
    INTO v_partner_id
    FROM couples WHERE id = v_couple_id;

    PERFORM create_notification(
      v_partner_id,
      'wedding_created',
      'Wedding Created',
      'Your partner created the wedding "' || p_name || '"',
      '/wedding/' || v_wedding_id::TEXT
    );
  END;

  -- Return success
  RETURN QUERY SELECT TRUE, v_wedding_id, v_events_count, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_wedding_with_events IS 'Complete workflow for creating wedding with auto-generated events';

-- ============================================
-- DASHBOARD DATA AGGREGATION
-- ============================================

-- Get complete single user dashboard data
CREATE OR REPLACE FUNCTION get_single_dashboard_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'user', (
      SELECT json_build_object(
        'id', id,
        'email', email,
        'full_name', full_name,
        'age', age,
        'relationship_status', relationship_status,
        'can_invite', can_invite
      )
      FROM users WHERE id = p_user_id
    ),
    'pending_invitations', (
      SELECT json_agg(json_build_object(
        'id', id,
        'code', code,
        'receiver_email', receiver_email,
        'created_at', created_at,
        'expires_at', expires_at,
        'status', status
      ))
      FROM partner_invitations
      WHERE sender_id = p_user_id
      AND status = 'pending'
      AND expires_at > NOW()
    ),
    'received_invitations', (
      SELECT json_agg(json_build_object(
        'id', id,
        'code', code,
        'sender_id', sender_id,
        'sender_name', (SELECT full_name FROM users WHERE id = sender_id),
        'created_at', created_at,
        'expires_at', expires_at,
        'message', message
      ))
      FROM partner_invitations
      WHERE receiver_email = (SELECT email FROM users WHERE id = p_user_id)
      AND status = 'pending'
      AND expires_at > NOW()
    ),
    'notifications', (
      SELECT json_agg(json_build_object(
        'id', id,
        'type', type,
        'title', title,
        'message', message,
        'read', read,
        'created_at', created_at
      ) ORDER BY created_at DESC)
      FROM notifications
      WHERE user_id = p_user_id
      AND read = FALSE
      LIMIT 10
    ),
    'in_cooldown', is_in_cooldown(p_user_id, 'invitation')
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_single_dashboard_data IS 'Get all dashboard data for single user in one query';

-- Get complete engaged dashboard data
CREATE OR REPLACE FUNCTION get_engaged_dashboard_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
  v_couple_id UUID;
  v_wedding_id UUID;
BEGIN
  -- Get couple_id
  SELECT id INTO v_couple_id
  FROM couples
  WHERE user1_id = p_user_id OR user2_id = p_user_id;

  IF v_couple_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get wedding_id if exists
  SELECT id INTO v_wedding_id
  FROM weddings
  WHERE couple_id = v_couple_id
  AND status NOT IN ('cancelled', 'completed');

  SELECT json_build_object(
    'couple', (
      SELECT json_build_object(
        'id', c.id,
        'status', c.status,
        'engaged_date', c.engaged_date,
        'married_date', c.married_date,
        'user1', json_build_object(
          'id', u1.id,
          'full_name', u1.full_name,
          'email', u1.email
        ),
        'user2', json_build_object(
          'id', u2.id,
          'full_name', u2.full_name,
          'email', u2.email
        )
      )
      FROM couples c
      JOIN users u1 ON c.user1_id = u1.id
      JOIN users u2 ON c.user2_id = u2.id
      WHERE c.id = v_couple_id
    ),
    'wedding', (
      SELECT json_build_object(
        'id', w.id,
        'name', w.name,
        'date', w.date,
        'venue', w.venue,
        'city', w.city,
        'mode', w.mode,
        'budget_limit', w.budget_limit,
        'guest_limit', w.guest_limit,
        'status', w.status,
        'days_until', (w.date - CURRENT_DATE)
      )
      FROM weddings w
      WHERE w.id = v_wedding_id
    ),
    'wedding_stats', CASE WHEN v_wedding_id IS NOT NULL THEN (
      SELECT json_build_object(
        'total_events', (SELECT COUNT(*) FROM events WHERE wedding_id = v_wedding_id),
        'total_guests', (SELECT COUNT(*) FROM guests WHERE wedding_id = v_wedding_id),
        'guests_responded', (SELECT COUNT(*) FROM guests g JOIN rsvps r ON g.id = r.guest_id WHERE g.wedding_id = v_wedding_id AND r.status != 'pending'),
        'total_vendors', (SELECT COUNT(*) FROM vendor_bookings WHERE wedding_id = v_wedding_id),
        'confirmed_vendors', (SELECT COUNT(*) FROM vendor_bookings WHERE wedding_id = v_wedding_id AND booking_status = 'confirmed')
      )
    ) ELSE NULL END,
    'upcoming_events', CASE WHEN v_wedding_id IS NOT NULL THEN (
      SELECT json_agg(json_build_object(
        'id', id,
        'name', name,
        'event_type', event_type,
        'date', date,
        'start_time', start_time,
        'venue', venue
      ) ORDER BY date)
      FROM events
      WHERE wedding_id = v_wedding_id
      AND date >= CURRENT_DATE
      LIMIT 5
    ) ELSE NULL END,
    'notifications', (
      SELECT json_agg(json_build_object(
        'id', id,
        'type', type,
        'title', title,
        'message', message,
        'read', read,
        'created_at', created_at
      ) ORDER BY created_at DESC)
      FROM notifications
      WHERE user_id = p_user_id
      AND read = FALSE
      LIMIT 10
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_engaged_dashboard_data IS 'Get all dashboard data for engaged user in one query';

-- ============================================
-- GUEST INVITATION WORKFLOWS
-- ============================================

-- Invite guest with validation
CREATE OR REPLACE FUNCTION invite_wedding_guest(
  p_wedding_id UUID,
  p_inviter_id UUID,
  p_guest_email TEXT,
  p_guest_name TEXT,
  p_guest_phone TEXT,
  p_side TEXT,
  p_role TEXT,
  p_can_invite_others BOOLEAN DEFAULT FALSE,
  p_plus_one_allowed BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  success BOOLEAN,
  guest_id UUID,
  error_message TEXT
) AS $$
DECLARE
  v_guest_id UUID;
  v_inviter_role TEXT;
  v_can_invite BOOLEAN;
  v_existing_guest UUID;
BEGIN
  -- Validate: Check wedding exists and inviter has access
  IF NOT EXISTS (
    SELECT 1 FROM weddings w
    JOIN couples c ON w.couple_id = c.id
    WHERE w.id = p_wedding_id
    AND (c.user1_id = p_inviter_id OR c.user2_id = p_inviter_id)
  ) THEN
    -- Check if inviter is an existing guest with invite permission
    SELECT role, can_invite_others INTO v_inviter_role, v_can_invite
    FROM guests
    WHERE wedding_id = p_wedding_id
    AND user_id = p_inviter_id;

    IF v_inviter_role IS NULL OR NOT v_can_invite THEN
      RETURN QUERY SELECT FALSE, NULL::UUID, 'User does not have permission to invite guests'::TEXT;
      RETURN;
    END IF;
  ELSE
    v_inviter_role := 'groom'; -- Couple members have full permissions
  END IF;

  -- Validate: Check if guest already exists
  SELECT id INTO v_existing_guest
  FROM guests
  WHERE wedding_id = p_wedding_id
  AND email = p_guest_email;

  IF v_existing_guest IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Guest with this email already invited'::TEXT;
    RETURN;
  END IF;

  -- Validate: Check role-based permissions
  IF NOT can_invite_guest(v_inviter_role, p_role) THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Not authorized to invite guests with this role'::TEXT;
    RETURN;
  END IF;

  -- Validate: Check side
  IF p_side NOT IN ('groom', 'bride', 'both') THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 'Invalid side specified'::TEXT;
    RETURN;
  END IF;

  -- Insert guest
  INSERT INTO guests (
    wedding_id, email, full_name, phone, side, role,
    invited_by, can_invite_others, plus_one_allowed,
    status, invitation_sent_at
  )
  VALUES (
    p_wedding_id, p_guest_email, p_guest_name, p_guest_phone, p_side, p_role,
    p_inviter_id, p_can_invite_others, p_plus_one_allowed,
    'invited', NOW()
  )
  RETURNING id INTO v_guest_id;

  -- Create guest invitation record
  INSERT INTO guest_invitations (
    wedding_id, sender_id, receiver_email, receiver_name,
    role, side, can_invite_others, status
  )
  VALUES (
    p_wedding_id, p_inviter_id, p_guest_email, p_guest_name,
    p_role, p_side, p_can_invite_others, 'pending'
  );

  -- Return success
  RETURN QUERY SELECT TRUE, v_guest_id, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION invite_wedding_guest IS 'Complete workflow for inviting guest with validation';

-- ============================================
-- RSVP SUBMISSION WORKFLOWS
-- ============================================

-- Submit RSVP with headcount update
CREATE OR REPLACE FUNCTION submit_rsvp(
  p_guest_id UUID,
  p_event_id UUID,
  p_status TEXT,
  p_adults_count INTEGER DEFAULT 1,
  p_teens_count INTEGER DEFAULT 0,
  p_children_count INTEGER DEFAULT 0,
  p_dietary_preferences TEXT[] DEFAULT NULL,
  p_special_requirements TEXT DEFAULT NULL,
  p_rsvp_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  rsvp_id UUID,
  calculated_headcount DECIMAL,
  error_message TEXT
) AS $$
DECLARE
  v_rsvp_id UUID;
  v_wedding_id UUID;
  v_headcount DECIMAL;
  v_existing_rsvp UUID;
  v_event_date DATE;
BEGIN
  -- Validate: Check guest exists
  IF NOT EXISTS (SELECT 1 FROM guests WHERE id = p_guest_id) THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0::DECIMAL, 'Guest not found'::TEXT;
    RETURN;
  END IF;

  -- Validate: Check event exists
  SELECT wedding_id, date INTO v_wedding_id, v_event_date
  FROM events WHERE id = p_event_id;

  IF v_wedding_id IS NULL THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0::DECIMAL, 'Event not found'::TEXT;
    RETURN;
  END IF;

  -- Validate: Check RSVP deadline
  IF v_event_date - INTERVAL '24 hours' < NOW() THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0::DECIMAL, 'RSVP deadline has passed'::TEXT;
    RETURN;
  END IF;

  -- Validate: Status must be valid
  IF p_status NOT IN ('attending', 'not_attending', 'maybe') THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0::DECIMAL, 'Invalid RSVP status'::TEXT;
    RETURN;
  END IF;

  -- Validate: If attending, must have at least 1 adult
  IF p_status = 'attending' AND p_adults_count < 1 THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, 0::DECIMAL, 'At least 1 adult required when attending'::TEXT;
    RETURN;
  END IF;

  -- Calculate headcount
  v_headcount := (p_adults_count * 1.0) + (p_teens_count * 0.75) + (p_children_count * 0.3);

  -- Check if RSVP already exists
  SELECT id INTO v_existing_rsvp
  FROM rsvps
  WHERE event_id = p_event_id AND guest_id = p_guest_id;

  IF v_existing_rsvp IS NOT NULL THEN
    -- Update existing RSVP
    UPDATE rsvps
    SET status = p_status,
        adults_count = p_adults_count,
        teens_count = p_teens_count,
        children_count = p_children_count,
        dietary_preferences = p_dietary_preferences,
        special_requirements = p_special_requirements,
        rsvp_notes = p_rsvp_notes,
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = v_existing_rsvp;

    v_rsvp_id := v_existing_rsvp;
  ELSE
    -- Insert new RSVP
    INSERT INTO rsvps (
      event_id, guest_id, wedding_id, status,
      adults_count, teens_count, children_count,
      dietary_preferences, special_requirements, rsvp_notes,
      submitted_at
    )
    VALUES (
      p_event_id, p_guest_id, v_wedding_id, p_status,
      p_adults_count, p_teens_count, p_children_count,
      p_dietary_preferences, p_special_requirements, p_rsvp_notes,
      NOW()
    )
    RETURNING id INTO v_rsvp_id;
  END IF;

  -- Update headcount snapshot
  PERFORM update_headcount_snapshot(p_event_id, v_wedding_id);

  -- Update guest status
  UPDATE guests
  SET status = p_status, responded_at = NOW()
  WHERE id = p_guest_id;

  -- Return success
  RETURN QUERY SELECT TRUE, v_rsvp_id, v_headcount, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION submit_rsvp IS 'Complete workflow for submitting RSVP with automatic headcount calculation';

-- ============================================
-- NOTIFICATION TRIGGERS
-- ============================================

-- Trigger to notify on invitation acceptance
CREATE OR REPLACE FUNCTION notify_on_invitation_acceptance()
RETURNS TRIGGER AS $$
DECLARE
  v_sender_name TEXT;
  v_receiver_name TEXT;
BEGIN
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    -- Get names
    SELECT full_name INTO v_sender_name FROM users WHERE id = NEW.sender_id;
    SELECT full_name INTO v_receiver_name FROM users WHERE id = (
      SELECT id FROM users WHERE email = NEW.receiver_email
    );

    -- Notify sender
    PERFORM create_notification(
      NEW.sender_id,
      'acceptance',
      'Partner Invitation Accepted',
      v_receiver_name || ' has accepted your invitation!',
      '/dashboard'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_invitation_acceptance ON partner_invitations;
CREATE TRIGGER trigger_notify_invitation_acceptance
AFTER UPDATE ON partner_invitations
FOR EACH ROW
EXECUTE FUNCTION notify_on_invitation_acceptance();

-- Trigger to notify on RSVP submission
CREATE OR REPLACE FUNCTION notify_on_rsvp_submission()
RETURNS TRIGGER AS $$
DECLARE
  v_guest_name TEXT;
  v_event_name TEXT;
  v_couple_user1 UUID;
  v_couple_user2 UUID;
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.status != OLD.status) THEN
    -- Get guest and event details
    SELECT full_name INTO v_guest_name FROM guests WHERE id = NEW.guest_id;
    SELECT name INTO v_event_name FROM events WHERE id = NEW.event_id;

    -- Get couple members
    SELECT c.user1_id, c.user2_id INTO v_couple_user1, v_couple_user2
    FROM weddings w
    JOIN couples c ON w.couple_id = c.id
    WHERE w.id = NEW.wedding_id;

    -- Notify couple
    PERFORM create_notification(
      v_couple_user1,
      'rsvp_received',
      'New RSVP Received',
      v_guest_name || ' has responded to ' || v_event_name || ': ' || NEW.status,
      '/events/' || NEW.event_id::TEXT
    );

    PERFORM create_notification(
      v_couple_user2,
      'rsvp_received',
      'New RSVP Received',
      v_guest_name || ' has responded to ' || v_event_name || ': ' || NEW.status,
      '/events/' || NEW.event_id::TEXT
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_rsvp_submission ON rsvps;
CREATE TRIGGER trigger_notify_rsvp_submission
AFTER INSERT OR UPDATE ON rsvps
FOR EACH ROW
EXECUTE FUNCTION notify_on_rsvp_submission();

-- ============================================
-- ANALYTICS AND REPORTING
-- ============================================

-- Get wedding progress analytics
CREATE OR REPLACE FUNCTION get_wedding_analytics(p_wedding_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'wedding_id', p_wedding_id,
    'events', json_build_object(
      'total', (SELECT COUNT(*) FROM events WHERE wedding_id = p_wedding_id),
      'auto_generated', (SELECT COUNT(*) FROM events WHERE wedding_id = p_wedding_id AND auto_generated = TRUE),
      'custom', (SELECT COUNT(*) FROM events WHERE wedding_id = p_wedding_id AND auto_generated = FALSE),
      'upcoming', (SELECT COUNT(*) FROM events WHERE wedding_id = p_wedding_id AND date >= CURRENT_DATE)
    ),
    'guests', json_build_object(
      'total_invited', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id),
      'by_side', json_build_object(
        'groom', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND side = 'groom'),
        'bride', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND side = 'bride'),
        'both', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND side = 'both')
      ),
      'by_status', json_build_object(
        'invited', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND status = 'invited'),
        'accepted', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND status = 'accepted'),
        'declined', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND status = 'declined'),
        'maybe', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND status = 'maybe')
      ),
      'vip_count', (SELECT COUNT(*) FROM guests WHERE wedding_id = p_wedding_id AND is_vip = TRUE)
    ),
    'rsvps', json_build_object(
      'total_responses', (SELECT COUNT(DISTINCT guest_id) FROM rsvps WHERE wedding_id = p_wedding_id),
      'completion_rate', get_rsvp_completion_rate(p_wedding_id),
      'total_headcount', calculate_total_headcount(p_wedding_id),
      'by_status', json_build_object(
        'attending', (SELECT COUNT(*) FROM rsvps WHERE wedding_id = p_wedding_id AND status = 'attending'),
        'not_attending', (SELECT COUNT(*) FROM rsvps WHERE wedding_id = p_wedding_id AND status = 'not_attending'),
        'maybe', (SELECT COUNT(*) FROM rsvps WHERE wedding_id = p_wedding_id AND status = 'maybe')
      )
    ),
    'budget', get_wedding_budget_summary(p_wedding_id),
    'progress_percentage', get_wedding_progress(p_wedding_id)
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_wedding_analytics IS 'Get comprehensive wedding analytics in one query';

-- ============================================
-- USAGE EXAMPLES
-- ============================================

/*
-- Create partner invitation
SELECT * FROM create_partner_invitation(
  'sender-user-id',
  'receiver@example.com',
  'Will you be my partner?'
);

-- Accept invitation
SELECT * FROM accept_partner_invitation(
  'receiver-user-id',
  'ABC123'
);

-- Create wedding with events
SELECT * FROM create_wedding_with_events(
  'user-id',
  'Our Amazing Wedding',
  '2025-12-25',
  'Grand Hotel Ballroom',
  'Mumbai',
  'combined',
  500000.00,
  500
);

-- Get single dashboard data
SELECT get_single_dashboard_data('user-id');

-- Get engaged dashboard data
SELECT get_engaged_dashboard_data('user-id');

-- Invite guest
SELECT * FROM invite_wedding_guest(
  'wedding-id',
  'inviter-user-id',
  'guest@example.com',
  'John Doe',
  '+91 98765 43210',
  'groom',
  'friend',
  FALSE,
  TRUE
);

-- Submit RSVP
SELECT * FROM submit_rsvp(
  'guest-id',
  'event-id',
  'attending',
  2,  -- adults
  1,  -- teens
  1,  -- children
  ARRAY['vegetarian'],
  'No peanuts please',
  'Looking forward to it!'
);

-- Get wedding analytics
SELECT get_wedding_analytics('wedding-id');
*/

-- ============================================
-- VERIFICATION
-- ============================================

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as arguments,
  pg_get_function_result(oid) as returns
FROM pg_proc
WHERE proname IN (
  'create_partner_invitation',
  'accept_partner_invitation',
  'reject_partner_invitation',
  'create_wedding_with_events',
  'get_single_dashboard_data',
  'get_engaged_dashboard_data',
  'invite_wedding_guest',
  'submit_rsvp',
  'get_wedding_analytics'
)
ORDER BY proname;

-- ============================================
-- SUCCESS
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'ADVANCED STORED PROCEDURES CREATED SUCCESSFULLY';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'The following workflows are now available:';
  RAISE NOTICE '- Partner Invitation (create, accept, reject)';
  RAISE NOTICE '- Wedding Creation with auto-events';
  RAISE NOTICE '- Dashboard Data Aggregation';
  RAISE NOTICE '- Guest Invitation with validation';
  RAISE NOTICE '- RSVP Submission with headcount';
  RAISE NOTICE '- Real-time notifications (triggers)';
  RAISE NOTICE '- Wedding Analytics';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'See USAGE EXAMPLES section for implementation details';
  RAISE NOTICE '==========================================';
END $$;
