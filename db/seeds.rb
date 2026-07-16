# db/seeds.rb

puts "🧹 Cleaning database..."
UserScan.destroy_all
Scan.destroy_all
Token.destroy_all
Order.destroy_all
Offer.destroy_all
User.destroy_all

puts "🌱 Seeding users, offers, and scans..."

# ==========================================
# 1. Create the User
# ==========================================
# User.create! also grants 1 free token via the after_create callback.
default_user = User.create!(
  email: "student@example.com",
  password: "password123",
  first_name: "Test",
  last_name: "Student"
)

puts "👤 Created user: #{default_user.email}"
puts "🪙 Starting token balance: #{default_user.total_scan_allowance}."

# ==========================================
# 2. Offers (token packs)
# ==========================================
Offer.create!(name: "Starter Pack", tokens_amount: 10, price_cents: 500)
Offer.create!(name: "Pro Pack", tokens_amount: 50, price_cents: 2000)

puts "📦 Created offers."

# ==========================================
# 3. Scans, matching the full_report JSON contract
# ==========================================
def seed_scan(user:, site_name:, url:, content:, risk_score:, summary:, categories:, gdpr_flags: [], ai_act_flags: [])
  scan = Scan.create!(
    site_name: site_name,
    url: url,
    content: content,
    risk_score: risk_score,
    full_report: {
      "summary" => summary,
      "risk_score" => risk_score,
      "categories" => categories,
      "gdpr_flags" => gdpr_flags,
      "ai_act_flags" => ai_act_flags
    }
  )
  UserScan.create!(user: user, scan: scan)
  scan
end

seed_scan(
  user: default_user,
  site_name: "DuckDuckGo",
  url: "https://duckduckgo.com/privacy",
  content: "They do not collect or share personal information. They do not track user searches.",
  risk_score: 9,
  summary: "They respect user privacy. Our scanner detected zero tracking mechanisms, and they explicitly state they do not collect or sell your personal data.",
  categories: [
    { "name" => "data_sharing", "level" => "low", "items" => [
      { "label" => "No sharing", "level" => "low", "finding" => "No personal data shared with third parties.",
        "article" => nil, "quote" => "They do not collect or share personal information." }
    ] },
    { "name" => "tracking", "level" => "low", "items" => [
      { "label" => "No tracking", "level" => "low", "finding" => "No user tracking detected.",
        "article" => nil, "quote" => "They do not track user searches." }
    ] }
  ]
)

seed_scan(
  user: default_user,
  site_name: "Standard Streaming Co.",
  url: "https://example.com/streaming/terms",
  content: "Their membership automatically renews monthly. They share demographic data with partners.",
  risk_score: 5,
  summary: "Keep an eye on your wallet. They use automatic subscription renewals that require manual cancellation. They also share anonymized user data with external marketing partners.",
  categories: [
    { "name" => "data_sharing", "level" => "medium", "items" => [
      { "label" => "Partner sharing", "level" => "medium", "finding" => "Anonymized demographic data shared with partners.",
        "article" => nil, "quote" => "They share demographic data with partners." }
    ] },
    { "name" => "cancellation", "level" => "medium", "items" => [
      { "label" => "Auto-renewal", "level" => "medium", "finding" => "Auto-renews monthly; cancellation requires manual action.",
        "article" => nil, "quote" => "Their membership automatically renews monthly." }
    ] }
  ]
)

seed_scan(
  user: default_user,
  site_name: "Shady Games Inc.",
  url: "https://example.com/shadygames/terms",
  content: "They track precise background location. They sell browsing history. Users waive their right to sue.",
  risk_score: 2,
  summary: "Major privacy and legal risks! They track your location even when the app is closed, sell your history to advertisers, and strip away your right to join a class-action lawsuit.",
  categories: [
    { "name" => "data_sharing", "level" => "high", "items" => [
      { "label" => "Selling data", "level" => "high", "finding" => "Browsing history sold to advertisers.",
        "article" => nil, "quote" => "They sell browsing history." }
    ] },
    { "name" => "tracking", "level" => "high", "items" => [
      { "label" => "Location tracking", "level" => "high", "finding" => "Precise background location tracking.",
        "article" => nil, "quote" => "They track precise background location." }
    ] },
    { "name" => "cancellation", "level" => "high", "items" => [
      { "label" => "Rights waived", "level" => "high", "finding" => "Users waive the right to join a class-action lawsuit.",
        "article" => nil, "quote" => "Users waive their right to sue." }
    ] }
  ],
  gdpr_flags: ["Cross-border data transfer outside the EU"]
)

puts "✅ Seeding complete! User has #{default_user.scans.count} scans."
