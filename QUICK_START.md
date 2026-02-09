# 🚀 QUICK START - GlucoDietix

## For Absolute Beginners - Follow These Exact Steps

### STEP 1: Set Up Supabase (5 minutes)

1. Go to https://supabase.com
2. Click "Start your project" → Sign up with GitHub or email
3. Click "New Project"
4. Fill in:
   - Name: `glucodietix`
   - Password: (make one up and save it)
   - Region: (pick closest to you)
5. Click "Create new project"
6. **WAIT 2-3 MINUTES** for project to initialize

### STEP 2: Create Database Tables (2 minutes)

1. In Supabase, left sidebar → Click "SQL Editor"
2. Click "+ New query"
3. Open the file: `database/schema.sql` in your code editor
4. Copy ALL the text (Ctrl+A, Ctrl+C)
5. Paste into Supabase SQL editor (Ctrl+V)
6. Click "Run" at bottom right
7. You should see: "Success. No rows returned" ✅

### STEP 3: Add Sample Food Data (1 minute)

1. In Supabase SQL Editor, click "+ New query" again
2. Open the file: `database/seed_data.sql`
3. Copy ALL the text
4. Paste into Supabase SQL editor
5. Click "Run"
6. You should see: Results showing 5 foods and 10 portions ✅

### STEP 4: Get Your Credentials (1 minute)

1. In Supabase, left sidebar → Click "Settings" (gear icon)
2. Click "API" under Project Settings
3. You'll see two things we need:
   
   **A) Project URL** (looks like):
   ```
   https://abcdefghijklm.supabase.co
   ```
   Copy this entire URL ✅
   
   **B) Project API keys → anon public** (very long text starting with eyJ...):
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzd...
   ```
   Click "Copy" button next to it ✅

4. Keep these somewhere (Notepad, etc.)

### STEP 5: Configure Your App (2 minutes)

1. In VS Code, open: `lib/config/supabase_config.dart`
2. You'll see:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
   ```

3. Replace with your actual values (paste what you copied):
   ```dart
   static const String supabaseUrl = 'https://abcdefghijklm.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3M...';
   ```

4. **Save the file** (Ctrl+S)

### STEP 6: Install Dependencies (2 minutes)

Open terminal in VS Code (Terminal → New Terminal) and type:

```bash
flutter pub get
```

Press Enter. Wait for it to finish (you'll see "exit code 0").

### STEP 7: Connect Your Phone (3 minutes)

**On your Android phone:**
1. Go to Settings → About Phone
2. Tap "Build Number" 7 times (enables Developer Mode)
3. Go back → Developer Options
4. Turn on "USB Debugging"
5. Connect phone to computer with USB cable
6. On phone screen, tap "Allow USB Debugging" when popup appears

**In VS Code terminal, check connection:**
```bash
flutter devices
```

You should see your phone listed ✅

### STEP 8: Run the App! (5 minutes first time)

In VS Code terminal:
```bash
flutter run
```

**First time takes 3-5 minutes** to build. ⏳
Subsequent runs are much faster (30 seconds).

You'll see app install and launch on your phone! 🎉

---

## 🎯 USING THE APP - QUICK GUIDE

### First Time Setup:

1. **Register**
   - Tap "Don't have an account? Register"
   - Enter email: `test@example.com`
   - Enter password: `password123` (min 6 chars)
   - Tap "Register"
   - Tap "Already have an account? Login"

2. **Login**
   - Email: `test@example.com`
   - Password: `password123`
   - Tap "Login"

3. **Set Profile**
   - Tap profile icon (top right)
   - Choose your health settings
   - Tap "Save Profile"

### Build Your First Meal:

1. **Add Food**
   - Tap "Add Food" button
   - In search box, type: `rice`
   - Tap + icon next to "White Rice (Cooked)"
   - Select "1 cup" portion
   - Tap "Add to Meal"

2. **Add More Foods**
   - Search for "dhal"
   - Add "Dhal Curry"
   - Choose portion
   - Repeat for 2-3 more foods

3. **See Results**
   - Tap "Calculate Nutrients"
   - View:
     - ✅ "Meal is OK!" (green) or ❌ "Not OK" (red)
     - Total carbs, protein, fat, etc.
     - Recommendations (if over carb limit)

---

## ❌ WHAT IF SOMETHING GOES WRONG?

### "Build failed" or errors in terminal

```bash
flutter clean
flutter pub get
flutter run
```

### "Invalid API key" error

1. Double-check you copied the **anon public** key (not service_role)
2. Make sure you didn't add spaces before/after the URL or key
3. Restart the app completely (stop and run again)

### Can't see any foods

1. Go to Supabase → Table Editor → foods table
2. Click "Insert row" manually and add a test food

### Phone not detected

1. Unplug and replug USB cable
2. On phone, tap "Transfer files" (not "Charge only")
3. Run: `flutter devices` again

### App crashes immediately

1. Check internet connection (app needs internet)
2. Verify Supabase credentials are correct
3. Check terminal for error message

---

## 🎓 WHAT YOU JUST BUILT

You now have a fully functional app with:
- ✅ User registration & login (Supabase Auth)
- ✅ User profiles with health data
- ✅ Sri Lankan food database
- ✅ Meal builder with portion selection
- ✅ Smart carb calculator with recommendations
- ✅ Camera integration for plate scanning
- ✅ AR view integration (WebVR ready)

**Total Time: ~20 minutes** ⚡

---

## 📚 NEXT: Read the Full README

For troubleshooting, customization, and advanced features, see: [README.md](README.md)

---

**You did it! 🎉 Happy coding!**
