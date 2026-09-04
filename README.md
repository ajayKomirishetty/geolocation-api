# Geolocation API

A RESTful Ruby on Rails API that resolves geolocation information from either an IP address or a URL, stores the result in PostgreSQL, and uses an external geolocation provider through a provider abstraction.

The application is designed to be:

- RESTful and JSON-based
- Dockerized for quick local setup
- Backed by PostgreSQL
- Protected with Bearer-token authentication
- Testable with RSpec
- Provider-agnostic, so the geolocation provider can be replaced without changing the controller
- Defensive around invalid input and external-provider failures

---

## Architecture

```text
Client
  |
  | JSON over HTTP
  v
Rails API
  |
  v
GeolocationsController
  |
  v
GeolocationService::Lookup
  |
  v
GeolocationService::Provider
  |
  +------------------------------+
  |                              |
  v                              v
IpstackProvider             Future Provider
  |                              |
  v                              |
ipstack API                      |
                                 |
  +------------------------------+
  |
  v
PostgreSQL
```

### Why use a provider abstraction?

The controller and application service do not depend directly on ipstack.

The application depends on the provider interface:

```ruby
GeolocationService::Provider
```

The current implementation is:

```ruby
GeolocationService::IpstackProvider
```

This makes it possible to replace ipstack with another provider later without rewriting the API controller or core lookup workflow.

For example:

```text
IpstackProvider
MaxMindProvider
GoogleGeolocationProvider
AnotherProvider
```

---

# Technology Stack

- Ruby 3.4.5
- Ruby on Rails 8.1.3.1
- PostgreSQL 16
- RSpec 3.13
- rspec-rails 7.1
- WebMock
- Docker
- Docker Compose
- ipstack API

---

# Prerequisites

For the Docker setup, install:

- Docker Desktop
- Git

You do not need PostgreSQL installed locally when using Docker Compose.

For running Rails directly on the host, you will also need:

- Ruby 3.4.5
- Bundler
- PostgreSQL

---

# Quick Start with Docker

## 1. Clone the repository

```bash
git clone https://github.com/ajayKomirishetty/geolocation-api.git
cd geolocation-api
```

## 2. Create the environment file

Copy the example environment file:

```bash
cp .env.example .env
```

Configure the required values:

```text
IPSTACK_API_KEY=your_ipstack_api_key
API_TOKEN=your_long_random_api_token
SECRET_KEY_BASE=your_long_random_rails_secret
```

Never commit `.env` to source control.

## 3. Start the application

```bash
docker compose up --build
```

The API will be available at:

```text
http://localhost:3000
```

The Docker entrypoint prepares the database during startup.
It also loads an idempotent demo geolocation for `8.8.8.8`, so the read API
can be exercised immediately without consuming a provider request.

## 4. Verify authentication

Requests without authentication should be rejected:

```bash
curl http://localhost:3000/api/v1/geolocations
```

Expected:

```json
{
  "error": "Unauthorized"
}
```

Use the configured API token:

```bash
curl http://localhost:3000/api/v1/geolocations \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

---

# Environment Variables

| Variable | Required | Purpose |
|---|---|---|
| `IPSTACK_API_KEY` | Yes | API key used to communicate with ipstack |
| `API_TOKEN` | Yes | Bearer token required by the application API |
| `SECRET_KEY_BASE` | Yes for production Docker | Rails cryptographic secret; generate with `openssl rand -hex 64` |
| `DATABASE_HOST` | Docker | PostgreSQL hostname |
| `DATABASE_USERNAME` | Docker | PostgreSQL username |
| `DATABASE_PASSWORD` | Docker | PostgreSQL password |
| `DATABASE_NAME` | Docker | PostgreSQL database name |

Example:

```text
IPSTACK_API_KEY=your-key
API_TOKEN=your-secure-token
SECRET_KEY_BASE=your-long-random-rails-secret
```

### Security

Never commit:

```text
.env
config/master.key
API keys
API tokens
Database passwords
Private credentials
```

The repository should contain:

```text
.env.example
```

but not:

```text
.env
```

---

# API Authentication

All API endpoints are protected by Bearer-token authentication.

Every request must include:

```http
Authorization: Bearer YOUR_API_TOKEN
```

## Missing token

Request:

```http
GET /api/v1/geolocations
```

Response:

```http
401 Unauthorized
```

```json
{
  "error": "Unauthorized"
}
```

## Invalid token

Request:

```http
Authorization: Bearer invalid-token
```

Response:

```http
401 Unauthorized
```

## Valid token

Request:

```http
Authorization: Bearer YOUR_API_TOKEN
```

The request proceeds normally.

The API token is loaded from an environment variable and compared using a timing-safe comparison mechanism.

---

# API Endpoints

Base URL:

```text
http://localhost:3000/api/v1
```

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/geolocations` | Create/resolve geolocation |
| `GET` | `/geolocations` | Retrieve geolocation |
| `GET` | `/geolocations/:id` | Retrieve a stored geolocation |
| `DELETE` | `/geolocations/:id` | Delete a geolocation |

