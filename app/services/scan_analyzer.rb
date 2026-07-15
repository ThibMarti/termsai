class ScanAnalyzer
  MODEL = "gpt-4o-mini".freeze
  MAX_CONTENT_CHARS = 40_000 # limite la latence (timeout Heroku 30 s) et le coût

  SCHEMA = {
    name: "TermsReportSchema",
    schema: {
      type: "object",
      properties: {
        summary: { type: "string" },
        risk_score: { type: "integer", minimum: 1, maximum: 10 },
        categories: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string", enum: %w[data_sharing ai_training tracking cancellation] },
              level: { type: "string", enum: %w[low medium high] },
              finding: { type: "string" }
            },
            required: %w[name level finding],
            additionalProperties: false
          }
        },
        gdpr_flags: { type: "array", items: { type: "string" } },
        ai_act_flags: { type: "array", items: { type: "string" } }
      },
      required: %w[summary risk_score categories gdpr_flags ai_act_flags],
      additionalProperties: false
    }
  }.freeze

  INSTRUCTIONS = <<~PROMPT.freeze
    You are TermsAI, a legal analyst specialized in consumer protection,
    GDPR and the EU AI Act. You analyze Terms & Conditions from the point
    of view of an ordinary EU consumer.

    Rules:
    - Always include exactly these 4 categories: data_sharing, ai_training,
      tracking, cancellation, summary, gdpr_flags, ai_act_flags
    - Base every finding on the actual text. Never invent clauses.
    - If a topic is not addressed, use level "low" and state it is not addressed.
    - risk_score: 10 = very safe for the consumer, 1 = very risky. It must be
      consistent with the category levels (several "high" implies a low score).
    - Keep each finding under 20 words.
    - Write the summary and findings in the same language as the document.
      Keep JSON keys, category names and levels in English as specified.
  PROMPT

  def initialize(content)
    @content = content.to_s.first(MAX_CONTENT_CHARS)
  end

  def call
    return fake_report if ENV["OPENAI_API_KEY"].blank?

    chat = RubyLLM.chat(model: MODEL)
                  .with_temperature(0.2)
                  .with_schema(SCHEMA)
                  .with_instructions(INSTRUCTIONS)
    chat.ask("Analyze these Terms & Conditions:\n\n#{@content}").content
  end

  private

  # Garde l'app fonctionnelle pour les coéquipiers sans clé API
  def fake_report
    {
      "summary" => "Fake report — set OPENAI_API_KEY in .env to get real analysis.",
      "risk_score" => rand(1..10),
      "categories" => [
        { "name" => "data_sharing", "level" => "high", "finding" => "Data shared with third parties." },
        { "name" => "ai_training", "level" => "medium", "finding" => "Content may be used to train AI models." }
      ],
      "gdpr_flags" => ["Cross-border data transfer outside the EU"],
      "ai_act_flags" => []
    }
  end
end
