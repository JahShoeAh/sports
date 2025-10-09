# SportsLog - Sports Game Logging App

A Letterboxd-inspired iOS app for logging and reviewing sports games, built with SwiftUI and Firebase.

## Features

### Core Functionality
- **Game Logging**: Rate and review sports games with entertainment value (1-10 scale)
- **Social Features**: Follow users, see their reviews, and discover trending games
- **Game Discovery**: Browse games by league, find live games, and explore staff-curated lists
- **Team & Player Profiles**: View detailed information about teams and athletes

### App Structure
- **Feed**: Infinite scroll of trending games and user activity
- **Search**: Browse by league, discover live/upcoming games, and search functionality
- **Activity**: Follow user activity, your own activity, and incoming interactions
- **Profile**: User profile with statistics, recent games, and menu options

### Game Features
- **Game Posters**: Visual game cards with team matchups and game info
- **Game Menu**: Detailed game information with polls, reviews, and statistics
- **Log Game**: Rate entertainment value, add reactions, specify viewing method, write notes, and add tags
- **Reviews**: View all reviews, your reviews, and reviews from people you follow

## Technical Architecture

### Technologies
- **SwiftUI**: Modern iOS UI framework
- **Firebase**: Authentication and local storage
- **API Integration**: Local server API for sports data
- **MVVM Pattern**: Clean architecture with separation of concerns

### Project Structure
```
sports/
├── Models/           # Data models (User, Game, Review, etc.)
├── Services/         # API and Firebase services
├── Views/           # SwiftUI views organized by feature
│   ├── Auth/        # Authentication views
│   ├── Feed/        # Feed page
│   ├── Search/      # Search and browse
│   ├── Activity/    # Activity feed
│   ├── Profile/     # User profile
│   ├── Game/        # Game-related views
│   ├── Team/        # Team menu
│   ├── Player/      # Athlete menu
│   └── Components/  # Reusable UI components
└── Docs/            # Documentation
```

## Setup Instructions

### Prerequisites
- Xcode 16.4+
- iOS 18.5+
- Firebase project
- Local server setup

### Installation
1. Clone the repository
2. Open `sports.xcodeproj` in Xcode
3. Add your Firebase configuration:
   - Add `GoogleService-Info.plist` to the project
   - Configure Firebase in `sportsApp.swift`
4. Start your local server
5. Build and run the project

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Download `GoogleService-Info.plist` and add to project
5. Configure Firestore security rules

## Current Status

### Completed Features
- ✅ Project structure and data models
- ✅ Firebase integration and authentication
- ✅ API service for NFL data
- ✅ Tab-based navigation
- ✅ Feed page with game posters
- ✅ Search page with browse/discover sections
- ✅ Activity page with tabs
- ✅ Profile page with statistics
- ✅ Game poster cards and game menu
- ✅ Log game functionality
- ✅ Game reviews system
- ✅ Team and athlete menu views

### Pending Features
- 🔄 Firebase project configuration
- 🔄 Server setup
- 🔄 Navigation between views
- 🔄 Real data integration
- 🔄 Poll functionality
- 🔄 Watchlist management
- 🔄 Following system

## API Integration

The app integrates with a local server for sports data:
- Games and schedules
- Team information
- Player rosters and statistics
- Game statistics and box scores

Data is cached for 30 minutes as specified in requirements.

## Future Enhancements

### Additional Leagues
- NBA, MLB, NHL, MLS, EPL
- College sports (Football, Basketball, etc.)
- Olympic sports

### Advanced Features
- Push notifications for live games
- Real-time updates
- Advanced search and filtering
- Social features (comments, likes, sharing)
- Game recommendations
- Analytics and insights

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational purposes. Please ensure you have proper licenses for any third-party services used.

## Support

For questions or issues, please refer to the `Docs/OPEN_QUESTIONS.md` file for known issues and implementation details.
