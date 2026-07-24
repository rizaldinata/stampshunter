import os
from supabase import create_client
from dotenv import load_dotenv

# Load env file
load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_ANON_KEY")

print(f"Supabase URL: {supabase_url}")
print(f"Supabase Key: {supabase_key[:10]}..." if supabase_key else "None")

if not supabase_url or "your-project-id" in supabase_url:
    print("Error: Supabase URL belum diatur dengan benar.")
    exit(1)

try:
    client = create_client(supabase_url, supabase_key)
    # Test connection by listing buckets
    buckets = client.storage.list_buckets()
    print("\n[OK] Koneksi berhasil!")
    print(f"Daftar Bucket yang ditemukan: {[b.name for b in buckets]}")
except Exception as e:
    print(f"\n[ERROR] Koneksi gagal: {e}")
    exit(1)
