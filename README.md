# Setup Instructions
Note: check URL_SHORTENER_FLOW.md for some information regarding the encode and decode flows

## Prerequisites

- Docker and Docker Compose installed
- Git

## Installation

1. Clone the repository:
```bash
git clone https://github.com/oramadn/short-link.git
cd short-link
```
2. Install version 4.0.0 of ruby if not already present
```bash
rbenv install 4.0.0
rbenv local 4.0.0
```

3. Build and start the containers:
```bash
docker-compose up --build
```
Note: .env file is included in the repo for easier setup

4. In a new terminal, set up the database:
```bash
docker-compose exec web bin/rails db:create db:migrate
```

5. Access the application at `http://0.0.0.0:3000`

## Services

The application runs the following services:

- **Web**: Rails server on port 3000
- **CSS**: Tailwind CSS watcher for live stylesheet compilation
- **Database**: PostgreSQL on port 5432
- **Redis**: Redis server on port 6337
- **Sidekiq**: Background job processor

## Common Commands

Stop all services:
```bash
docker-compose down
```

View logs:
```bash
docker-compose logs -f
```

Run Rails commands:
```bash
docker-compose exec web bin/rails <command>
```

Access Rails console:
```bash
docker-compose exec web bin/rails console
```
Running tests:
```bash
docker-compose exec web bin/rails db:test:prepare
docker-compose exec web bin/rails test
```

## Troubleshooting

If you see "watchman not found" warnings in the CSS service logs, this is expected and can be safely ignored. The CSS watcher will function correctly using an alternative file watcher.

# Design breakdown
## Design Decisions

### When a user attempts to shorten a URL that was already shortened, how can we quickly look it up?

Introduce a column called `long_url_hash`. Hash any provided URL using SHA-256 and store the result in this column. This allows fast lookups on a fixed-length value instead of comparing strings that can be 1,000–2,000 characters long.

### What caching strategy should this service use?

Write-through caching is the better option. At scale, a viral shortened URL is expected to be requested by hundreds of users at once, if not more. If we rely on cache misses, many of those requests will hit the database unnecessarily. Instead, we push the short URL to Redis on write and give it a TTL of 24–48 hours.

### In the decode service, why is the alphabet string converted into a hashmap?

Array lookups have a time complexity of O(n), while hashmap lookups are O(1). Using a hashmap results in faster decoding.

## Scaling ShortLink

### Read > Write

A URL shortener will typically have far more reads than writes — roughly 100 reads for every 1 write. To handle this load, we have two main approaches:

- **Read replicas**: Encode requests go to the primary database, while decode requests go to read replicas. This reduces load on the primary but increases infrastructure cost and adds replication delay.
- **Sharding**: Split the load by assigning subsets of short codes to different databases. For example, links starting with a–m go to DB-1 and n–z go to DB-2, etc. This distributes load, but a viral link can still create hotspots on a single shard. The Redis layer can be sharded as well.

### Distributed ID Generation

Currently, ID generation is a single point of failure and a performance bottleneck due to the lack of async operations. In a multi-region setup, two databases could also attempt to issue the same ID.

To resolve this, we can use a distributed ID generator such as Twitter Snowflake. These systems guarantee unique IDs per request and also solve predictability issues where attackers can guess links. This does add complexity, as a separate microservice must be deployed and maintained.

### Infrastructure Scaling

The simplest (but most expensive) approach is horizontal scaling: add more Rails containers for the web server and Sidekiq, and place NGINX in front to load balance across them.

## Potential Attack Vectors

### Data Scraping

This project currently uses a counter to avoid collisions. In its current form, an attacker could iterate through all links by requesting `shortlink.com/1` through `/99999`, or any range they choose.

This allows an attacker to effectively scrape the entire URL database, including links intended to be private.

**Mitigation**: ID shuffling or large prime offsets. Twitter uses a similar approach where IDs are distributed in a pseudo-random manner.

### DDoS on Redis / Database

The decode endpoint checks Redis first and then falls back to the database. An attacker could spam non-existing codes, forcing repeated database hits and potentially degrading performance or causing an outage.

**Mitigation**: Negative caching can be used. Cache “not found” results in Redis for ~60 seconds to prevent repeated misses from hitting the database.

### Phishing and Link Jacking

Attackers can shorten malicious phishing links. If this happens frequently and the links are shared via email or other channels, Google and ISPs may start blocking the ShortLink domain entirely.

**Mitigation**: Cloudflare provides a service that checks the safety of submitted links. This adds some latency to the workflow but significantly improves safety.

### Spamming Requests

An attacker can spam requests to overload the database, Redis, or the job queue.

**Mitigation**: a rate limiter should be added so each IP address is limited to X requests per minute.
