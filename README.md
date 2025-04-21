# Meetily Backend - Meeting Transcription and Analysis

Meetily Backend is a powerful FastAPI-based service that provides automatic transcription and intelligent analysis of meetings. It uses state-of-the-art speech recognition technology combined with AI analysis to help you extract key insights from your meetings.

## Features

- **Automatic Speech Recognition**: Powered by Whisper.cpp for fast, accurate transcription
- **Speaker Diarization**: Identifies different speakers in the conversation
- **Meeting Analysis**: Generates summaries, action items, and key points
- **API-First Design**: Easy integration with frontend applications or other services
- **Multiple AI Options**: Support for Anthropic Claude, Groq, and local Ollama models

## Installation

### Prerequisites

- macOS (via Homebrew)
- Python 3.9 or higher
- FFmpeg (installed automatically as a dependency)

### Install via Homebrew

First, add the Meetily tap (this is a custom tap, not an official Homebrew formula):

```bash
brew tap zackriya-solutions/meetily-backend
```

Then install the backend:

```bash
brew install meetily-backend
```

### Post-Installation Setup

1. Download a Whisper model:

```bash
meetily-download-model medium
```

Available models: `tiny`, `base`, `small`, `medium`, `large-v3`

To run the server, run
```bash
meetily-server
```

2. Configure AI providers (optional but recommended):

You can set up API keys during installation or manually:

```bash
echo "ANTHROPIC_API_KEY=your_key_here" > $(brew --prefix)/opt/meetily-backend/backend/.env
echo "GROQ_API_KEY=your_key_here" >> $(brew --prefix)/opt/meetily-backend/backend/.env
```

3. For local LLM support, install Ollama:

```bash
brew install ollama
ollama pull mistral
```

## Usage

### Starting the Server

```bash
meetily-server
```

This will start both the Whisper transcription server and the FastAPI backend.

### Accessing the API

- Whisper Server: http://localhost:8178
- FastAPI Backend: http://localhost:5167
- API Documentation: http://localhost:5167/docs

## API Endpoints

The Meetily Backend provides several endpoints for meeting transcription and analysis:

### Transcription

- `POST /transcribe`: Upload an audio file for transcription
- `GET /transcriptions/{id}`: Retrieve a specific transcription
- `GET /transcriptions`: List all transcriptions

### Analysis

- `POST /analyze/{transcription_id}`: Generate analysis for a transcription
- `GET /analysis/{id}`: Retrieve a specific analysis
- `GET /analysis`: List all analyses

## Frontend Integration

For the complete Meetily experience, install the frontend application from our custom tap:

```bash
brew tap zackriya-solutions/meetily
brew install --cask meetily
```

## Troubleshooting

### Model Issues

If you encounter issues with the Whisper model:

```bash
# Try a different model size
meetily-download-model small

# Verify model installation
ls -la $(brew --prefix)/opt/meetily-backend/backend/whisper-server-package/models/
```

### Server Connection Issues

If the server fails to start:

1. Check if ports 8178 and 5167 are available
2. Verify that FFmpeg is installed correctly
3. Check the logs for specific error messages

## Development and Contributions

Meetily is an open-source project. Visit our GitHub repository to contribute:
https://github.com/Zackriya-Solutions/meeting-minutes

## License

MIT License
