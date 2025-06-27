# EchoWave Backend API

RESTful API server for the EchoWave feedback platform.

## Status: Coming Soon

This directory will contain the backend built with:
- Node.js + Express.js
- TypeScript for type safety
- PostgreSQL database
- Prisma ORM
- Redis for caching
- Bull for job queues

## Planned Endpoints
```
POST   /api/v1/auth/signup
POST   /api/v1/auth/signin
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

GET    /api/v1/surveys
POST   /api/v1/surveys
GET    /api/v1/surveys/:id
PUT    /api/v1/surveys/:id
DELETE /api/v1/surveys/:id

POST   /api/v1/surveys/:id/responses
GET    /api/v1/surveys/:id/summary
GET    /api/v1/surveys/:id/qr-code

GET    /api/v1/users/profile
PUT    /api/v1/users/profile
GET    /api/v1/users/stats
```

## Security Features
- JWT authentication
- Rate limiting
- Input validation
- SQL injection prevention
- XSS protection
- CORS configuration
- API key management

Check back soon for the backend implementation! 