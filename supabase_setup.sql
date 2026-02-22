-- ================================================
-- SUPABASE DATABASE SETUP FOR EVENTPANEL
-- ================================================
-- Run this script in your Supabase SQL Editor
-- ================================================

-- =================
-- CREATE TABLES
-- =================

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'coordinator')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events table
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  banner_url TEXT,
  category TEXT NOT NULL CHECK (category IN ('academic', 'social', 'sport')),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  registration_deadline TIMESTAMP WITH TIME ZONE,
  venue TEXT NOT NULL,
  max_capacity INTEGER NOT NULL CHECK (max_capacity > 0),
  price DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  created_by UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
  allow_waitlist BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Registrations table
CREATE TABLE IF NOT EXISTS registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
  amount_paid DECIMAL(10, 2) NOT NULL CHECK (amount_paid >= 0),
  qr_token TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

-- Attendance table
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  scanned_by UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

-- =================
-- CREATE INDEXES
-- =================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_events_created_by ON events(created_by);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_registrations_user_id ON registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_registrations_event_id ON registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_registrations_qr_token ON registrations(qr_token);
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_event_id ON attendance(event_id);

-- =================
-- CREATE STORAGE BUCKET
-- =================

-- Insert storage bucket for event banners (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-banners', 'event-banners', true)
ON CONFLICT (id) DO NOTHING;

-- =================
-- ENABLE ROW LEVEL SECURITY
-- =================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- =================
-- DROP EXISTING POLICIES (if any)
-- =================

DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Anyone can insert during signup" ON users;

DROP POLICY IF EXISTS "Anyone can view published events" ON events;
DROP POLICY IF EXISTS "Coordinators can create events" ON events;
DROP POLICY IF EXISTS "Coordinators can update their events" ON events;
DROP POLICY IF EXISTS "Coordinators can delete their events" ON events;

DROP POLICY IF EXISTS "Users can view their registrations" ON registrations;
DROP POLICY IF EXISTS "Users can create registrations" ON registrations;
DROP POLICY IF EXISTS "Users can update their registrations" ON registrations;

DROP POLICY IF EXISTS "Coordinators can view attendance for their events" ON attendance;
DROP POLICY IF EXISTS "Coordinators can mark attendance" ON attendance;
DROP POLICY IF EXISTS "Users can view their attendance" ON attendance;

-- =================
-- CREATE RLS POLICIES - USERS TABLE
-- =================

CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Anyone can insert during signup"
  ON users FOR INSERT
  WITH CHECK (true);

-- =================
-- CREATE RLS POLICIES - EVENTS TABLE
-- =================

CREATE POLICY "Anyone can view published events"
  ON events FOR SELECT
  USING (
    status = 'published'
    OR created_by = auth.uid()
  );

CREATE POLICY "Coordinators can create events"
  ON events FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users WHERE role = 'coordinator'
    )
    AND created_by = auth.uid()
  );

CREATE POLICY "Coordinators can update their events"
  ON events FOR UPDATE
  USING (created_by = auth.uid());

CREATE POLICY "Coordinators can delete their events"
  ON events FOR DELETE
  USING (created_by = auth.uid());

-- =================
-- CREATE RLS POLICIES - REGISTRATIONS TABLE
-- =================

CREATE POLICY "Users can view their registrations"
  ON registrations FOR SELECT
  USING (
    user_id = auth.uid()
    OR event_id IN (
      SELECT id FROM events WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Users can create registrations"
  ON registrations FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their registrations"
  ON registrations FOR UPDATE
  USING (
    user_id = auth.uid()
    OR event_id IN (
      SELECT id FROM events WHERE created_by = auth.uid()
    )
  );

-- =================
-- CREATE RLS POLICIES - ATTENDANCE TABLE
-- =================

CREATE POLICY "Coordinators can view attendance for their events"
  ON attendance FOR SELECT
  USING (
    event_id IN (
      SELECT id FROM events WHERE created_by = auth.uid()
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Users can view their attendance"
  ON attendance FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Coordinators can mark attendance"
  ON attendance FOR INSERT
  WITH CHECK (
    scanned_by = auth.uid()
    AND scanned_by IN (
      SELECT id FROM users WHERE role = 'coordinator'
    )
    AND event_id IN (
      SELECT id FROM events WHERE created_by = auth.uid()
    )
  );

-- =================
-- CREATE STORAGE POLICIES
-- =================

DROP POLICY IF EXISTS "Anyone can view event banners" ON storage.objects;
DROP POLICY IF EXISTS "Coordinators can upload event banners" ON storage.objects;
DROP POLICY IF EXISTS "Coordinators can update event banners" ON storage.objects;
DROP POLICY IF EXISTS "Coordinators can delete event banners" ON storage.objects;

CREATE POLICY "Anyone can view event banners"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'event-banners');

CREATE POLICY "Coordinators can upload event banners"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'event-banners'
    AND auth.uid() IN (
      SELECT id FROM users WHERE role = 'coordinator'
    )
  );

CREATE POLICY "Coordinators can update event banners"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'event-banners'
    AND auth.uid() IN (
      SELECT id FROM users WHERE role = 'coordinator'
    )
  );

CREATE POLICY "Coordinators can delete event banners"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'event-banners'
    AND auth.uid() IN (
      SELECT id FROM users WHERE role = 'coordinator'
    )
  );

-- =================
-- CREATE FUNCTIONS
-- =================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =================
-- CREATE TRIGGERS
-- =================

DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_registrations_updated_at ON registrations;
CREATE TRIGGER update_registrations_updated_at
  BEFORE UPDATE ON registrations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =================
-- INSERT SAMPLE DATA (OPTIONAL - FOR TESTING)
-- =================

-- Note: Uncomment the following section to insert sample data

/*
-- Sample coordinator user (password: Test123!)
-- You'll need to create this user through Supabase Auth first

-- Sample events (replace 'YOUR_COORDINATOR_UUID' with actual UUID)
INSERT INTO events (title, description, category, start_date, venue, max_capacity, price, created_by, status)
VALUES
  (
    'AI & Future Tech Summit',
    'Join us for a deep dive into the future of generative AI, immersive tech, and software engineering. This summit brings together leading engineers and tech industry leaders.',
    'academic',
    NOW() + INTERVAL '30 days',
    'Main Auditorium, Building C',
    250,
    15.00,
    'YOUR_COORDINATOR_UUID',
    'published'
  ),
  (
    'Freshman Orientation Mixer',
    'The easiest way to register for workshops, club meetups, and campus parties. Meet new students and join the community!',
    'social',
    NOW() + INTERVAL '7 days',
    'Student Union Hall',
    150,
    0.00,
    'YOUR_COORDINATOR_UUID',
    'published'
  );
*/

-- =================
-- VERIFICATION QUERIES
-- =================

-- Run these queries to verify the setup
SELECT 'Tables created:' AS status;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('users', 'events', 'registrations', 'attendance');

SELECT 'Storage bucket created:' AS status;
SELECT * FROM storage.buckets WHERE id = 'event-banners';

SELECT 'RLS enabled:' AS status;
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('users', 'events', 'registrations', 'attendance');

-- =================
-- SETUP COMPLETE
-- =================
-- Your EventPanel database is now ready to use!
-- Don't forget to update your Supabase credentials in the Flutter app.

