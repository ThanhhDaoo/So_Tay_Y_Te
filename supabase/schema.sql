-- ==============================================================================
-- SCHEMA POSTGRESQL CHUẨN Y TẾ CHO SỔ TAY Y TẾ TRÊN SUPABASE (V3 - FULL SYNC)
-- Hỗ trợ: Supabase Auth, Row Level Security (RLS), Đa thành viên gia đình,
-- Soft Delete, Tra cứu mã STYT-XXXXXX an toàn qua RPC & Chia sẻ QR Bác sĩ
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
    height TEXT,
    weight TEXT,
    organ_donor TEXT DEFAULT 'CHƯA ĐĂNG KÝ',
    region TEXT,
    allergies TEXT DEFAULT 'Không có',
    chronic_conditions TEXT DEFAULT 'Không có',
    emergency_contact TEXT,
    avatar_url TEXT,
    is_pro BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Người dùng chỉ xem hồ sơ của chính mình" 
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Người dùng được khởi tạo hồ sơ của chính mình"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Người dùng chỉ cập nhật hồ sơ của chính mình" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- Hàm RPC tra cứu liên hệ đăng nhập từ mã STYT-XXXXXX trên thiết bị mới (an toàn dưới RLS)
CREATE OR REPLACE FUNCTION public.lookup_login_by_patient_code(p_code TEXT)
RETURNS TEXT AS $$
DECLARE
    resolved_contact TEXT;
BEGIN
    IF p_code IS NULL OR length(trim(p_code)) < 6 THEN
        RETURN NULL;
    END IF;
    SELECT COALESCE(NULLIF(phone, ''), NULLIF(email, ''))
    INTO resolved_contact
    FROM public.profiles
    WHERE UPPER(patient_code) = UPPER(trim(p_code))
    LIMIT 1;
    RETURN resolved_contact;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.lookup_login_by_patient_code(TEXT) TO anon, authenticated;

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
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'primary_contact'),
        NEW.raw_user_meta_data->>'avatar_url',
        NULLIF(NEW.raw_user_meta_data->>'date_of_birth', '')::DATE,
        COALESCE(NEW.raw_user_meta_data->>'gender', 'Chưa rõ'),
        COALESCE(NEW.raw_user_meta_data->>'blood_type', 'Chưa rõ')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Bảng Thành Viên Gia Đình (Family Members)
CREATE TABLE IF NOT EXISTS public.family_members (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    blood_type TEXT DEFAULT 'Chưa rõ',
    dob TEXT,
    gender TEXT DEFAULT 'Chưa rõ',
    phone TEXT,
    allergies TEXT,
    chronic_conditions TEXT,
    avatar_asset TEXT,
    height TEXT,
    weight TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chỉ chủ tài khoản mới quản lý thành viên gia đình"
ON public.family_members FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. Bảng Lịch Sử Khám Bệnh (Medical Events - Đồng bộ 1:1 với Mobile SQLite)
CREATE TABLE IF NOT EXISTS public.medical_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    member_id TEXT NOT NULL DEFAULT 'primary',
    title TEXT NOT NULL,
    description TEXT,
    facility_name TEXT,
    hospital TEXT,
    doctor_name TEXT,
    department TEXT,
    diagnosis TEXT,
    blood_pressure TEXT,
    heart_rate TEXT,
    spo2 TEXT,
    temperature TEXT,
    prescription_json JSONB,
    hospital_fee TEXT,
    event_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_type TEXT NOT NULL DEFAULT 'generalCheckup',
    attachments JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

ALTER TABLE public.medical_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chỉ chủ tài khoản mới được quản lý bệnh án" 
ON public.medical_events FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 5. Bảng Đơn Thuốc (Prescriptions)
CREATE TABLE IF NOT EXISTS public.prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.medical_events(id) ON DELETE SET NULL,
    doctor_name TEXT NOT NULL,
    hospital TEXT,
    issued_date TIMESTAMPTZ NOT NULL,
    duration_days INTEGER DEFAULT 7,
    status TEXT DEFAULT 'active',
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chỉ chủ tài khoản mới được xem và sửa đơn thuốc" 
ON public.prescriptions FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 6. Bảng Chi Tiết Thuốc Trong Đơn (Medicines)
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

-- 7. Bảng Kho Tài Liệu Độc Lập (Medical Documents)
CREATE TABLE IF NOT EXISTS public.medical_documents (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    member_id TEXT NOT NULL DEFAULT 'primary',
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    hospital TEXT,
    doc_date TEXT NOT NULL,
    summary JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.medical_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chỉ chủ tài khoản quản lý tài liệu y tế"
ON public.medical_documents FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 8. Bảng Token Chia Sẻ QR Tạm Thời Cho Bác Sĩ (Doctor Share Tokens)
CREATE TABLE IF NOT EXISTS public.doctor_share_tokens (
    token TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pin_hash TEXT NOT NULL,
    scopes TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.doctor_share_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chủ hồ sơ quản lý và thu hồi mã QR chia sẻ"
ON public.doctor_share_tokens FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 9. Storage Bucket cho Tài Liệu Y Tế & Kết Quả Xét Nghiệm
INSERT INTO storage.buckets (id, name, public) 
VALUES ('medical-documents', 'medical-documents', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Bảo vệ file y tế riêng tư cho từng người dùng"
ON storage.objects FOR ALL
USING (bucket_id = 'medical-documents' AND auth.uid()::TEXT = (storage.foldername(name))[1]);
