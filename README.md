# 🌾 FarmerConnect

A cross-platform Flutter marketplace connecting farmers and buyers through real-time product discovery, secure ordering, inventory management, and price tracking.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)

## 🚀 Demo

**[Download Android APK](release/FarmerConnect-release.apk)**

> Built with Flutter for cross-platform deployment.

## ✨ Features

### Buyer
- Product search and category discovery
- Nearby-first product discovery
- Cart and multi-product checkout
- Real-time stock validation
- Order tracking
- Wishlist and notifications
- Price alerts and trend tracking
- Buyer analytics

### Seller
- Product listing and management
- Cloudinary image uploads
- Live inventory tracking
- Order management and status updates
- Seller analytics

## 🧠 Engineering Highlights

- **Atomic checkout** using Firestore transactions to prevent stale-stock purchases
- **Role-based access** for buyer, seller, and combined accounts
- **Real-time marketplace data** powered by Cloud Firestore
- **Database-level security** with Firestore Security Rules
- **Checkout-time price validation**
- **Location-aware discovery** with nearby-first sorting
- **Cloudinary image pipeline** for product images

## 🛠️ Tech Stack

**Flutter · Dart · Riverpod · Firebase Authentication · Cloud Firestore · Cloudinary · go_router · Geolocator**

## 🔄 Order Flow

`Placed → Accepted → Preparing → Ready → Completed`

## 📱 Architecture

Feature-based Flutter architecture with repository and service layers.

`Authentication · Marketplace · Orders · Wishlist · Price Alerts · Notifications · Analytics`

## 🔐 Security

- Firebase Authentication
- Role-based Firestore access
- Firestore Security Rules
- Protected buyer and seller operations
- Transactional inventory updates
- Checkout-time validation

## ⚡ Run Locally

    flutter pub get
    flutter run

Firebase configuration is intentionally excluded from version control. Configure your own Firebase project before running locally.

## 📦 Release

The current repository includes an Android release build for demonstration.

**[Download FarmerConnect APK](release/FarmerConnect-release.apk)**
