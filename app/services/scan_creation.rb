# Shared by ScansController (HTML) and Api::ScansController (JSON) so the
# find-by-url dedup, the can_scan? gate, the ScanAnalyzer call + save, and
# token consumption live in exactly one place.
class ScanCreation
  Result = Struct.new(:status, :scan, :message, keyword_init: true)
  # status is one of: :created, :reused, :blocked, :invalid

  def initialize(user:, scan_params:, authorizer:)
    @user = user
    @scan_params = scan_params
    @authorizer = authorizer
  end

  def call
    existing_scan = Scan.find_by(url: @scan_params[:url])
    return reuse(existing_scan) if existing_scan

    scan = Scan.new(@scan_params)
    @authorizer.call(scan)

    return Result.new(status: :blocked, message: "No tokens left.") unless @user.can_scan?

    create_and_analyze(scan)
  end

  private

  # This site was already scanned (by anyone) — reuse the existing report
  # instead of burning the user's token on a duplicate AI call.
  def reuse(scan)
    @authorizer.call(scan)
    @user.user_scans.find_or_create_by!(scan: scan)
    Result.new(status: :reused, scan: scan)
  end

  def create_and_analyze(scan)
    scan.status = "processing" if scan.respond_to?(:status=)

    if scan.save
      register_user_scan(scan)
      ScanAnalysisJob.perform_later(scan)
      Result.new(status: :created, scan: scan)
    else
      Result.new(status: :invalid, scan: scan, message: scan.errors.full_messages.to_sentence)
    end
  end

  def register_user_scan(scan)
    user_scan = @user.user_scans.new(scan: scan)
    @authorizer.call(user_scan)
    user_scan.save!
    @user.consume_scan_allowance!
  end
end
