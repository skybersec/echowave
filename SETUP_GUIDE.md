# EchoWave Setup Guide

This guide will help you set up EchoWave from scratch, including the Supabase backend, environment variables, and getting everything running.

## 🚀 Quick Start

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create a free account
2. Create a new project:
   - Choose a project name (e.g., "EchoWave")
   - Choose a strong database password
   - Select a region close to your users
3. Wait for the project to be provisioned (2-3 minutes)

### Step 2: Set Up Database Schema

1. In your Supabase dashboard, go to the **SQL Editor**
2. Copy the entire contents of `web/supabase-schema.sql`
3. Paste it into the SQL editor and click **Run**
4. This will create all tables, functions, policies, and insert sample templates

### Step 3: Configure Environment Variables

1. In your Supabase dashboard, go to **Settings > API**
2. Copy your project URL and anon key
3. Create a `.env.local` file in the `web/` directory:

```bash
# In web/.env.local
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Optional: For AI insights (add later)
OPENAI_API_KEY=your-openai-api-key

# Optional: For payments (add later)
STRIPE_SECRET_KEY=your-stripe-secret-key
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key

# App Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### Step 4: Enable Row Level Security Policies

The SQL schema already includes RLS policies, but verify they're working:

1. Go to **Authentication > Policies** in Supabase
2. You should see policies for `profiles`, `surveys`, `responses`, `templates`, and `insights`
3. All should be enabled by default

### Step 5: Configure Authentication

1. In Supabase dashboard, go to **Authentication > Settings**
2. Under **Site URL**, add: `http://localhost:3000`
3. Under **Redirect URLs**, add: `http://localhost:3000/auth/callback`
4. (Optional) Enable social providers like Google, GitHub, etc.

### Step 6: Run the Application

```bash
cd web
npm install  # (already done)
npm run dev
```

Your app should now be running at `http://localhost:3000`!

---

## 🧪 Testing the Setup

### Test 1: User Registration
1. Go to `http://localhost:3000`
2. Complete the onboarding flow
3. Click "Get Started" and create an account
4. Verify you can log in and see the dashboard

### Test 2: Create a Survey
1. Go to the "Create" tab
2. Select a template (e.g., "Individual Feedback")
3. Fill out the survey details and save
4. Verify the survey appears in your "Surveys" list

### Test 3: Publish and Share Survey
1. In your surveys list, click the "..." menu on a survey
2. Click "Publish"
3. The survey should now be "Live"
4. Copy the survey ID from the URL or database
5. Go to `http://localhost:3000/s/[survey-id]` to test the public form

### Test 4: Submit Response
1. Fill out the public survey form
2. Submit the response
3. Check that the response count increased in your dashboard
4. Try to view responses (should be blocked until 10+ responses)

---

## 🛠 Development Tools

### Database Management
- **Supabase Dashboard**: `https://app.supabase.com/project/[your-project-id]`
- **Table Editor**: View and edit data directly
- **SQL Editor**: Run custom queries
- **Logs**: View real-time logs and errors

### Useful SQL Queries

```sql
-- View all surveys
SELECT id, title, status, response_count, min_responses FROM surveys;

-- View all responses for a survey
SELECT * FROM responses WHERE survey_id = 'your-survey-id';

-- Check user profiles
SELECT * FROM profiles;

-- View survey analytics
SELECT * FROM survey_analytics;
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Unauthorized" errors
- Check that your environment variables are correct
- Verify RLS policies are enabled
- Make sure you're logged in

#### 2. Survey not found
- Check that the survey is published (`status = 'published'`)
- Verify `is_active = true`
- Check the survey ID is correct

#### 3. Can't view responses
- Ensure the survey has reached `min_responses` threshold
- Verify you own the survey
- Check RLS policies on responses table

#### 4. Database connection issues
- Verify your Supabase project is active
- Check environment variables are loaded
- Look at browser network tab for API errors

### Environment Variables Not Loading?

Make sure your `.env.local` file is in the `web/` directory and restart your dev server:

```bash
cd web
npm run dev
```

### Database Schema Issues?

If you need to reset the database:

1. Go to **Settings > General > Danger Zone**
2. Click "Reset database"
3. Re-run the `supabase-schema.sql` script

---

## 🚀 Next Steps

Once everything is working:

1. **Add Sample Data**: Create a few test surveys and responses
2. **Test Mobile**: Check responsive design on mobile devices
3. **Configure Analytics**: Set up monitoring and error tracking
4. **Add AI Integration**: Configure OpenAI for insights
5. **Set Up Payments**: Integrate Stripe for monetization

### Production Deployment

When ready to deploy:

1. **Update Environment Variables**: Add production URLs
2. **Configure Supabase**: Update redirect URLs for production
3. **Deploy to Vercel**: Connect your GitHub repo
4. **Set up Custom Domain**: Configure DNS settings
5. **Enable HTTPS**: Ensure all traffic is encrypted

---

## 📚 Resources

### Documentation
- [Supabase Docs](https://supabase.com/docs)
- [Next.js Docs](https://nextjs.org/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)

### Supabase Specific
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Database Functions](https://supabase.com/docs/guides/database/functions)
- [Realtime](https://supabase.com/docs/guides/realtime)

---

## 🆘 Getting Help

If you run into issues:

1. Check the browser console for errors
2. Look at Supabase logs in the dashboard
3. Review the database policies and permissions
4. Test API endpoints with a tool like Postman

The setup should take about 15-30 minutes total. Most of that time is waiting for Supabase to provision and running the database schema.

**Ready to build the next viral feedback platform? Let's go! 🎉** 