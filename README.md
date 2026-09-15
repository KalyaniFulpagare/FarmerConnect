# 🌾 FarmerConnect

> A full-stack Flutter marketplace connecting farmers and buyers through real-time product listings, secure ordering, stock validation, location-based discovery, analytics, and price alerts.

FarmerConnect is a mobile marketplace built with Flutter and Firebase that connects farmers directly with buyers through a streamlined marketplace experience.

## ✨ Features

### 🛒 Buyer

- Search and browse agricultural products
- Category-based discovery
- Nearby-first product sorting
- Product details and live availability
- Cart with quantity controls
- Multi-product checkout
- Order tracking
- Wishlist
- Notifications
- Price alerts
- Historical price tracking
- Buyer analytics

### 👨‍🌾 Seller

- Create and manage product listings
- Product image uploads
- Live inventory tracking
- Seller order management
- Order status workflow
- Seller analytics
- Automatic inventory updates
- Product availability management

### 🔐 Security & Reliability

- Firebase Authentication
- Role-based access control
- Firestore Security Rules
- Real-time Firestore updates
- Transaction-based stock validation
- Checkout-time price validation
- Protected order updates
- Automatic product unavailability when stock reaches zero

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Backend | Firebase |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Image Storage | Cloudinary |
| Navigation | go_router |
| Image Loading | cached_network_image |
| Location | Geolocator |
| Architecture | Repository + Service based architecture |

## 🧠 Technical Highlights

### Transactional Checkout

Stock validation and order creation are handled inside a Firestore transaction.

    Buyer Checkout
          ↓
    Read latest product data
          ↓
    Validate availability
          ↓
    Validate stock
          ↓
    Validate current price
          ↓
    Decrease inventory
          ↓
    Create order
          ↓
    Commit transaction

This ensures inventory updates and order creation happen atomically and prevents stale stock from causing invalid purchases.

### Role-Based Application Flow

    User
     │
     ├── Buyer
     │    ├── Home
     │    ├── Browse
     │    ├── Cart
     │    ├── Orders
     │    ├── Wishlist
     │    ├── Notifications
     │    ├── Price Alerts
     │    └── Analytics
     │
     └── Seller
          ├── My Listings
          ├── Add Product
          ├── Seller Orders
          └── Analytics

Users with both buyer and seller capabilities can access the appropriate workflows.

## 📱 Application Modules

    FarmerConnect
    │
    ├── Authentication
    │   ├── Login
    │   ├── Registration
    │   └── Role Management
    │
    ├── Buyer
    │   ├── Home
    │   ├── Browse
    │   ├── Cart
    │   ├── Orders
    │   ├── Wishlist
    │   ├── Notifications
    │   ├── Price Alerts
    │   └── Analytics
    │
    ├── Seller
    │   ├── My Listings
    │   ├── Add Product
    │   ├── Seller Orders
    │   └── Analytics
    │
    ├── Marketplace
    │   ├── Product Discovery
    │   ├── Categories
    │   ├── Location-based Sorting
    │   └── Product Details
    │
    └── Backend
        ├── Firebase Authentication
        ├── Cloud Firestore
        ├── Firestore Security Rules
        └── Cloudinary

## 🔄 Order Lifecycle

    Placed
      ↓
    Accepted
      ↓
    Preparing
      ↓
    Ready
      ↓
    Completed

Orders can also be cancelled where permitted by the workflow.

## ☁️ Image Upload Pipeline

    Gallery
       ↓
    Flutter Image Picker
       ↓
    Image Processing
       ↓
    Cloudinary Upload
       ↓
    Secure Image URL
       ↓
    Firestore Product Document
       ↓
    Cached Image Display

## 📊 Price Tracking

FarmerConnect maintains product price history and provides trend information.

- Historical price tracking
- Price change monitoring
- Trend estimates
- Price alerts

## 🎨 UI & UX

The application follows a modern quick-commerce inspired interface with:

- Search-first discovery
- Product cards
- Category shortcuts
- Promotional banners
- Bottom navigation
- Floating cart access
- Loading, empty, and error states
- Role-specific dashboards
- Clean marketplace-focused layouts

Primary user flow:

**Discover → Add to Cart → Checkout → Track Order**

## 🔐 Firestore Security

Firestore Security Rules enforce access at the database level.

- Users can access their own profile data
- Buyers can create their own orders
- Sellers can update permitted fields on their own orders
- Buyers can perform only valid stock reductions
- Notification creation is tied to the authenticated user
- Marketplace operations are protected according to user roles

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Android Studio
- Firebase project
- Android device or emulator

### Clone

    git clone https://github.com/KalyaniFulpagare/FarmerConnect.git
    cd FarmerConnect

### Install Dependencies

    flutter pub get

### Firebase Configuration

Firebase configuration files are intentionally excluded from this repository.

Configure Firebase for your own project before running the application.

### Run

    flutter run

## 📂 Project Structure

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
    ├── services/
    └── main.dart

Local Firebase configuration files are excluded from version control.

## 🧪 Validation

The project was tested across key marketplace workflows:

- Authentication
- Buyer browsing
- Product search
- Category filtering
- Cart operations
- Checkout
- Transactional stock validation
- Order lifecycle
- Seller inventory
- Wishlist
- Notifications
- Price alerts
- Image upload and display
- Role-based navigation
- Firestore security rules

## 📦 APK

A release APK was successfully generated during development.

    build/app/outputs/flutter-apk/app-release.apk

The generated APK is not committed to the repository.

## 🔮 Future Improvements

- Online payment integration
- Push notifications
- Advanced recommendation system
- Sophisticated price forecasting
- Delivery partner integration
- Multilingual support
- Seller verification
- Buyer-seller chat
- Production-grade release signing

## 👩‍💻 Author

**Kalyani Fulpagare**

B.Tech Computer Science Engineering  
MKSSS Cummins College of Engineering for Women, Pune

## 📄 License

This project is developed for academic and portfolio purposes.
