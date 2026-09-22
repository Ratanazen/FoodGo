# 💻 Local Development Guide

## Quick Start
```bash
# Spin up both Daphne and Flutter Web server concurrently
./run_all.sh
```

## Running Tests
```bash
# Backend Test Suite
cd backend && source venv/bin/activate && python manage.py test

# Flutter Test Suite & Analyzer
cd foodgo_flutter
flutter analyze
flutter test
```
