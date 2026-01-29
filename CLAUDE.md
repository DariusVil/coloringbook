# ColoringBook

A full-stack kids coloring book application with an iOS frontend and Python FastAPI backend, featuring AI-powered image generation via DALL-E 3.

## Project Structure

```
ColoringBook/
├── iOS/                      # SwiftUI iOS Application
│   └── ColoringBook/
│       ├── Models/           # Data models (Codable, Sendable)
│       ├── Views/            # SwiftUI views
│       ├── ViewModels/       # @Observable view models
│       └── Services/         # API and utility services
└── server/                   # Python FastAPI Backend
    ├── main.py               # API endpoints
    ├── requirements.txt      # Python dependencies
    └── images/               # Coloring book images
```

## iOS Development Guidelines

### Architecture: MVVM + SwiftUI

- **Models**: Pure data types conforming to `Codable`, `Identifiable`, `Hashable`, and `Sendable`
- **Views**: SwiftUI views that observe ViewModels; keep views declarative and logic-free
- **ViewModels**: Use `@Observable` macro for state management; contain business logic and coordinate services
- **Services**: Use `actor` pattern for thread-safe API communication

### Strict Concurrency

This project uses Swift 6 strict concurrency. All code must be concurrency-safe:

- Mark data models as `Sendable`
- Use `actor` for services that manage mutable state
- Use `async/await` for all asynchronous operations
- Avoid `@MainActor` unless necessary for UI updates
- Never use completion handlers; prefer structured concurrency

### Building with XcodeBuild MCP

Use the xcodebuildmcp skill for all iOS build, test, and run operations:

```
/xcodebuildmcp build
/xcodebuildmcp test
/xcodebuildmcp run
```

This provides better integration with Claude Code for iOS/macOS development workflows.

### SwiftUI Best Practices

- Target iOS 17+ to use modern APIs (`@Observable`, etc.)
- Use `#Preview` macros for all views
- Prefer composition over inheritance
- Use `LazyVGrid`/`LazyHGrid` for performance with large collections
- Handle loading, error, and empty states explicitly in views

## Server Development Guidelines

### Technology Stack

- **FastAPI**: Async Python web framework
- **Uvicorn**: ASGI server
- **OpenAI API**: DALL-E 3 image generation

### Running the Server

```bash
cd server
source venv/bin/activate
OPENAI_API_KEY=your-key uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/images` | GET | List all images |
| `/api/generate` | POST | Generate new image |
| `/images/{filename}` | GET | Serve image file |

## Code Style

### Swift

- Use Swift's native naming conventions (PascalCase for types, camelCase for members)
- Prefer `let` over `var`
- Use explicit types only when necessary for clarity
- Document public APIs with doc comments

### Python

- Follow PEP 8 style guide
- Use type hints for function signatures
- Use Pydantic models for request/response validation
- Use `async def` for all endpoint handlers

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | Required for image generation |
| `COLORINGBOOK_IMAGES_DIR` | Optional: Custom images directory |

## Testing

- iOS: Use XCTest with async test methods
- Server: Use pytest with httpx for async API testing

## Common Tasks

### Adding a New Feature (iOS)

1. Create/update model in `Models/` if needed
2. Add service method in `Services/` for API calls
3. Update ViewModel with new state and methods
4. Create/update View to display the feature

### Adding a New Endpoint (Server)

1. Define Pydantic models for request/response
2. Add endpoint function in `main.py`
3. Update CORS if needed for new routes
