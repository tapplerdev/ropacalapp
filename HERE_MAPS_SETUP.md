# HERE Maps Setup Instructions

This guide will help you set up HERE Maps integration for real-time traffic-aware routing.

## Why HERE Maps?

- ✅ **30,000 FREE routing requests/month**
- ✅ **Real-time traffic data included**
- ✅ **Historical traffic patterns**
- ✅ **Accurate ETAs accounting for current conditions**
- ✅ No credit card required for free tier

---

## Step 1: Create HERE Developer Account

1. Go to: https://developer.here.com/sign-up
2. Fill out the registration form
3. Verify your email address
4. Login to your account

---

## Step 2: Get Your API Key

1. Login to HERE Platform: https://platform.here.com/
2. Click on **"Projects"** in the left sidebar
3. Click **"Create new project"**
   - Name: `RopacalApp` (or any name)
   - Description: Waste collection routing app
4. Once created, click on your project
5. Go to **"REST & XYZ HUB API Keys"** tab
6. Click **"Create API key"**
7. **Copy the API key** (it looks like: `abcdef123456789...`)

---

## Step 3: Add API Key to Your App

1. Open `/lib/features/driver/here_maps_test_page.dart`
2. Find line 35:
   ```dart
   static const String _hereApiKey = 'YOUR_HERE_MAPS_API_KEY';
   ```
3. Replace `'YOUR_HERE_MAPS_API_KEY'` with your actual API key:
   ```dart
   static const String _hereApiKey = 'YOUR_ACTUAL_KEY_HERE';
   ```

---

## Step 4: Test the Integration

1. Run your app in debug mode:
   ```bash
   flutter run
   ```

2. On the main map page, tap the **orange "Test HERE" button** in the top-left corner

3. This will open the HERE Maps test page

4. Try the following:
   - Create a route (same as normal map)
   - Start a shift
   - Compare ETA times with the OSRM version

---

## What's Different in HERE Maps Test Page?

### Visual Differences:
- **Orange route lines** (instead of blue) to differentiate from OSRM
- **"TRAFFIC-AWARE" badge** in the app bar
- **Traffic layer enabled** on the Google Maps widget

### Functional Differences:
- **Real-time traffic** - ETAs account for current traffic conditions
- **Time-of-day routing** - Knows about rush hour patterns
- **Accident/closure awareness** - Routes around incidents
- **Accurate completion times** - Based on real road conditions

---

## Comparing OSRM vs HERE Maps

| Feature | OSRM (Blue Route) | HERE Maps (Orange Route) |
|---------|-------------------|--------------------------|
| **Route Color** | Blue | Orange |
| **Traffic Data** | ❌ No | ✅ Yes |
| **ETA Accuracy** | Basic (30 km/h avg) | Real-time traffic |
| **Cost** | Free | Free (30K/month) |
| **Best For** | Off-peak routes | Rush hour routes |

---

## Troubleshooting

### "Failed to get route" Error
- **Check API key**: Make sure you copied it correctly
- **Check free tier limits**: 30,000 requests/month
- **Check internet connection**: HERE API requires network access

### "Invalid API key" Error
- Make sure you're using a **REST API key**, not a JavaScript API key
- Regenerate the key if needed from HERE Platform

### No Traffic-Aware Routing
- Make sure `departureTime` is set to current time (it should be by default)
- Check that you're using the HERE Maps test page (orange button)

---

## Next Steps

Once you've tested HERE Maps and confirmed it works:

1. **Compare ETAs**: Create the same route on both pages and compare finish times
2. **Test during rush hour**: See how traffic affects routing
3. **Decide which to keep**:
   - Keep OSRM if traffic doesn't matter for your routes
   - Switch to HERE if you need accurate traffic-aware routing

---

## Free Tier Limits

Your usage: ~3,000 requests/month (estimated)
HERE free tier: 30,000 requests/month

**You're well within the free tier!** Even at 10x growth, you'd still be free.

---

## Need Help?

- HERE Maps Docs: https://developer.here.com/documentation/routing/dev_guide/index.html
- HERE Maps Support: https://developer.here.com/help
- API Status: https://status.here.com/

---

## Optional: Environment Variables

For production, you may want to store the API key as an environment variable instead of hardcoding it:

1. Create `.env` file:
   ```
   HERE_MAPS_API_KEY=your_key_here
   ```

2. Add to `.gitignore`:
   ```
   .env
   ```

3. Use `flutter_dotenv` package to load the key

But for testing, hardcoding is fine!
