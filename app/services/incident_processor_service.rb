class IncidentProcessorService
  def initialize
    @openai_service = OpenaiService.new
    @elevenlabs_service = ElevenlabsService.new
  end

  def process_transcript_segment(transcript_segment, context = {})
    # Generate suggestions using OpenAI
    suggestions = @openai_service.generate_suggestions(transcript_segment, context)

    # Process each suggestion and add audio if needed
    suggestions.map do |suggestion|
      process_suggestion(suggestion)
    end
  end

  def process_suggestion(suggestion)
    # Add audio for high-priority suggestions
    if suggestion["priority"] == "high" && suggestion["type"] == "action_item"
      audio_data = @elevenlabs_service.generate_incident_audio(suggestion["content"])
      suggestion["audio_data"] = audio_data if audio_data
    end

    suggestion
  end

  def replay_incident(transcript_data, speed_multiplier = 10)
    # Simulate 10x speed replay of the incident
    # 10 minutes of transcript = 1 minute of replay
    total_duration = 10.minutes
    replay_duration = total_duration / speed_multiplier

    # Process transcript in chunks
    transcript_data.each_with_index do |message, index|
      # Calculate timing for this message
      message_time = (index.to_f / transcript_data.length) * replay_duration

      # Process the message
      suggestions = process_transcript_segment(message["content"])

      # Yield suggestions with timing information
      yield({
        message: message,
        suggestions: suggestions,
        timestamp: message_time,
        index: index
      }) if block_given?

      # Simulate real-time processing delay
      sleep(replay_duration / transcript_data.length)
    end
  end
end
