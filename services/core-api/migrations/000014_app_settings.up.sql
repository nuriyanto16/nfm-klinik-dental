CREATE TABLE IF NOT EXISTS app_settings (
    id VARCHAR(36) PRIMARY KEY,
    key_name VARCHAR(100) UNIQUE NOT NULL,
    value_data TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO app_settings (id, key_name, value_data, description) VALUES
    ('set-brand', 'brand_name', 'Nina Dental Care', 'Nama klinik yang ditampilkan di aplikasi dan web'),
    ('set-logo', 'logo_url', '', 'URL logo klinik'),
    ('set-phone', 'contact_phone', '', 'Nomor WhatsApp klinik')
ON CONFLICT (key_name) DO NOTHING;
