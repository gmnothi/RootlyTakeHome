class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def generate_suggestions(transcript_segment, context = {})
    # If no API key is set, generate mock suggestions for demo
    if ENV["OPENAI_API_KEY"].blank? || ENV["OPENAI_API_KEY"] == "your_openai_api_key_here"
      return generate_mock_suggestions(transcript_segment, context)
    end

    prompt = build_suggestion_prompt(transcript_segment, context)

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are an incident management assistant. Your job is to analyze incident meeting transcripts and identify important information that should be recorded. Focus on: 1) Action items and follow-ups, 2) Trigger events for timeline, 3) Potential root causes, 4) Missing metadata. Be concise and actionable."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.3,
        max_tokens: 1000
      }
    )

    parse_suggestions(response.dig("choices", 0, "message", "content"))
  rescue => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    # Fallback to mock suggestions
    generate_mock_suggestions(transcript_segment, context)
  end

  private

  def generate_mock_suggestions(transcript_segment, context)
    # Generate realistic mock suggestions based on the transcript content
    suggestions = []

    # Action items
    if transcript_segment.downcase.include?("remember") || transcript_segment.downcase.include?("follow up")
      suggestions << {
        "type" => "action_item",
        "content" => "Follow up on the mentioned task",
        "confidence" => 0.8,
        "priority" => "high"
      }
    end

    # Trigger events
    if transcript_segment.downcase.include?("resolved") || transcript_segment.downcase.include?("fixed")
      suggestions << {
        "type" => "trigger_event",
        "content" => "Issue appears to be resolved",
        "confidence" => 0.9,
        "priority" => "high"
      }
    end

    # Root causes
    if transcript_segment.downcase.include?("deploy") || transcript_segment.downcase.include?("deployment")
      suggestions << {
        "type" => "root_cause",
        "content" => "Recent deployment may be related to the issue",
        "confidence" => 0.7,
        "priority" => "medium"
      }
    end

    # Metadata
    if transcript_segment.downcase.include?("service") || transcript_segment.downcase.include?("api")
      suggestions << {
        "type" => "metadata",
        "content" => "Service/API mentioned - should be tracked",
        "confidence" => 0.6,
        "priority" => "low"
      }
    end

    # Default suggestion if none match
    if suggestions.empty?
      suggestions << {
        "type" => "action_item",
        "content" => "Review this message for important details",
        "confidence" => 0.5,
        "priority" => "medium"
      }
    end

    suggestions
  end

  def build_suggestion_prompt(transcript_segment, context)
    <<~PROMPT
      Analyze this incident meeting transcript segment and identify important information:

      TRANSCRIPT SEGMENT:
      #{transcript_segment}

      CONTEXT: #{context[:previous_suggestions] || 'No previous suggestions'}

      Please identify and categorize:
      1. ACTION ITEMS: Things responders need to remember to do later
      2. TRIGGER EVENTS: Important moments to record in incident timeline (e.g., "impact mitigated", "service restored")
      3. ROOT CAUSES: Potential causes or theories mentioned (e.g., "started after deploy", "CDN issue")
      4. MISSING METADATA: Services, teams, or systems mentioned that should be tracked

      Format your response as JSON:
      {
        "suggestions": [
          {
            "type": "action_item|trigger_event|root_cause|metadata",
            "content": "description",
            "confidence": 0.8,
            "priority": "high|medium|low"
          }
        ]
      }
    PROMPT
  end

  def parse_suggestions(content)
    return [] unless content.present?

    begin
      parsed = JSON.parse(content)
      parsed.dig("suggestions") || []
    rescue JSON::ParserError
      # Fallback: try to extract suggestions from text
      extract_suggestions_from_text(content)
    end
  end

  def extract_suggestions_from_text(text)
    suggestions = []

    # Simple text parsing as fallback
    if text.include?("ACTION ITEM") || text.include?("action item")
      suggestions << {
        "type" => "action_item",
        "content" => text,
        "confidence" => 0.6,
        "priority" => "medium"
      }
    end

    suggestions
  end
end
