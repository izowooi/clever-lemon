# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a FastAPI-based poetry generation API service designed for deployment on Google Cloud Run. The application serves as a backend for a Flutter mobile app that uses Supabase Google authentication. The main functionality includes user currency management, settings management, payment processing, and AI-powered poetry generation.

## Architecture

- **Main Application**: `main.py` - FastAPI application with REST endpoints
- **Authentication**: `verify_token.py` - Supabase JWT token verification module
- **Poetry Generation**: `poem_generator_modern.py` - Modern AI poetry generation with GPT-4o/GPT-5 support
- **Containerization**: `Dockerfile` - Multi-stage Docker build for Cloud Run deployment
- **Deployment**: `deploy.sh` - Automated Google Cloud Run deployment script

## Development Setup

### Prerequisites
- Python 3.12+
- uv package manager (used for dependency management)

### Local Development
```bash
# Install dependencies
uv sync

# Run development server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Access API documentation
# http://localhost:8000/docs
```

### Testing
Use the provided HTTP test file:
```bash
# Test endpoints using test_main.http
# Contains comprehensive endpoint tests including error cases
```

## Deployment

### Google Cloud Run Deployment
```bash
# Automated deployment
./deploy.sh

# Manual deployment
gcloud run deploy clever-lemon-api \
    --source . \
    --region=asia-northeast1 \
    --platform=managed \
    --allow-unauthenticated
```

**Production URL**: https://clever-lemon.zowoo.uk/
- API Documentation: https://clever-lemon.zowoo.uk/docs
- Health Check: https://clever-lemon.zowoo.uk/ping

### Container Build
```bash
# Local container testing
docker build -t cloud-run-proj .
docker run -p 8080:8080 -e PORT=8080 cloud-run-proj
```

## Authentication Architecture

The application is designed to work with Supabase JWT tokens from Flutter Google authentication:

- **Token Verification**: `verify_token.py` handles Supabase JWT verification
- **JWKS Endpoint**: Uses Supabase's JWKS endpoint for key validation
- **Supported Algorithms**: ES256, RS256, EdDSA
- **Integration Point**: Ready for middleware integration in FastAPI endpoints

## API Structure

### Core Endpoints
- `GET /ping` - Health check
- `POST /auth/register` - User registration with access token
- `POST /payments/approve` - Payment processing
- `POST /poems/generate` - AI poetry generation with credit validation (30+ second response time)

### Data Models
- **UserCurrency**: coins, gems, premium_points
- **UserSettings**: font_size, theme, favorite_poet, poem_style, etc.
- **PoemRequest/Response**: Handles multi-style poetry generation with user credit validation

## Key Implementation Notes

### Poetry Generation System
The application uses a modern poetry generation system with dual API support:
- **GPT-5 Models**: Use OpenAI Responses API with reasoning capabilities
- **GPT-4o Models**: Use traditional Chat Completions API
- **Credit System**: Each poem generation consumes 1 credit from user account
- **Error Handling**: Comprehensive JSON parsing failure handling with detailed logging

### Credit Management
- Poetry generation requires user credit validation before processing
- Credits are deducted only after successful poem generation
- Failed generations do not consume credits
- Database operations use Supabase `users_credits` table

### Long-Running Operations
- Poetry generation endpoint simulates 30+ second AI processing
- Designed for async handling in production
- Consider implementing background job processing for production use

### Database Integration
- **Supabase Integration**: Active for user registration, authentication, and credit management
- **Mock Data**: Uses in-memory fake databases for currency and settings (`fake_user_currency`, `fake_user_settings`)
- **Database Tables**: 
  - `users_credits`: user_id, credits, updated_at
- **Future Integration**: Ready for full database migration for all features

### Error Handling
- Comprehensive HTTP exception handling
- Korean language error messages for user-facing responses
- Detailed logging for JSON parsing failures in poetry generation

## Security Considerations

- JWT verification module ready for production use
- Non-root Docker user configuration
- Environment variable support for sensitive configuration
- HTTPS enforcement in deployment configuration

## Configuration

### Environment Variables
- `PORT` - Server port (default: 8080)
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key for database operations
- `SUPABASE_ANON_KEY` - Supabase anonymous key (optional)
- `OPENAI_API_KEY` - OpenAI API key for poetry generation
- `OPENAI_MODEL` - OpenAI model to use (default: gpt-5-mini-2025-08-07)

### Docker Configuration
- Python 3.12 slim base image
- Non-root user execution
- Optimized for Cloud Run deployment