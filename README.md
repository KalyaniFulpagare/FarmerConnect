# 🌾 FarmerConnect

A full-stack Flutter marketplace connecting farmers and buyers with real-time listings, secure checkout, transactional inventory management, location-based discovery, analytics, and price alerts.

## Features

- Buyer and seller role-based workflows
- Product search, categories, and nearby-first discovery
- Cart and multi-product checkout
- Real-time inventory and order management
- Transactional stock and price validation
- Wishlist, notifications, and price alerts
- Buyer and seller analytics
- Cloudinary-powered image uploads
- Firebase Authentication and Firestore Security Rules
- Modern quick-commerce inspired UI

## Tech Stack

**Flutter · Dart · Riverpod · Firebase Auth · Cloud Firestore · Cloudinary · go_router · Geolocator**

## Engineering Highlights

### Atomic Checkout

    Validate latest stock
            ↓
    Validate current price
            ↓
    Update inventory
            ↓
    Create order
            ↓
    Commit transaction

Firestore transactions ensure inventory and order updates remain consistent and prevent stale-stock purchases.

### Order Lifecycle

    Placed → Accepted → Preparing → Ready → Completed

## Architecture

    lib/
    ├── core/
    ├── features/
    │   ├── auth/
    │   ├── marketplace/
    │   ├── orders/
    │   ├── wishlist/
    │   ├── price_alerts/
    │   ├── notifications/
    │   └── analytics/
    ├── models/
    └── services/

Repository and service-based architecture with Firebase-backed real-time data.

## Download

[Download Release APK](release/FarmerConnect-release.apk)

## Security

- Role-based database access
- Protected buyer and seller operations
- Transactional inventory updates
- Checkout-time price validation
- Firebase Authentication
- Firestore Security Rules

## Setup

    flutter pub get
    flutter run

Firebase configuration files are excluded from version control and must be configured for a local deployment.