All endpoints require authentication.

---

# Create Geolocation from an IP

Request:

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -d '{"ip_address":"8.8.8.8"}'
```

The application:

1. Validates the IP address.
2. Checks whether the IP already exists.
3. Calls the configured geolocation provider when necessary.
4. Normalizes the provider response.
5. Stores the result in PostgreSQL.
6. Returns the stored geolocation.

Example response:

```json
{
  "id": 1,
  "ip_address": "8.8.8.8",
  "url": null,
  "country": "United States",
  "region": "California",
  "city": "Mountain View",
  "latitude": 37.386,
  "longitude": -122.0838,
  "provider": "ipstack_provider",
  "created_at": "2026-09-02T18:00:00.000Z",
  "updated_at": "2026-09-02T18:00:00.000Z"
}
```

---

# Create Geolocation from a URL

Request:

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -d '{"url":"example.com"}'
```

The application:

1. Validates the URL.
2. Extracts the hostname.
3. Resolves the hostname to an IP address.
4. Checks whether that IP already exists.
5. Calls the geolocation provider.
6. Stores the result.
7. Returns the geolocation.

---

# Retrieve Geolocation by IP

```bash
curl "http://localhost:3000/api/v1/geolocations?ip=8.8.8.8" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

---

# Retrieve Geolocation by URL

```bash
curl "http://localhost:3000/api/v1/geolocations?url=example.com" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

---

# Retrieve Geolocation by ID

```bash
curl http://localhost:3000/api/v1/geolocations/1 \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

---

# Delete a Geolocation

```bash
curl -X DELETE http://localhost:3000/api/v1/geolocations/1 \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

Successful deletion returns:

```http
204 No Content
```

## Run the test suite

With PostgreSQL available locally:

```bash
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

The GitHub Actions test job runs the same RSpec suite against PostgreSQL.

---

# Request Validation

The create endpoint accepts exactly one lookup input.

## IP address

```json
{
  "ip_address": "8.8.8.8"
}
```

## URL

```json
{
  "url": "example.com"
}
```

## Neither supplied

```json
{}
```

Response:

```http
422 Unprocessable Content
```

Example:

```json
{
  "error": "Either ip_address or url must be provided"
}
```

## Both supplied

```json
{
  "ip_address": "8.8.8.8",
  "url": "example.com"
}
```

Response:

```http
422 Unprocessable Content
```

## Invalid IP

```json
{
  "ip_address": "999.999.999.999"
}
```

Response:

```http
422 Unprocessable Content
```

---

# Error Handling

The API distinguishes between client errors, missing resources, authentication failures, and upstream provider failures.

| Status | Meaning |
|---|---|
| `200` | Successful retrieval |
| `201` | Geolocation created |
| `204` | Successful deletion |
| `401` | Missing or invalid authentication |
| `404` | Resource not found |
| `422` | Invalid request/input |
| `502` | Upstream geolocation provider failure |
| `504` | Upstream provider timeout |

Errors are returned as JSON.

Example:

```json
{
  "error": "Invalid IP address"
}
```

Provider failures are not exposed as raw HTTP exceptions to the client. They are translated into appropriate API errors.

---

# Service Layer

The application separates HTTP concerns from geolocation business logic.

```text
Controller
    |
    v
GeolocationService::Lookup
    |
    v
GeolocationService::Provider
    |
    v
IpstackProvider
```

## GeolocationService::Lookup

Responsible for the application workflow:

- Validate input
- Resolve URLs
- Check existing records
- Invoke the provider
- Normalize results
- Persist the result

## GeolocationService::Provider

Defines the provider interface:

```ruby
module GeolocationService
  class Provider
    def lookup(_ip_address)
      raise NotImplementedError, "Provider must implement #lookup"
    end
  end
