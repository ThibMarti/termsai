require "net/http"
require "json"

# Fetches news for 3 categories (data breach / AI advancement / data policy),
# then asks an LLM to drop keyword-search noise (NewsAPI's search is a plain
# OR match, so "data breach OR data leak" also pulls in unrelated "leak"
# stories). `call` returns one featured tile per category for the Home page's
# teaser grid; `call_by_category` returns everything fetched, grouped, for
# the full News page. Both share the same cached fetch — NewsAPI requests and
# the relevance pass only happen once per CACHE_TTL window, not per page load.
class NewsFeedFetcher
  CACHE_KEY = "news_feed_articles"
  CACHE_TTL = 3.hours
  ARTICLES_PER_CATEGORY = 10 # a wider candidate pool for the relevance pass to pick from
  REQUEST_TIMEOUT = 5 # seconds — keeps a NewsAPI outage from stalling the dashboard
  RELEVANCE_MODEL = "gpt-4o-mini".freeze

  QUERIES = {
    data_breach: "data breach OR data leak",
    ai_advancement: "artificial intelligence breakthrough",
    data_policy: "data privacy policy OR GDPR"
  }.freeze

  CATEGORY_TOPICS = {
    data_breach: "a genuine cybersecurity incident, data breach, or data leak affecting " \
                 "real user/company data — not unrelated uses of \"breach\" or \"leak\" " \
                 "(e.g. water leaks, leaked photos/rumors unrelated to data security).",
    ai_advancement: "a genuine advancement, breakthrough, product launch, or major " \
                    "announcement in AI technology or research — not just any article " \
                    "that mentions \"AI\" in passing.",
    data_policy: "genuine data privacy/protection policy or regulatory news (e.g. GDPR, " \
                 "data protection law) — not unrelated \"policy\" news (foreign policy, " \
                 "economic policy, etc)."
  }.freeze

  RELEVANCE_SCHEMA = {
    name: "NewsRelevanceSchema",
    schema: {
      type: "object",
      properties: QUERIES.keys.to_h { |c| [c, { type: "array", items: { type: "integer" } }] },
      required: QUERIES.keys.map(&:to_s),
      additionalProperties: false
    }
  }.freeze

  RELEVANCE_INSTRUCTIONS = <<~PROMPT.freeze
    You are filtering news search results for topical relevance, one list per
    category. Each category gives you a numbered "title — description" list
    pulled from a keyword search that often includes irrelevant matches.

    Categories:
    #{QUERIES.keys.map { |c| "- #{c}: #{CATEGORY_TOPICS[c]}" }.join("\n")}

    For each category, return the 0-based indices of the articles that are
    genuinely on-topic, ordered most relevant first. Omit indices for articles
    that only superficially match the search keywords.
  PROMPT

  # Keeps the dashboard usable for teammates without an API key
  SAMPLE_ARTICLES_BY_CATEGORY = {
    data_breach: [{ category: :data_breach, title: "Sample story — set NEWS_API_KEY in .env for live news",
                    source: "terms AI", url: "https://newsapi.org", published_at: Time.current,
                    description: nil, image_url: nil }],
    ai_advancement: [{ category: :ai_advancement, title: "Sample story — set NEWS_API_KEY in .env for live news",
                       source: "terms AI", url: "https://newsapi.org", published_at: 1.hour.ago,
                       description: nil, image_url: nil }],
    data_policy: [{ category: :data_policy, title: "Sample story — set NEWS_API_KEY in .env for live news",
                    source: "terms AI", url: "https://newsapi.org", published_at: 2.hours.ago,
                    description: nil, image_url: nil }]
  }.freeze

  # One tile per category, preferring an article that actually has an image;
  # a category that failed entirely just contributes no tile.
  def call
    by_category.filter_map do |_category, articles|
      articles.find { |article| article[:image_url].present? } || articles.first
    end
  end

  # Everything fetched, grouped by category — { category => [article, ...] }.
  def call_by_category
    by_category
  end

  private

  def by_category
    return SAMPLE_ARTICLES_BY_CATEGORY if ENV["NEWS_API_KEY"].blank?

    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL, race_condition_ttl: 30.seconds) { fetch_all_categories }
  end

  def fetch_all_categories
    raw = QUERIES.to_h { |category, query| [category, fetch_category(category, query)] }
    filter_relevant(raw)
  end

  # One category failing (timeout, bad response, rate limit) shouldn't blank
  # out the other two — rescue per-request, not around the whole fetch.
  def fetch_category(category, query)
    response = request_articles(build_uri(query))
    return [] unless successful?(category, response)

    (JSON.parse(response.body)["articles"] || []).map { |article| build_article(category, article) }
  rescue StandardError => e
    Rails.logger.error("NewsFeedFetcher: #{category} failed — #{e.class}: #{e.message}")
    []
  end

  # Drops keyword-search noise via one LLM call covering all 3 categories.
  # No OPENAI_API_KEY, or the call itself failing, just falls back to the
  # unfiltered NewsAPI results rather than breaking the feed.
  def filter_relevant(raw_by_category)
    return raw_by_category if ENV["OPENAI_API_KEY"].blank?

    relevant_indices = ask_relevance(raw_by_category)
    raw_by_category.to_h do |category, articles|
      picked = Array(relevant_indices[category.to_s]).filter_map { |i| articles[i] }
      [category, picked.presence || articles]
    end
  rescue StandardError => e
    Rails.logger.error("NewsFeedFetcher: relevance filter failed — #{e.class}: #{e.message}")
    raw_by_category
  end

  def ask_relevance(raw_by_category)
    chat = RubyLLM.chat(model: RELEVANCE_MODEL)
                  .with_temperature(0.0)
                  .with_schema(RELEVANCE_SCHEMA)
                  .with_instructions(RELEVANCE_INSTRUCTIONS)
    chat.ask(relevance_prompt(raw_by_category)).content
  end

  def relevance_prompt(raw_by_category)
    raw_by_category.map do |category, articles|
      listing = articles.each_with_index.map { |a, i| "#{i}. #{a[:title]} — #{a[:description]}" }.join("\n")
      "### #{category}\n#{listing}"
    end.join("\n\n")
  end

  def request_articles(uri)
    Net::HTTP.start(
      uri.host, uri.port,
      use_ssl: true, open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT
    ) { |http| http.get(uri) }
  end

  def successful?(category, response)
    return true if response.is_a?(Net::HTTPSuccess)

    Rails.logger.error("NewsFeedFetcher: #{category} request failed — HTTP #{response.code}")
    false
  end

  def build_uri(query)
    uri = URI("https://newsapi.org/v2/everything")
    uri.query = URI.encode_www_form(
      q: query,
      language: "en",
      sortBy: "publishedAt",
      pageSize: ARTICLES_PER_CATEGORY,
      apiKey: ENV.fetch("NEWS_API_KEY", nil)
    )
    uri
  end

  def build_article(category, article)
    {
      category: category,
      title: article["title"],
      source: article.dig("source", "name"),
      url: article["url"],
      published_at: parse_time(article["publishedAt"]),
      description: article["description"],
      image_url: article["urlToImage"]
    }
  end

  def parse_time(value)
    return Time.current if value.blank?

    Time.zone.parse(value.to_s) || Time.current
  rescue ArgumentError, TypeError
    Time.current
  end
end
