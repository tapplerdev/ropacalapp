# Mapbox Setup Guide

## Step 1: Create Mapbox Account & Get Access Tokens

### 1. Go to Mapbox Website
Visit: https://account.mapbox.com/auth/signup/

### 2. Sign Up (Free)
- Use your email
- Choose "Individual" plan
- **Free tier includes:** 50,000 map loads/month, 100,000 routing requests/month

### 3. Get Your Access Tokens

Once logged in, you'll be redirected to your dashboard.

#### **Public Token** (for maps display)
1. Go to: https://account.mapbox.com/access-tokens/
2. You should see a **Default public token** already created
3. **Copy this token** - it starts with `pk.`
4. This is your `PUBLIC_TOKEN`

#### **Secret Token** (for downloads - iOS only)
1. On the same page, click **"Create a token"**
2. Name it: `SECRET_TOKEN_IOS`
3. Under **Secret scopes**, check:
   - ✅ `DOWNLOADS:READ`
4. Click **"Create token"**
5. **Copy this token immediately** - it starts with `sk.` and you won't see it again
6. This is your `SECRET_TOKEN`

### 4. Save Your Tokens

**IMPORTANT:** Keep these tokens secret! Don't commit them to Git.

You'll have:
- **Public Token:** `pk.eyJ1Ijoi...` (for maps)
- **Secret Token:** `sk.eyJ1Ijoi...` (for iOS downloads)

---

## Step 2: I'll Configure Your App

Once you have both tokens, **paste them here in the chat** and I'll:

1. ✅ Add them to Android configuration
2. ✅ Add them to iOS configuration
3. ✅ Set up environment variables
4. ✅ Configure Mapbox SDK properly

---

## Pricing Info (You're Safe)

**Your app will be well within free tier:**

| Service | Free Tier | Your Usage (estimated) |
|---------|-----------|------------------------|
| **Map Loads** | 50,000/month | ~5,000/month (100 drivers × 50 uses/month) |
| **Routing** | 100,000/month | Already using HERE (free) |
| **Directions** | 100,000/month | Already using HERE (free) |

You won't hit paid tier unless you have 1,000+ active drivers daily.

---

## Next Steps

1. **Get your tokens** (takes 2 minutes)
2. **Paste them in chat**
3. **I'll configure everything** (5 minutes)
4. **We continue building** 🚀

**Ready when you are!**