end
```

## GeolocationService::IpstackProvider

Responsible for:

- Making the external HTTP request
- Passing the API key
- Parsing the provider response
- Converting the response into the application's normalized format
- Translating provider failures into application-level errors

---

# Provider Abstraction

One of the main design goals is making the geolocation provider replaceable.

The application does not spread ipstack-specific logic throughout the controllers or models.

The provider returns a normalized structure:

```ruby
{
  country: "...",
  region: "...",
  city: "...",
  latitude: ...,
  longitude: ...
}
```

A future provider can implement the same interface:

```ruby
module GeolocationService
  class AnotherProvider < Provider
    def lookup(ip_address)
      # External API call

      {
        country: "...",
        region: "...",
        city: "...",
        latitude: ...,
        longitude: ...
      }
    end
  end
end
```

The core lookup service does not need to know how the provider obtains the data.

---

# Database

The `geolocations` table stores:

```text
id
ip_address
url
country
region
city
latitude
longitude
provider
created_at
updated_at
```

The database uses uniqueness constraints for IP addresses and URLs.

This provides protection against duplicate records at the database level in addition to application-level validation.

---

# Testing

The project uses RSpec.

Run the entire test suite:

```bash
bundle exec rspec
```

Run the provider specs:

```bash
bundle exec rspec spec/services/geolocation_service/ipstack_provider_spec.rb
```

Run request specs:

```bash
bundle exec rspec spec/requests/api/v1/geolocations_spec.rb
```

Run model specs:

```bash
bundle exec rspec spec/models/geolocation_spec.rb
```

---

# External API Testing

The ipstack provider is tested using WebMock.

Tests do not make real HTTP calls to ipstack.

Instead, external responses are stubbed.

This provides:

- Fast tests
- Deterministic tests
- No dependency on internet connectivity
- No consumption of external API quota
- Predictable failure scenarios

Provider tests cover successful responses and upstream failure conditions.

---

# Running Tests with Docker

You can run the test suite inside the container:

```bash
docker compose exec web bundle exec rspec
```

Run a specific test:

```bash
docker compose exec web \
  bundle exec rspec spec/services/geolocation_service/ipstack_provider_spec.rb
