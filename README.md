# habit-of-learning

it's for track the daily learning habits and closely monitoring where I'm on each topics

# Supbase SQL Details

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own study logs" ON public.study_log;
DROP POLICY IF EXISTS "Users can insert their own study logs" ON public.study_log;
DROP POLICY IF EXISTS "Users can update their own study logs" ON public.study_log;
DROP POLICY IF EXISTS "Users can delete their own study logs" ON public.study_log;

-- Create new policies that allow anonymous access
CREATE POLICY "Allow anonymous SELECT on study_log" ON public.study_log
    FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Allow anonymous INSERT on study_log" ON public.study_log
    FOR INSERT
    TO anon
    WITH CHECK (true);

CREATE POLICY "Allow anonymous UPDATE on study_log" ON public.study_log
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow anonymous DELETE on study_log" ON public.study_log
    FOR DELETE
    TO anon
    USING (true);

-- Also allow authenticated users (if you plan to add authentication later)
CREATE POLICY "Allow authenticated SELECT on study_log" ON public.study_log
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated INSERT on study_log" ON public.study_log
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated UPDATE on study_log" ON public.study_log
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow authenticated DELETE on study_log" ON public.study_log
    FOR DELETE
    TO authenticated
    USING (true);

-- Grant permissions to anonymous users
GRANT ALL ON public.study_log TO anon;
GRANT EXECUTE ON FUNCTION public.get_study_logs_by_date_range TO anon;
GRANT EXECUTE ON FUNCTION public.get_current_ist_time TO anon;
GRANT EXECUTE ON FUNCTION public.to_ist TO anon;


-- First, check current timezone (should show UTC by default)
SHOW TIMEZONE;

-- Set the database timezone to IST (Asia/Kolkata)
-- Note: Supabase recommends keeping UTC, but we can override for IST
-- ALTER DATABASE postgres SET TIMEZONE TO 'Asia/Kolkata';

-- Alternative: Set timezone for current session only
SET TIMEZONE TO 'Asia/Kolkata';

-- Create the study_log table with optimized schema (only if not exists)
CREATE TABLE IF NOT EXISTS public.study_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    topic TEXT,
    sub_topic TEXT,
    notes TEXT,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    -- These will now default to IST timezone
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- Create indexes for optimal query performance
CREATE INDEX IF NOT EXISTS idx_study_log_date ON public.study_log(date);
CREATE INDEX IF NOT EXISTS idx_study_log_topic ON public.study_log(topic);
CREATE INDEX IF NOT EXISTS idx_study_log_created_at ON public.study_log(created_at);
CREATE INDEX IF NOT EXISTS idx_study_log_date_created ON public.study_log(date, created_at);
CREATE INDEX IF NOT EXISTS idx_study_log_completed ON public.study_log(completed) WHERE completed = true;

-- Enable Row Level Security
ALTER TABLE public.study_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for authenticated users (only create if they don't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'study_log' 
        AND policyname = 'Users can view their own study logs'
    ) THEN
        CREATE POLICY "Users can view their own study logs" ON public.study_log
            FOR SELECT 
            TO authenticated
            USING (auth.uid() IS NOT NULL);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'study_log' 
        AND policyname = 'Users can insert their own study logs'
    ) THEN
        CREATE POLICY "Users can insert their own study logs" ON public.study_log
            FOR INSERT 
            TO authenticated
            WITH CHECK (auth.uid() IS NOT NULL);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'study_log' 
        AND policyname = 'Users can update their own study logs'
    ) THEN
        CREATE POLICY "Users can update their own study logs" ON public.study_log
            FOR UPDATE 
            TO authenticated
            USING (auth.uid() IS NOT NULL)
            WITH CHECK (auth.uid() IS NOT NULL);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'study_log' 
        AND policyname = 'Users can delete their own study logs'
    ) THEN
        CREATE POLICY "Users can delete their own study logs" ON public.study_log
            FOR DELETE 
            TO authenticated
            USING (auth.uid() IS NOT NULL);
    END IF;
END $$;

-- Drop existing trigger function if it exists and recreate with IST support
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

-- Create IST-aware function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Set updated_at to current IST time
    NEW.updated_at = NOW() AT TIME ZONE 'Asia/Kolkata';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger for automatic IST timestamp updates
