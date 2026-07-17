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
              items: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    label: { type: "string" },
                    level: { type: "string", enum: %w[low medium high] },
                    finding: { type: "string" },
                    article: { type: %w[string null] },
                    quote: { type: %w[string null] }
                  },
                  required: %w[label level finding article quote],
                  additionalProperties: false
                }
              }
            },
            required: %w[name level items],
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
    - Each category has 1 to 4 sub-findings in `items`, ordered most severe
      first. Each item needs:
      - label: 2-4 word tag (e.g. "Data sharing", "Auto-renewal")
      - level: this specific item's severity — items within one category can
        have different levels (e.g. one "high" item and one "low" item both
        under data_sharing)
      - finding: one-sentence plain-language summary, under 20 words
      - article: the section/clause reference if the document has
        identifiable numbered sections or headings (e.g. "Section 14.2"),
        otherwise null — never invent a reference
      - quote: the exact verbatim phrase from the source text that supports
        the finding, otherwise null if nothing specific applies (e.g. a
        "low" item just noting a topic isn't addressed). NEVER paraphrase or
        invent a quote — it must be copied exactly from the document.
    - The category's own `level` is the highest severity among its items.
    - If a topic is not addressed at all, use a single item with level "low"
      stating it is not addressed, article null, quote null.
    - risk_score: 10 = very safe for the consumer, 1 = very risky. It must be
      consistent with the category levels (several "high" implies a low score).
    - Write the summary and findings in the same language as the document.
      Keep JSON keys, category/label names and levels in English as specified.
  PROMPT

  def initialize(content)
    @content = content.to_s.first(MAX_CONTENT_CHARS)
  end

  def call(&)
    return fake_report if ENV["OPENAI_API_KEY"].blank?

    chat = RubyLLM.chat(model: MODEL)
                  .with_temperature(0.2)
                  .with_schema(SCHEMA)
                  .with_instructions(INSTRUCTIONS)

    # =========================================================================
    # TURBO STREAMING REFACTOR
    # =========================================================================
    # If a block is passed (e.g. from an ActionJob/Turbo system), stream chunks
    # token-by-token directly out to the layout wrapper. Otherwise, run a
    # traditional synchronous ask request.
    if block_given?
      chat.stream("Analyze these Terms & Conditions:\n\n#{@content}", &)
    else
      chat.ask("Analyze these Terms & Conditions:\n\n#{@content}").content
    end
    # =========================================================================
  end

  private

  # Garde l'app fonctionnelle pour les coéquipiers sans clé API
  def fake_report
    {
      "summary" => "Fake report — set OPENAI_API_KEY in .env to get real analysis.",
      "risk_score" => rand(1..10),
      "categories" => [
        {
          "name" => "data_sharing", "level" => "high",
          "items" => [
            { "label" => "Third-party sharing", "level" => "high",
              "finding" => "Data shared with third parties.", "article" => nil,
              "quote" => "We may share your personal information with third-party partners." }
          ]
        },
        {
          "name" => "ai_training", "level" => "medium",
          "items" => [
            { "label" => "AI training", "level" => "medium",
              "finding" => "Content may be used to train AI models.", "article" => nil,
              "quote" => "Your submitted content may be used to train and improve our machine-learning models." }
          ]
        }
      ],
      "gdpr_flags" => ["Cross-border data transfer outside the EU"],
      "ai_act_flags" => []
    }
  end
end
