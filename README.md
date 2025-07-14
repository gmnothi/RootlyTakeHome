<div align="center">
  <img src="app/assets/images/bootly.png" alt="Bootly Logo" width="220" />
</div>

---

## 🎥 Demo

[![Watch the demo video](https://img.youtube.com/vi/16o_nZJTKyhy673WppgefAqsuSlaV9V4L/0.jpg)](https://drive.google.com/file/d/16o_nZJTKyhy673WppgefAqsuSlaV9V4L/view?usp=sharing)

[Click here to watch the demo video on Google Drive](https://drive.google.com/file/d/16o_nZJTKyhy673WppgefAqsuSlaV9V4L/view?usp=sharing)

---

# Rootly Incident Assistant

An AI-powered incident management tool that analyzes incident meeting transcripts in real-time and provides intelligent suggestions to incident responders. (Definitely not a Rootly rip-off! 😡)

## 🚀 Features

- **Real-time Transcript Processing**: Processes incident meeting transcripts at 10x speed
- **AI-Powered Suggestions**: Uses GPT-4.0-mini to identify:
  - Action items and follow-ups
  - Trigger events for timeline
  - Potential root causes
  - Missing metadata
- **Audio Feedback**: ElevenLabs integration for audio alerts on high-priority suggestions
- **Beautiful UI**: Modern, responsive interface with real-time updates
- **Background Processing**: Sidekiq for reliable job processing

## 🛠️ Technology Stack

- **Ruby on Rails 8.0.2** - Web framework
- **PostgreSQL** - Database
- **Sidekiq** - Background job processing
- **Hotwire** - Real-time UI updates
- **OpenAI GPT-4.0-mini** - AI suggestion generation
- **ElevenLabs** - Text-to-speech for audio alerts
- **Bootstrap 5** - UI framework

## 📋 Prerequisites

- Ruby 3.4.4 (via rbenv)
- PostgreSQL
- Redis (for Sidekiq)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install PostgreSQL (if not already installed)
brew install postgresql
brew services start postgresql
```

### 2. Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
# OpenAI API Configuration
OPENAI_API_KEY=your_openai_api_key_here

# ElevenLabs API Configuration
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# Database Configuration
DATABASE_URL=postgresql://localhost/rootly_incident_assistant_development
```

### 3. Set Up Database

```bash
# Create and migrate database
bin/rails db:create db:migrate
```

### 4. Start the Application

```bash
# Terminal 1: Start Rails server
bin/rails server

# Terminal 2: Start Sidekiq (for background jobs)
bundle exec sidekiq
```

### 5. Access the Application

Visit [http://localhost:3000](http://localhost:3000) in your browser.

## 🎯 How to Use

1. **Landing Page**: Visit the homepage to see an overview of the application
2. **Start Replay**: Click "Start Incident Replay" to begin processing the transcript
3. **Watch Suggestions**: Real-time suggestions will appear as the transcript is processed
4. **Review Results**: Check the sidebar for statistics and suggestion counts

## 📊 Sample Incident

The application comes with a sample incident transcript (`rootly_takehome_transcript_80_no_timestamps.json`) that demonstrates:

- **Database performance issues** caused by a recent deployment
- **Rollback procedures** and incident response
- **Action items** and follow-up tasks
- **Root cause analysis** and timeline events

## 🏗️ Architecture

### Services

- **`OpenaiService`**: Handles AI suggestion generation using GPT-3.5-turbo
- **`ElevenlabsService`**: Manages text-to-speech for audio alerts
- **`IncidentProcessorService`**: Orchestrates transcript processing and suggestion generation

### Models

- **`Suggestion`**: Stores generated suggestions with types, priorities, and audio data

### Jobs

- **`IncidentReplayJob`**: Background job that processes the transcript in real-time

### Controllers

- **`IncidentsController`**: Handles replay simulation and suggestion endpoints
- **`SuggestionsController`**: Manages suggestion CRUD operations

## 🧭 Decisions

- **Independent Incident Processing:** Each incident replay is processed independently in its own job. This ensures that multiple incidents can be replayed or analyzed in parallel without interfering with each other.
- **Redis for Progress Tracking:** Redis is used to store per-incident progress and state, enabling the UI to display live updates for each incident as it is processed. This design keeps the UI responsive and decouples job progress from the main database.

## 🎨 UI Features

- **Real-time Updates**: Suggestions appear as the transcript is processed
- **Priority-based Styling**: Different colors for high/medium/low priority suggestions
- **Statistics Dashboard**: Live counts of suggestion types and priorities
- **Progress Tracking**: Visual progress bar for replay simulation

## 🔧 Configuration

### API Keys

You'll need to obtain API keys for:

1. **OpenAI**: Get from [OpenAI Platform](https://platform.openai.com/)
2. **ElevenLabs**: Get from [ElevenLabs](https://elevenlabs.io/)

### Model Configuration

- **GPT-4.0-mini**: Used for cost-effective but capable AI analysis
- **Temperature**: 0.3 for consistent, focused responses
- **Max Tokens**: 500 for reasonable suggestion length

## 🚀 Deployment

### Production Considerations

1. **Environment Variables**: Use proper secret management
2. **Database**: Use production PostgreSQL instance
3. **Redis**: Configure for Sidekiq in production
4. **API Keys**: Secure storage of OpenAI and ElevenLabs keys

### Scaling

- **Sidekiq**: Can be scaled horizontally for more job processing
- **Database**: Add read replicas for heavy query loads
- **Caching**: Add Redis caching for frequently accessed data

## 🧪 Testing

```bash
# Run tests
bin/rails test

# Run specific test files
bin/rails test test/jobs/incident_replay_job_test.rb
```

## 📈 Future Enhancements

With more time, I would add:

1. **ActionCable Integration**: Real-time WebSocket updates instead of polling
2. **User Authentication**: Multi-user support with role-based access
3. **Incident Templates**: Pre-configured incident types and workflows
4. **Advanced Analytics**: Detailed metrics and performance insights
5. **Export Features**: PDF reports and data export capabilities
6. **Integration APIs**: Connect with other incident management tools
7. **Custom Voices**: Allow users to choose different ElevenLabs voices
8. **Transcript Upload**: Support for different transcript formats
9. **Automatic Integrations:** Integrate with calendar apps (Google Calendar, Outlook) to automatically schedule follow-ups or post-mortems, and with Slack for real-time incident notifications and action item assignments—mirroring Rootly's core value.
10. **Better Timeline Streaming:** Implement smooth, real-time streaming of timeline events with animations and live updates, making the replay experience even more immersive and intuitive.

## ⏱️ Time Spent

- **Setup & Configuration**: 2 hours
- **API Integration**: 3 hours
- **UI Development**: 4 hours
- **Testing & Polish**: 1 hour
- **Documentation**: 1 hour

**Total**: ~11 hours


## 📄 License

This project is for the Rootly Product Engineer take-home assignment.

---

**Built with ❤️ using Ruby on Rails and modern web technologies**
