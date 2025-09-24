# Firestore Data Model (MVP)

This document defines the initial Firestore collections, document shapes, and recommended indexes to support the Lyfstyl MVP.

## Collections

### `users/{userId}`
Profile and preferences for each user.

Fields:
- `email`: string (required)
- `displayName`: string | null
- `username`: string | null (unique if used for public profiles)
- `bio`: string | null
- `interests`: string[] (freeform tags/genres)
- `favoriteIds`: string[] (mediaIds)
- `isPublic`: boolean (default true)
- `avatarUrl`: string | null
- `createdAt`: timestamp
- `updatedAt`: timestamp

Notes:
- Document ID equals `auth.uid`.
- Only owner can write; public read governed by `isPublic`.

### `mediaItems/{mediaId}`
Canonical media items for film/book/music.

Fields:
- `type`: 'film' | 'book' | 'music'
- `source`: 'manual' | 'letterboxd' | 'goodreads' | 'spotify' | 'other'
- `title`: string
- `subtitle`: string | null (album/series)
- `creator`: string | null (director/author/artist)
- `releaseDate`: timestamp | null
- `genres`: string[]
- `coverUrl`: string | null
- `externalIds`: map (e.g., imdbId/goodreadsId/spotifyId)
- `createdAt`: timestamp
- `updatedAt`: timestamp

### `logs/{logId}`
User activity logs referencing a `mediaItems` doc.

Fields:
- `userId`: string (auth.uid)
- `mediaId`: string (ref id)
- `rating`: number | null
- `review`: string | null
- `tags`: string[]
- `consumedAt`: timestamp
- `createdAt`: timestamp
- `updatedAt`: timestamp

Common queries:
- By user: `where(userId == uid) orderBy(consumedAt desc)`
- By media: `where(mediaId == X) orderBy(createdAt desc)`

Indexes:
- Composite: `(userId asc, consumedAt desc)`
- Composite: `(mediaId asc, createdAt desc)`

### `collections/{collectionId}`
User-curated ordered sets of media items.

Fields:
- `userId`: string
- `name`: string
- `itemIds`: string[] (ordered mediaIds)
- `createdAt`: timestamp
- `updatedAt`: timestamp

Common queries:
- By user: `where(userId == uid) orderBy(createdAt desc)`

Indexes:
- Composite: `(userId asc, createdAt desc)`

### `trending/{aggregateId}`
Denormalized aggregates per period.

Fields:
- `window`: 'day' | 'week'
- `periodStart`: timestamp (start of day/week in UTC)
- `type`: 'film' | 'book' | 'music'
- `genre`: string | null
- `topMediaIds`: string[] (ordered)
- `generatedAt`: timestamp

Queries:
- `where(window == 'day'|'week' && type == 'film') orderBy(periodStart desc) limit 1`

Indexes:
- Composite: `(window asc, type asc, periodStart desc)`
- Optional: add `genre` to support per-genre trending

## Security Rules (Draft Outline)
- `users`: owner can read/write own doc; public read if `isPublic == true`
- `logs`: only owner can read/write docs where `userId == auth.uid`
- `collections`: only owner can read/write docs where `userId == auth.uid`
- `mediaItems`: read open; write restricted to trusted roles (or only via imports)
- `trending`: read open; write restricted to backend job

Use server timestamps for `createdAt/updatedAt` on writes when possible.

## Profile Editing Scope
To support “create/edit profile (name, bio, interests)” now:
- On first login, create `users/{uid}` with defaults
- Profile edit form can update: `displayName`, `bio`, `interests`, `avatarUrl`, `isPublic`
- Enforce username uniqueness later (Cloud Function or client check + index)

## Implementation Notes
- Use `Timestamp` for dates. Convert with `toDate()` and `Timestamp.fromDate`.
- Prefer reference by id (string) for simplicity; add `DocumentReference` later if needed.
- Add pagination: `.startAfterDocument(lastDoc)` for logs/trending.
- Normalize media: avoid duplicating titles; prefer one `mediaItems` doc per entity.
