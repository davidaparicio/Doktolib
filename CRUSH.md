# CRUSH.md - Development Guide

## Build/Test/Lint Commands

### Frontend (Next.js + TypeScript)
- `cd frontend && npm run dev` - Start development server
- `cd frontend && npm run build` - Build for production
- `cd frontend && npm run lint` - Run ESLint
- `cd frontend && npm run lint -- --fix` - Fix linting issues
- `cd frontend && npx tsc --noEmit` - Type check without emitting files

### Backend (Go)
- `cd backend && go run .` - Start development server
- `cd backend && go build -o doktolib .` - Build binary
- `cd backend && go test ./...` - Run all tests
- `cd backend && go test -run TestSpecificFunction ./...` - Run single test
- `cd backend && go fmt ./...` - Format code
- `cd backend && go vet ./...` - Static analysis

### Docker & Services
- `docker compose up -d` - Start all services
- `docker compose --profile loadtest up` - Include load testing
- `./scripts/run-seed.sh 100 false` - Seed database with 100 doctors

## Code Style Guidelines

### TypeScript/React (Frontend)
- Use TypeScript strict mode, define interfaces for all data structures
- Prefer `interface` over `type` for object shapes
- Use Next.js App Router patterns with `'use client'` when needed
- Import order: React/Next → Third-party → Local components → Constants/types
- Use Tailwind CSS classes, avoid inline styles
- Handle loading/error states explicitly in components
- Use `const` for components: `const ComponentName = () => {}`

### Go (Backend)
- Use struct tags for JSON serialization: `json:"field_name"`
- Handle errors explicitly, don't ignore them
- Use `gin.Context` for HTTP handlers
- Group imports: standard → third-party → local
- Use camelCase for JSON fields, PascalCase for Go structs
- Validate request data with binding tags: `binding:"required"`
- Use environment variables for configuration with fallbacks