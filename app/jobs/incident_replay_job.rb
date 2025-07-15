class IncidentReplayJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting IncidentReplayJob"

    processor = IncidentProcessorService.new
    transcript_data = load_transcript_data

    Rails.logger.info "Loaded #{transcript_data.length} transcript messages"

    # Process each message one by one with delays
    transcript_data.each_with_index do |message, index|
      Rails.logger.info "Processing message #{index + 1}/#{transcript_data.length}: #{message['speaker']}: #{message['text'][0..50]}..."

      # Check if replay is paused
      if Rails.cache.read("replay_paused")
        Rails.logger.info "Replay paused at message #{index + 1}. Waiting for resume..."
        # Wait for resume signal
        while Rails.cache.read("replay_paused")
          sleep(1)
        end
        Rails.logger.info "Replay resumed at message #{index + 1}"
      end

      # Store progress BEFORE processing to ensure UI gets updates
      store_progress(index + 1, transcript_data.length)

      begin
        # Process the message and generate suggestions
        suggestions = processor.process_transcript_segment(
          message["text"],
          { speaker: message["speaker"], message_index: index }
        )

        Rails.logger.info "Generated #{suggestions.length} suggestions for message #{index + 1}"

        # If no suggestions were generated, create a fallback
        if suggestions.empty?
          Rails.logger.info "No suggestions generated for message #{index + 1}, creating fallback"
          suggestions = [ {
            "type" => "metadata",
            "content" => "Processed message from #{message['speaker']}",
            "confidence" => 0.5,
            "priority" => "low",
            "audio_data" => nil
          } ]
        end

        # Save suggestions to database with proper error handling
        suggestions.each_with_index do |suggestion_data, suggestion_index|
          begin
            # Clean and validate the suggestion data
            cleaned_content = clean_string(suggestion_data["content"])
            validated_type = validate_suggestion_type(suggestion_data["type"])
            validated_priority = validate_priority(suggestion_data["priority"])

            # Skip if content is empty after cleaning
            if cleaned_content.empty? || cleaned_content == "[Content removed due to encoding issues]"
              Rails.logger.warn "Skipping suggestion #{suggestion_index + 1} for message #{index + 1} - content empty after cleaning"
              next
            end

            # Check for duplicates before saving
            next unless prevent_duplicate_suggestions(suggestion_data)

            # Create and save the suggestion
            suggestion = Suggestion.new(
              content: cleaned_content,
              suggestion_type: validated_type,
              priority: validated_priority,
              confidence: suggestion_data["confidence"] || 0.5,
              audio_data: suggestion_data["audio_data"],
              message_index: index  # Store the message index for association
            )

            if suggestion.save
              Rails.logger.info "  Saved suggestion #{suggestion_index + 1}: #{validated_type} - #{cleaned_content[0..50]}"
            else
              Rails.logger.error "  Failed to save suggestion #{suggestion_index + 1}: #{suggestion.errors.full_messages.join(', ')}"
            end

          rescue => e
            Rails.logger.error "  Error saving suggestion #{suggestion_index + 1} for message #{index + 1}: #{e.message}"
            # Continue with other suggestions even if one fails
          end
        end

        # Broadcast to UI via ActionCable (if we set it up)
        broadcast_suggestions(suggestions, message, index)

      rescue => e
        Rails.logger.error "Failed to process message #{index + 1}: #{e.message}"
        # Continue processing other messages even if one fails
      end

      # Add a longer delay between messages to make it more visible
      # This simulates real-time processing that users can see
      if index < transcript_data.length - 1  # Don't sleep after the last message
        sleep(1.5) # 1.5 seconds between messages - more responsive
      end
    end

    Rails.logger.info "IncidentReplayJob completed successfully"
  rescue => e
    Rails.logger.error "Error in IncidentReplayJob: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def clean_string(str)
    return str unless str.is_a?(String)

    begin
      # Force UTF-8 encoding first
      cleaned = str.force_encoding("UTF-8")

      # Remove null bytes and other problematic characters
      cleaned = cleaned.gsub(/\x00/, "")

      # Handle Unicode characters and special characters
      cleaned = cleaned.gsub(/[\u2014\u2013\u2018\u2019\u201C\u201D]/, " ") # Replace em dashes, en dashes, smart quotes
      cleaned = cleaned.gsub(/[\u2026]/, "...") # Replace ellipsis
      cleaned = cleaned.gsub(/[\u00A0]/, " ") # Replace non-breaking spaces

      # Remove all non-printable characters except newlines, tabs, and spaces
      cleaned = cleaned.gsub(/[^\x20-\x7E\x0A\x09]/, " ")

      # Remove any remaining control characters
      cleaned = cleaned.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")

      # More aggressive cleaning for multibyte issues
      # Convert to ASCII-only, replacing non-ASCII with spaces
      cleaned = cleaned.encode("ASCII", invalid: :replace, undef: :replace, replace: " ")

      # Remove any remaining problematic characters
      cleaned = cleaned.gsub(/[^\x20-\x7E\x0A\x09]/, " ")

      # Remove any remaining multibyte characters
      cleaned = cleaned.gsub(/[^\x00-\x7F]/, " ")

      # Clean up multiple spaces
      cleaned = cleaned.gsub(/\s+/, " ")

      # Ensure it's not empty after cleaning
      cleaned.empty? ? "[Content removed due to encoding issues]" : cleaned.strip
    rescue => e
      Rails.logger.warn "Error cleaning string: #{e.message}"
      # Return a safe fallback
      "[Content removed due to encoding issues]"
    end
  end

  def validate_suggestion_type(type)
    return "action_item" unless type.is_a?(String)

    cleaned_type = clean_string(type).strip.downcase

    # Map common variations to valid types
    case cleaned_type
    when "action_item", "actionitem", "action", "todo"
      "action_item"
    when "trigger_event", "triggerevent", "trigger", "event"
      "trigger_event"
    when "root_cause", "rootcause", "cause", "root"
      "root_cause"
    when "metadata", "meta", "info"
      "metadata"
    else
      Rails.logger.warn "Invalid suggestion type '#{type}', defaulting to 'action_item'"
      "action_item"
    end
  end

  def validate_priority(priority)
    return "medium" unless priority.is_a?(String)

    cleaned_priority = clean_string(priority).strip.downcase

    case cleaned_priority
    when "high", "critical", "urgent"
      "high"
    when "medium", "normal", "moderate"
      "medium"
    when "low", "minor"
      "low"
    else
      Rails.logger.warn "Invalid priority '#{priority}', defaulting to 'medium'"
      "medium"
    end
  end

  def store_progress(current, total)
    # Store progress in Redis for UI to track
    Rails.logger.info "Storing progress: #{current}/#{total} (#{(current.to_f / total * 100).round(1)}%)"

    begin
      Rails.cache.write("replay_progress", {
        current: current,
        total: total,
        percentage: (current.to_f / total * 100).round(1)
      }, expires_in: 10.minutes)
      Rails.logger.info "Successfully stored progress in Redis"
    rescue => e
      Rails.logger.error "Failed to store progress: #{e.message}"
    end
  end

  def load_transcript_data
    transcript_file = Rails.root.join("rootly_takehome_transcript_80_no_timestamps.json")

    if File.exist?(transcript_file)
      json_data = JSON.parse(File.read(transcript_file))
      json_data["meeting_transcript"]
    else
      Rails.logger.error "Transcript file not found: #{transcript_file}"
      []
    end
  rescue => e
    Rails.logger.error "Error loading transcript: #{e.message}"
    []
  end

  def broadcast_suggestions(suggestions, message, index)
    # For now, we'll use Rails.logger to see the suggestions
    # Later we can implement ActionCable for real-time updates
    Rails.logger.info "Message #{index + 1}: #{message['speaker']}: #{message['text']}"
    Rails.logger.info "Generated #{suggestions.length} suggestions"

    suggestions.each do |suggestion|
      Rails.logger.info "  - #{suggestion['type'].upcase}: #{suggestion['content']} (#{suggestion['priority']})"
    end
  end

  def prevent_duplicate_suggestions(suggestion_data)
    # Create a normalized version for comparison
    normalized_content = clean_string(suggestion_data["content"]).downcase.strip
    suggestion_type = validate_suggestion_type(suggestion_data["type"])

    # Check if a similar suggestion already exists (more flexible matching)
    existing = Suggestion.where(
      suggestion_type: suggestion_type
    ).where(
      "LOWER(TRIM(content)) LIKE ?", "%#{normalized_content[0..50]}%"
    ).first

    if existing
      Rails.logger.info "Skipping duplicate suggestion: #{suggestion_type} - #{suggestion_data['content'][0..50]}..."
      return false
    end

    true
  end
end
