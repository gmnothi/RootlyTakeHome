module IncidentsHelper
  # Assigns a color class dynamically from a palette based on the participant's index
  def get_speaker_class(speaker, participants = nil)
    palette = %w[bg-primary bg-success bg-warning bg-info bg-danger bg-secondary]
    # If participants list is provided, use its index for color assignment
    if participants
      idx = participants.index(speaker.to_s)
      palette[idx % palette.length]
    else
      palette[speaker.to_s.downcase.hash % palette.length]
    end
  end
end
