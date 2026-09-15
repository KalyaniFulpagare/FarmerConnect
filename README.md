# 🌾 FarmerConnect

A full-stack Flutter marketplace that connects farmers and buyers through real-time product discovery, secure ordering, inventory management, and price tracking.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)

## 🚀 Demo

**[Download the Android APK](release/FarmerConnect-release.apk)**

## ✨ What it does

### For Buyers
- Discover and search agricultural products
- Browse by category and location
- Add products to cart and checkout
- Real-time stock validation
- Track orders
- Manage wishlist
- Set price alerts
- View price trends and analytics

### For Sellers
- Create and manage listings
- Upload product images
- Track live inventory
- Manage incoming orders
- Update order status
- View sales analytics

## 🧠 Engineering Highlights

- **Atomic checkout** using Firestore transactions to prevent stale-stock purchases
- **Role-based access** for buyer, seller, and combined accounts
- **Real-time data** powered by Cloud Firestore
- **Database-level security** with Firestore Security Rules
- **Checkout-time price validation**
- **Cloudinary image pipeline** for efficient product image storage and delivery
- **Location-aware discovery** with nearby-first sorting

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
- Protected buyer/seller operations
- Transactional inventory updates
- Checkout-time validation

## ⚡ Run Locally

    flutter pub get
    flutter run

Firebase configuration is intentionally excluded from version control. Configure your own Firebase project before running locally.

## 📦 Release

The latest Android release is available here:

**[FarmerConnect-release.apk](release/FarmerConnect-release.apk)**
