# EventPanel - Event Booking & Attendance Verification Application

A complete production-ready mobile-first Event Booking & Attendance Verification Application built with Flutter and Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 🌟 Features

### 👥 User/Participant Features
- ✅ Email + password authentication with role-based access
- ✅ Browse and search events by category
- ✅ View detailed event information with banners
- ✅ Secure payment processing simulation
- ✅ QR code ticket generation
- ✅ My Events dashboard with attendance tracking

### 🛠 Coordinator/Admin Features
- ✅ Analytics dashboard (Events, Registrations, Revenue)
- ✅ Create and manage events with banner uploads
- ✅ Registration management and CSV export
- ✅ QR code scanner for attendance verification
- ✅ Real-time attendance tracking
- ✅ Revenue analytics

## 📱 Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Supabase** - PostgreSQL + Auth + Storage + Real-time
- **Provider** - State management
- **QR Code** - Ticket generation and scanning
- **FL Chart** - Analytics visualization

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Supabase

Create `lib/config/supabase_config.dart` from the template:
```bash
cp lib/config/supabase_config.dart.template lib/config/supabase_config.dart
```

Then edit `lib/config/supabase_config.dart` with your credentials:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

**Note:** The `supabase_config.dart` file is in `.gitignore` to protect your credentials.

### 3. Set Up Database

Run this SQL in your Supabase SQL Editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'coordinator')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  banner_url TEXT,
  category TEXT NOT NULL CHECK (category IN ('academic', 'social', 'sport')),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  registration_deadline TIMESTAMP WITH TIME ZONE,
  venue TEXT NOT NULL,
  max_capacity INTEGER NOT NULL,
  price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  created_by UUID REFERENCES users(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
  allow_waitlist BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Registrations table
CREATE TABLE registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
  amount_paid DECIMAL(10, 2) NOT NULL,
  qr_token TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

-- Attendance table
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  scanned_by UUID REFERENCES users(id) NOT NULL,
  scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Policies (see full documentation for complete RLS policies)
```

### 4. Run the App
```bash
flutter run
```

## 📂 Project Structure

```
lib/
├── config/              # Supabase configuration
├── models/              # Data models (User, Event, Registration, Attendance)
├── services/            # Business logic & API calls
├── providers/           # State management with Provider
├── screens/             # UI screens (Auth, User, Coordinator)
├── widgets/             # Reusable UI components
├── theme/               # Dark premium SaaS theme
├── utils/               # Helper functions
└── main.dart            # Entry point
```

## 🎨 Design System

**Premium Dark SaaS Theme**
- Primary: Electric Blue (#4F6FFF)
- Accent: Purple (#9B6FFF)
- Background: Dark Navy (#0A0E27)
- Card: Dark Blue (#141B3B)
- 8px spacing system
- 20px border radius

## 🔒 Security Features

- ✅ Row-Level Security (RLS) on all tables
- ✅ Role-based access control
- ✅ Secure QR token generation
- ✅ Duplicate attendance prevention
- ✅ Protected storage buckets

## 📱 Key Screens

### User Side
- Login/Register with role selection
- Home - Browse events with search & filters
- Event Details - Full event info with registration
- Payment - Multiple payment methods
- Ticket - QR code display
- My Events - Registration history

### Coordinator Side
- Dashboard - Analytics overview
- Events - Create and manage events
- QR Scanner - Attendance verification
- Registrations - Participant management

## 📊 Database Schema

**Users** → id, name, email, role, created_at
**Events** → id, title, description, banner_url, category, dates, venue, capacity, price, status
**Registrations** → id, user_id, event_id, payment_status, amount_paid, qr_token
**Attendance** → id, user_id, event_id, scanned_by, scanned_at

## 🧪 Testing

```bash
flutter test
```

## 📦 Build for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📄 License

MIT License - feel free to use this project for your own events!

## 👨‍💻 Support

For issues or questions, please open an issue on GitHub.

---

**Built with ❤️ using Flutter & Supabase**