DROP TRIGGER IF EXISTS trigger_study_log_updated_at ON public.study_log;
CREATE TRIGGER trigger_study_log_updated_at
    BEFORE UPDATE ON public.study_log
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Drop the existing function with the old signature
DROP FUNCTION IF EXISTS public.get_study_logs_by_date_range(DATE, DATE);

-- Create the new enhanced function for bulk date range queries with IST timezone
CREATE OR REPLACE FUNCTION public.get_study_logs_by_date_range(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE(
    id UUID,
    date DATE,
    topic TEXT,
    sub_topic TEXT,
    notes TEXT,
    completed BOOLEAN,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    created_at_ist TEXT,
    updated_at_ist TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sl.id,
        sl.date,
        sl.topic,
        sl.sub_topic,
        sl.notes,
        sl.completed,
        sl.completed_at,
        sl.created_at,
        sl.updated_at,
        -- Convert to IST for display
        to_char(sl.created_at AT TIME ZONE 'Asia/Kolkata', 'DD-Mon-YYYY HH12:MI:SS AM') as created_at_ist,
        to_char(sl.updated_at AT TIME ZONE 'Asia/Kolkata', 'DD-Mon-YYYY HH12:MI:SS AM') as updated_at_ist
    FROM public.study_log sl
    WHERE sl.date >= start_date 
      AND sl.date <= end_date
    ORDER BY sl.date ASC, sl.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current IST time
CREATE OR REPLACE FUNCTION public.get_current_ist_time()
RETURNS TIMESTAMPTZ AS $$
BEGIN
    RETURN NOW() AT TIME ZONE 'Asia/Kolkata';
END;
$$ LANGUAGE plpgsql;

-- Function to convert any timestamp to IST
CREATE OR REPLACE FUNCTION public.to_ist(input_timestamp TIMESTAMPTZ)
RETURNS TEXT AS $$
BEGIN
    RETURN to_char(input_timestamp AT TIME ZONE 'Asia/Kolkata', 'DD-Mon-YYYY HH12:MI:SS AM');
END;
$$ LANGUAGE plpgsql;

-- Verify timezone settings
-- Run these queries to check the configuration:

-- 1. Check current database timezone
SELECT current_setting('TIMEZONE') as current_timezone;

-- 2. Check if Asia/Kolkata is available
SELECT name, abbrev, utc_offset, is_dst 
FROM pg_timezone_names() 
WHERE name = 'Asia/Kolkata';

-- 3. Test IST time functions
SELECT 
    NOW() as utc_time,
    NOW() AT TIME ZONE 'Asia/Kolkata' as ist_time,
    public.get_current_ist_time() as function_ist_time;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.study_log TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_study_logs_by_date_range TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_ist_time TO authenticated;
GRANT EXECUTE ON FUNCTION public.to_ist TO authenticated;

-- Drop existing IST view if it exists and recreate
DROP VIEW IF EXISTS public.study_log_ist;

-- Create a view that automatically shows IST timestamps
CREATE OR REPLACE VIEW public.study_log_ist AS
SELECT 
    id,
    date,
    topic,
    sub_topic,
    notes,
    completed,
    completed_at,
    created_at,
    updated_at,
    -- IST formatted timestamps
    to_char(created_at AT TIME ZONE 'Asia/Kolkata', 'DD-MM-YYYY HH24:MI:SS') as created_at_ist,
    to_char(updated_at AT TIME ZONE 'Asia/Kolkata', 'DD-MM-YYYY HH24:MI:SS') as updated_at_ist,
    -- IST date parts
    extract(hour from created_at AT TIME ZONE 'Asia/Kolkata') as created_hour_ist,
    extract(minute from created_at AT TIME ZONE 'Asia/Kolkata') as created_minute_ist
FROM public.study_log;

-- Grant access to the IST view
GRANT SELECT ON public.study_log_ist TO authenticated;

-- Test query to verify IST timestamps work correctly
SELECT 
    'Testing IST Configuration' as test_name,
    NOW() as current_utc,
    NOW() AT TIME ZONE 'Asia/Kolkata' as current_ist,
    current_setting('TIMEZONE') as current_timezone_setting;

-- Show existing data with IST conversion (if any exists)
SELECT 
    topic,
    sub_topic,
    created_at,
    created_at AT TIME ZONE 'Asia/Kolkata' as created_at_ist,
    updated_at AT TIME ZONE 'Asia/Kolkata' as updated_at_ist
FROM public.study_log 
ORDER BY created_at DESC 
LIMIT 5;

select * from study_log;