```

---

# Local Development Without Docker

Install dependencies:

```bash
bundle install
```

Configure `.env`:

```text
IPSTACK_API_KEY=your-key
API_TOKEN=your-token
```

Create the database:

```bash
bin/rails db:create
```

Run migrations:

```bash
bin/rails db:migrate
```

Start Rails:

```bash
bin/rails server
```

The application will be available at:

```text
http://localhost:3000
```

---

# Docker Commands

## Start

```bash
docker compose up
```

## Build and start

```bash
docker compose up --build
```

## Start in background

```bash
docker compose up -d
```

## View application logs

```bash
docker compose logs -f web
```

## View PostgreSQL logs

```bash
docker compose logs -f db
```

## Rails console

```bash
docker compose exec web bin/rails console
```

## Run migrations

```bash
docker compose exec web bin/rails db:migrate
```

## Run tests

```bash
docker compose exec web bundle exec rspec
```

## Stop containers

```bash
docker compose down
```

## Stop containers and delete PostgreSQL data

```bash
docker compose down -v
```

> Warning: `docker compose down -v` deletes the PostgreSQL Docker volume and therefore removes local Docker database data.

---

# Development Data

Create a test geolocation using the API:

```bash
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -d '{"ip_address":"8.8.8.8"}'
```

Open the Rails console:

```bash
docker compose exec web bin/rails console
```

Inspect records:

```ruby
Geolocation.count
Geolocation.all
```

Delete development records if necessary:

```ruby
Geolocation.delete_all
```

---

# Security

The application includes several security considerations.

## API Authentication

All API endpoints require a Bearer token.

```http
Authorization: Bearer <API_TOKEN>
```

Unauthenticated requests receive:

```http
401 Unauthorized
```

## Environment Variables

Secrets are supplied through environment variables rather than hard-coded into source code.

Sensitive values include:

```text
IPSTACK_API_KEY
API_TOKEN
SECRET_KEY_BASE
DATABASE_PASSWORD
```

## Docker User

The Rails container runs as a non-root user.

This reduces the impact of a potential container compromise.

## HTTPS

For production deployments, HTTPS/TLS should be enabled.

TLS should typically be terminated at the load balancer, reverse proxy, or cloud platform edge.

---

# Handling Unfortunate Conditions

The implementation is designed to explicitly handle failure scenarios.

Examples include:

- Invalid IP addresses
- IPv4 addresses
- IPv6 addresses
- Invalid URLs
- DNS resolution failures
- Missing lookup parameters
- Both IP and URL supplied
- Unknown geolocation records
- Provider HTTP failures
- Invalid provider JSON
- Provider authentication failures
- Provider timeouts
- Duplicate database records
- Missing environment variables
- Unauthorized requests

External provider failures should not cause the Rails application to crash.

They are converted into controlled API responses.

---

# Production Considerations

The assessment implementation is intentionally lightweight, but the architecture supports further production hardening.

Potential improvements include:

- Provider timeout handling
- Retry and exponential backoff
- Circuit breaker for repeated provider failures
- Rate limiting
- Structured logging
- Request IDs
- Distributed tracing
- Metrics and monitoring
- Secret management through a cloud secret manager
- Database connection pooling
- Response caching
- Background processing for high-volume requests
- Provider response validation
- Health/readiness endpoints
- DNS rebinding protection
- SSRF protection for arbitrary URL resolution

---

# URL Resolution and SSRF Considerations

Because the API accepts URLs, production deployments should treat URL resolution as a security-sensitive operation.

An unrestricted URL resolver can potentially be abused to access internal resources.

A production implementation should consider blocking:

```text
localhost
127.0.0.1
0.0.0.0
private IPv4 ranges
link-local addresses
private IPv6 ranges
cloud metadata endpoints
```

It should also protect against DNS rebinding and validate the resolved address before making any outbound request.

The current assessment implementation keeps URL resolution isolated inside:

```ruby
GeolocationService::UrlResolver
```

so these protections can be added without changing the controller.

---

# Design Guidelines

## Controllers

Controllers should remain thin.

They should:

- Accept HTTP input
- Invoke application services
- Render HTTP responses
- Translate known application errors into HTTP status codes

Business logic should not be placed directly inside controllers.

## Services

Services contain application and integration logic that does not belong in models or controllers.

## Models

Models handle:

- Persistence
- Database validations
- Uniqueness constraints
- Data relationships when required

## External APIs

External API integrations belong behind provider classes.

This prevents vendor-specific logic from spreading throughout the application.

## Tests

Tests should verify behavior rather than implementation details.

External HTTP calls should be stubbed.

Important edge cases should have explicit tests.

---

# Git and Submission Guidelines

Before pushing the repository:

```bash
git status
```

Review staged and untracked files:

```bash
git status --short
```

Review tracked files:

```bash
git ls-files
```

Verify `.env` is ignored:

```bash
git check-ignore .env
```

The repository should contain:

```text
Dockerfile
docker-compose.yml
.env.example
README.md
Gemfile
Gemfile.lock
app/
config/
db/
spec/
```

The repository should not contain:

```text
.env
config/master.key
```

---

# Suggested Commit Structure

A clean commit history could look like:

```text
feat: add geolocation API
feat: add ipstack provider abstraction
test: add geolocation service specs
test: add API request specs
feat: add bearer token authentication
chore: add Docker Compose setup
docs: add setup and API documentation
```

---

# API Workflow

The complete geolocation workflow is:

```text
             IP / URL
                |
                v
        Input Validation
                |
                v
       URL -> IP Resolution
          (when required)
                |
                v
        Database Lookup
                |
        +-------+-------+
        |               |
      Found           Missing
        |               |
        |               v
        |        Provider Lookup
        |               |
        |               v
        |       Normalize Response
        |               |
        |               v
        |         Save Record
        |               |
        +-------<--------+
                |
                v
          JSON Response
```

---

# API Design Summary

The API exposes:

```text
POST   /api/v1/geolocations
GET    /api/v1/geolocations
GET    /api/v1/geolocations/:id
DELETE /api/v1/geolocations/:id
```

All endpoints require:

```http
Authorization: Bearer <API_TOKEN>
```

The API accepts either:

```json
{
  "ip_address": "8.8.8.8"
}
```

or:

```json
{
  "url": "example.com"
}
```

The application validates the input, resolves the address, retrieves geolocation data from the provider when necessary, persists the result, and returns JSON.

---

# Assessment Goals

This project intentionally emphasizes:

1. Clear REST API boundaries
2. Provider abstraction
3. Database persistence
4. Automated testing
5. Authentication
6. Dockerized execution
7. Explicit error handling
8. Easy local setup
9. Separation of concerns
10. Extensibility for future providers
11. Handling of edge cases and failure conditions
12. Security-conscious design

The goal is to keep the implementation simple while demonstrating production-oriented engineering practices.
