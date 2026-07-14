# db/seeds.rb

puts "🧹 Cleaning database..."
# delete_all bypasses Active Record callbacks to avoid the broken user.rb association crash!
UserScan.delete_all
ScanResult.delete_all
Document.delete_all
Scan.delete_all
Credit.delete_all
Token.delete_all
Order.delete_all
Offer.delete_all
User.delete_all

puts "🌱 Seeding users, credits, documents, and scans..."

# ==========================================
# 1. Create the User & Associate Credits
# ==========================================
# Added password because encrypted_password is null: false in your schema (Devise)
default_user = User.create!(
  email: "student@example.com",
  password: "password123",
  first_name: "Test",
  last_name: "Student"
)

# In your schema, credits is a separate table belonging to a user
user_credits = Credit.create!(
  user: default_user,
  credits_amount: 10 # Representing 100 tokens (10 tokens per credit)
)

puts "👤 Created user: #{default_user.email}"
puts "💰 Created #{user_credits.credits_amount} credits for #{default_user.email}."

# ==========================================
# 2. Safe Document Scan (Score: 2)
# ==========================================
safe_doc = Document.create!(
  title: "DuckDuckGo Privacy Policy",
  url: "https://duckduckgo.com/privacy",
  raw_text: "They do not collect or share personal information. They do not track user searches."
)

ScanResult.create!(
  document: safe_doc,
  score: 2,
  verdict: "Safe",
  description: "They respect user privacy. Our scanner detected zero tracking mechanisms, and they explicitly state they do not collect or sell your personal data."
)

# Connect the document scan to the user via Scan and UserScan
safe_scan = Scan.create!(
  site_name: "DuckDuckGo",
  url: "https://duckduckgo.com/privacy",
  risk_score: 2,
  full_report: "Safe: They respect user privacy..."
)

UserScan.create!(
  user: default_user,
  scan: safe_scan
)

# ==========================================
# 3. Caution Document Scan (Score: 5)
# ==========================================
caution_doc = Document.create!(
  title: "Standard Streaming Co.",
  url: "https://example.com/streaming/terms",
  raw_text: "Their membership automatically renews monthly. They share demographic data with partners."
)

ScanResult.create!(
  document: caution_doc,
  score: 5,
  verdict: "Caution",
  description: "Keep an eye on your wallet. They use automatic subscription renewals that require manual cancellation. They also share anonymized user data with external marketing partners."
)

caution_scan = Scan.create!(
  site_name: "Standard Streaming Co.",
  url: "https://example.com/streaming/terms",
  risk_score: 5,
  full_report: "Caution: Automatic renewals active..."
)

UserScan.create!(
  user: default_user,
  scan: caution_scan
)

# ==========================================
# 4. Danger Document Scan (Score: 9)
# ==========================================
danger_doc = Document.create!(
  title: "Shady Games Inc.",
  url: "https://example.com/shadygames/terms",
  raw_text: "They track precise background location. They sell browsing history. Users waive their right to sue."
)

ScanResult.create!(
  document: danger_doc,
  score: 9,
  verdict: "Danger",
  description: "Major privacy and legal risks! They track your location even when the app is closed, sell your history to advertisers, and strip away your right to join a class-action lawsuit."
)

danger_scan = Scan.create!(
  site_name: "Shady Games Inc.",
  url: "https://example.com/shadygames/terms",
  risk_score: 9,
  full_report: "Danger: Location tracking and waiver of rights..."
)

UserScan.create!(
  user: default_user,
  scan: danger_scan
)

# Using direct SQL count via the join table to avoid calling the broken association in user.rb
completed_scans_count = UserScan.where(user: default_user).count
puts "✅ Seeding complete! User has #{completed_scans_count} completed scans."
