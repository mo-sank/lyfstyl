# lyfstyl
CS 4278 Group-15 Project 

Lyfstyl Team — Cami, Julia, Mohamed, Maya 

This repo serves as the version control hub for our PSWE project, Lyfstyl. 

Lyfstyl is an all-in-one media logger and discovery web app that lets a user track what they watch, read, and listen to, see a personalized “What’s Trending” feed, and share a simple profile with stats and collections. We’re building the frontend in Flutter (Dart) so we get one codebase for web with fast hot-reload, and using Firebase for Auth and Cloud Firestore (NoSQL) as the database. Hosting is on Vercel (auto preview links on pull requests, auto-publish on main), with GitHub for version control and Trello for planning. 

Core MVP features include email/password auth, manual logging with ratings/notes, a filtered trending feed, profiles/collections/save-for-later, and a lightweight stats view, plus CSV imports from Goodreads/Letterboxd and Spotify connect; stretch goals include AI-assisted recommendations and simple social follows. 

To run it locally: clone the repo, run flutter pub get, add your Firebase web config via Dart defines, and flutter run -d chrome; to deploy, connect the repo to Vercel and let it build flutter build web. 

Architecturally, the Flutter app talks directly to Firebase, with optional Cloud Functions for imports/search helpers; data centers on users, items, logs, and collections. Our focus is clean UX, privacy by default, and small, frequent releases.
