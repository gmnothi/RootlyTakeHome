class Suggestion < ApplicationRecord
  validates :content, presence: true
  validates :suggestion_type, presence: true, inclusion: { in: %w[action_item trigger_event root_cause metadata] }
  validates :priority, presence: true, inclusion: { in: %w[high medium low] }
  validates :confidence, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  scope :by_type, ->(type) { where(suggestion_type: type) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :high_priority, -> { where(priority: "high") }
  scope :recent, -> { order(created_at: :desc) }

  def action_item?
    suggestion_type == "action_item"
  end

  def trigger_event?
    suggestion_type == "trigger_event"
  end

  def root_cause?
    suggestion_type == "root_cause"
  end

  def metadata?
    suggestion_type == "metadata"
  end

  def has_audio?
    audio_data.present?
  end

  def priority_class
    case priority
    when "high"
      "danger"
    when "medium"
      "warning"
    when "low"
      "info"
    else
      "secondary"
    end
  end

  def type_icon
    case suggestion_type
    when "action_item"
      "📋"
    when "trigger_event"
      "⚡"
    when "root_cause"
      "🔍"
    when "metadata"
      "🏷️"
    else
      "💡"
    end
  end
end
