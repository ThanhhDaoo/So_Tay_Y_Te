-- ==============================================================================
-- SCHEMA POSTGRESQL CHUẨN Y TẾ CHO SỔ TAY Y TẾ TRÊN SUPABASE (OPTION A)
-- Hỗ trợ: Supabase Auth, Row Level Security (RLS), Tự động sinh mã STYT-XXXXXX
-- ==============================================================================

-- 1. Hàm tự động sinh mã hồ sơ bệnh nhân STYT-XXXXXX (6 số ngẫu nhiên)
CREATE OR REPLACE FUNCTION generate_unique_patient_code() 
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        new_code := 'STYT-' || floor(random() * (999999 - 100000 + 1) + 100000)::TEXT;
        SELECT EXISTS(SELECT 1 FROM public.profiles WHERE patient_code = new_code) INTO code_exists;
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- 2. Bảng Hồ Sơ Người Dùng (Liên kết chặt chẽ với auth.users của Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    patient_code TEXT UNIQUE NOT NULL DEFAULT generate_unique_patient_code(),
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    date_of_birth DATE,
    gender TEXT DEFAULT 'Chưa rõ',
    blood_type TEXT DEFAULT 'Chưa rõ',
    allergies TEXT DEFAULT 'Không có',
    chronic_conditions TEXT DEFAULT 'Không có',
    emergency_contact TEXT,
    avatar_url TEXT,
    is_pro BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Kích hoạt RLS cho profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Người dùng chỉ xem hồ sơ của chính mình" 
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Người dùng chỉ cập nhật hồ sơ của chính mình" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- Trigger tự động tạo hồ sơ khi người dùng đăng ký qua Email/Google/Apple
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        full_name, 
        email, 
        phone, 
        avatar_url,
        date_of_birth,
        gender,
        blood_type
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'Bệnh nhân mới'),
        NEW.email,
        NEW.phone,
        NEW.raw_user_meta_data->>'avatar_url',
        (NEW.raw_user_meta_data->>'date_of_birth')::DATE,
        COALESCE(NEW.raw_user_meta_data->>'gender', 'Chưa rõ'),
        COALESCE(NEW.raw_user_meta_data->>'blood_type', 'Chưa rõ')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Bảng Lịch Sử Khám Bệnh (Medical Events)
CREATE TABLE IF NOT EXISTS public.medical_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    hospital TEXT,
    doctor_name TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    event_type TEXT NOT NULL,
    attachments JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.medical_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chỉ chủ tài khoản mới được quản lý bệnh án" 
ON public.medical_events FOR ALL 
USING (auth.uid() = user_id);

-- 4. Bảng Đơn Thuốc (Prescriptions)
CREATE TABLE IF NOT EXISTS public.prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.medical_events(id) ON DELETE SET NULL,
    doctor_name TEXT NOT NULL,
    hospital TEXT,
    issued_date TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'active',
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chỉ chủ tài khoản mới được xem và sửa đơn thuốc" 
ON public.prescriptions FOR ALL 
USING (auth.uid() = user_id);

-- 5. Bảng Chi Tiết Thuốc Trong Đơn (Medicines)
CREATE TABLE IF NOT EXISTS public.medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES public.prescriptions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    instructions TEXT,
    is_taken BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chủ sở hữu đơn thuốc được quản lý chi tiết thuốc" 
ON public.medicines FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM public.prescriptions p
        WHERE p.id = medicines.prescription_id AND p.user_id = auth.uid()
    )
);

-- 6. Storage Bucket cho Tài Liệu Y Tế & Kết Quả Xét Nghiệm
INSERT INTO storage.buckets (id, name, public) 
VALUES ('medical-documents', 'medical-documents', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Bảo vệ file y tế riêng tư cho từng người dùng"
ON storage.objects FOR ALL
USING (bucket_id = 'medical-documents' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

