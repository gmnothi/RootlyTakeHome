class IncidentsController < ApplicationController
  def index
    # Main dashboard view
  end

  def replay
    @transcript = load_transcript_data
    # Load the transcript data
    @transcript_data = load_transcript_data

    # Start the replay simulation
    start_replay_simulation
  end

  def start_replay
    # AJAX endpoint to start replay
    begin
      # Clear any existing pause flag
      Rails.cache.delete("replay_paused")

      IncidentReplayJob.perform_later

      render json: {
        status: "started",
        message: "Incident replay job queued successfully",
        transcript_length: load_transcript_data.length
      }
    rescue => e
      Rails.logger.error "Error starting replay: #{e.message}"
      render json: {
        status: "error",
        message: "Failed to start replay: " + e.message
      }, status: 500
    end
  end

  def pause_replay
    # AJAX endpoint to pause replay
    Rails.cache.write("replay_paused", true, expires_in: 10.minutes)
    render json: {
      status: "paused",
      message: "Replay paused. Processing will stop at next safe point."
    }
  end

  def resume_replay
    # AJAX endpoint to resume replay
    Rails.cache.delete("replay_paused")
    render json: {
      status: "resumed",
      message: "Replay resumed."
    }
  end

  def clear_all
    # AJAX endpoint to clear all data
    begin
      # Clear all suggestions from database
      Suggestion.delete_all

      # Clear Redis cache
      Rails.cache.clear

      # Clear any existing progress
      Rails.cache.delete("replay_progress")
      Rails.cache.delete("replay_paused")

      render json: {
        status: "success",
        message: "All data cleared successfully.",
        suggestions_deleted: Suggestion.count
      }
    rescue => e
      Rails.logger.error "Error clearing all data: #{e.message}"
      render json: {
        status: "error",
        message: "Error clearing data: #{e.message}"
      }, status: 500
    end
  end

  def suggestions
    # Real-time suggestions endpoint
    suggestions = Suggestion.recent.limit(10)
    render json: suggestions
  end

  def transcript
    # Real-time transcript endpoint
    transcript_data = load_transcript_data

    # Get the current progress from the job
    progress = Rails.cache.read("replay_progress") || { current: 0, total: transcript_data.length }

    # Debug logging
    Rails.logger.info "Transcript endpoint called. Progress: #{progress.inspect}"
    Rails.logger.info "Transcript data length: #{transcript_data.length}"

    # Return only the messages that have been processed so far
    processed_messages = transcript_data.first(progress[:current])

    Rails.logger.info "Processed messages count: #{processed_messages.length}"

    # Add IDs and timestamps to each message for tracking
    processed_messages.each_with_index do |message, index|
      message["id"] = index + 1
      message["processed_at"] = Time.current - (progress[:current] - index).seconds
      message["is_new"] = index >= progress[:current] - 3 # Mark recent messages as new
    end

    render json: {
      messages: processed_messages,
      progress: progress,
      total_messages: transcript_data.length
    }
  end

  def timeline
    @transcript = load_transcript_data
    @suggestions = Suggestion.all.order(:message_index, :created_at)
  end

  private

  def load_transcript_data
    transcript_file = Rails.root.join("rootly_takehome_transcript_80_no_timestamps.json")

    if File.exist?(transcript_file)
      json_data = JSON.parse(File.read(transcript_file))
      json_data["meeting_transcript"]
    else
      []
    end
  rescue => e
    Rails.logger.error "Error loading transcript: #{e.message}"
    []
  end

  def start_replay_simulation
    # This will be handled by the background job
    # but we can prepare the data here
    @transcript_length = @transcript_data.length
    @estimated_duration = (@transcript_length * 0.75).seconds # 10x speed simulation
  end
end
