class ElevenlabsService
  def initialize
    @api_key = ENV["ELEVENLABS_API_KEY"]
    @base_url = "https://api.elevenlabs.io/v1"
  end

  def text_to_speech(text, voice_id = "21m00Tcm4TlvDq8ikWAM", model_id = "eleven_monolingual_v1")
    # If no API key is set, return mock audio data for demo
    if @api_key.blank? || @api_key == "your_elevenlabs_api_key_here"
      return generate_mock_audio_data(text)
    end

    response = HTTParty.post(
      "#{@base_url}/text-to-speech/#{voice_id}",
      headers: {
        "Accept" => "audio/mpeg",
        "Content-Type" => "application/json",
        "xi-api-key" => @api_key
      },
      body: {
        text: text,
        model_id: model_id,
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.5
        }
      }.to_json
    )

    if response.success?
      # Return the audio data
      response.body
    else
      Rails.logger.error "ElevenLabs API error: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "ElevenLabs API error: #{e.message}"
    # Fallback to mock audio data
    generate_mock_audio_data(text)
  end

  def get_available_voices
    return [] unless @api_key.present?

    response = HTTParty.get(
      "#{@base_url}/voices",
      headers: {
        "xi-api-key" => @api_key
      }
    )

    if response.success?
      JSON.parse(response.body)["voices"] || []
    else
      Rails.logger.error "ElevenLabs voices API error: #{response.code} - #{response.body}"
      []
    end
  rescue => e
    Rails.logger.error "ElevenLabs voices API error: #{e.message}"
    []
  end

  def generate_incident_audio(suggestion_text)
    # Create a more natural-sounding text for TTS
    audio_text = "Suggestion: #{suggestion_text}"

    text_to_speech(audio_text)
  end

  private

  def generate_mock_audio_data(text)
    # Return a small mock audio data for demonstration
    # In a real app, this would be actual audio data
    "mock_audio_data_for_#{text.length}_characters"
  end
end
