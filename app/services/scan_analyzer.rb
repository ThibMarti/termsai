class ScanAnalyzer
  FAKE_REPORT = {
    "summary" => "This document grants broad data sharing rights to third parties " \
                 "and uses ambiguous language around AI training and cancellation.",
    "categories" => [
      { "name" => "data_sharing", "level" => "high", "finding" => "Data resold to third-party ad partners." },
      { "name" => "ai_training", "level" => "medium", "finding" => "User content may be used to train AI models." }
    ],
    "gdpr_flags" => ["Cross-border data transfer outside the EU"],
    "ai_act_flags" => []
  }.freeze

  def initialize(content)
    @content = content
  end

  # TODO: replace this fake analysis with a real AI call
  def call
    FAKE_REPORT.merge("risk_score" => rand(1..10))
  end
end
