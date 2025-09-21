-- Set timezone for current session
SET TIMEZONE TO 'Asia/Kolkata';

-- Drop existing functions first (they might reference the table)
DROP FUNCTION IF EXISTS public.get_study_logs_by_date_range(DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.get_current_ist_time() CASCADE;
DROP FUNCTION IF EXISTS public.to_ist(TIMESTAMPTZ) CASCADE;

-- Drop existing view
DROP VIEW IF EXISTS public.study_log_ist CASCADE;

-- Drop existing table and all dependencies (CASCADE will remove policies, triggers, etc.)
DROP TABLE IF EXISTS public.study_log CASCADE;

-- Create the study_log table with optimized schema
CREATE TABLE public.study_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    topic TEXT,
    sub_topic TEXT,
    notes TEXT,
    duration INTEGER, -- NEW COLUMN: Duration in minutes
    reference_url TEXT, -- NEW COLUMN: Reference URL for direct access
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    -- These will now default to IST timezone
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- Create indexes for optimal query performance
CREATE INDEX idx_study_log_date ON public.study_log(date);
CREATE INDEX idx_study_log_topic ON public.study_log(topic);
CREATE INDEX idx_study_log_created_at ON public.study_log(created_at);
CREATE INDEX idx_study_log_date_created ON public.study_log(date, created_at);
CREATE INDEX idx_study_log_completed ON public.study_log(completed) WHERE completed = true;

-- Enable Row Level Security
ALTER TABLE public.study_log ENABLE ROW LEVEL SECURITY;

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

-- Create IST-aware function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Set updated_at to current IST time
    NEW.updated_at = NOW() AT TIME ZONE 'Asia/Kolkata';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic IST timestamp updates
CREATE TRIGGER trigger_study_log_updated_at
    BEFORE UPDATE ON public.study_log
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create the enhanced function for bulk date range queries with IST timezone
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
    duration INTEGER, -- NEW COLUMN: Include duration in function
    reference_url TEXT, -- NEW COLUMN: Include reference_url in function
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
        sl.duration, -- NEW COLUMN: Return duration
        sl.reference_url, -- NEW COLUMN: Return reference_url
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

-- Create a view that automatically shows IST timestamps
CREATE OR REPLACE VIEW public.study_log_ist AS
SELECT 
    id,
    date,
    topic,
    sub_topic,
    notes,
    duration, -- NEW COLUMN: Include duration in view
    reference_url, -- NEW COLUMN: Include reference_url in view
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

-- Grant permissions to anonymous users
GRANT ALL ON public.study_log TO anon;
GRANT EXECUTE ON FUNCTION public.get_study_logs_by_date_range TO anon;
GRANT EXECUTE ON FUNCTION public.get_current_ist_time TO anon;
GRANT EXECUTE ON FUNCTION public.to_ist TO anon;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.study_log TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_study_logs_by_date_range TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_ist_time TO authenticated;
GRANT EXECUTE ON FUNCTION public.to_ist TO authenticated;

-- Grant access to the IST view
GRANT SELECT ON public.study_log_ist TO authenticated;
GRANT SELECT ON public.study_log_ist TO anon;

-- Verify timezone settings
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

-- Show empty table (should display column structure including new duration and reference_url columns)
SELECT * FROM study_log;
TRUNCATE TABLE study_log;