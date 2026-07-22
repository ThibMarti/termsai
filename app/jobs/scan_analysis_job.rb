class ScanAnalysisJob < ApplicationJob
  queue_as :default

  def perform(scan)
    report = ScanAnalyzer.new(scan.content).call
    scan.update!(status: "completed", full_report: report, risk_score: report["risk_score"])
    scan.broadcast_completion!
  rescue RubyLLM::Error
    scan.update!(status: "failed")
    scan.broadcast_completion!
  end
end
