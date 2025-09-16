# Open Questions

This document tracks questions and decisions that need clarification or implementation details.

## API Integration
- **API Key Configuration**: Need to add proper API key configuration for api-sports.io
- **Stat Structure**: Define specific stat structure per sport (NFL, NBA, etc.) for BoxScore and Player stats
- **Team Data Parsing**: Parse city from team name or get from API for proper team display
- **Jersey Numbers**: Get jersey numbers from statistics API for players
- **Birth Date Parsing**: Parse birth date from API for players
- **Current Team**: Get current team from statistics for players
- **Conference/Division**: Get conference and division info from API for teams
- **Game Stats Conversion**: Implement proper game stats conversion from API response

## UI/UX Decisions
- **Navigation**: Implement navigation from Game Poster to Game Menu
- **Rating Distribution Chart**: Implement entertainment rating distribution bar chart
- **Starting Lineups**: Display actual starting lineups data
- **Game Result Details**: Show quarter/half scores, head-to-head stats, stat leaders
- **Box Score Display**: Show actual box score statistics
- **Staff Lists**: Implement staff curated lists with CMS integration
- **Live Games**: Load and display live games in discover section
- **Trending Games**: Implement trending games based on most logged games
- **Search Functionality**: Implement actual search functionality for games, teams, athletes, lists, users

## Data Management
- **Multiple Logs**: Handle multiple log entries per user per game with timestamps
- **Poll Results**: Display poll results after game start time
- **Watchlist Management**: Implement add/remove from watchlist functionality
- **Following System**: Implement user following system
- **Real-time Updates**: Implement real-time updates for live games and polls

## Firebase Configuration
- **Firebase Setup**: Need to configure Firebase project and add GoogleService-Info.plist
- **Firestore Rules**: Set up proper Firestore security rules
- **Authentication**: Configure Firebase Authentication providers

## Performance & Caching
- **Data Caching**: Implement 30-minute caching for API data as specified
- **Image Caching**: Implement caching for team logos, player headshots, etc.
- **Offline Support**: Consider offline support for logged data

## Future Features
- **Other Leagues**: Implement support for NBA, MLB, NHL, etc. beyond NFL
- **College Sports**: Implement college sports support
- **Olympic Sports**: Implement Olympic sports support
- **Push Notifications**: Implement push notifications for live games, poll results, etc.
- **Social Features**: Implement comments, likes, sharing functionality
- **Analytics**: Implement user analytics and game statistics
- **Recommendations**: Implement game recommendations based on user preferences

## Technical Debt
- **Error Handling**: Improve error handling throughout the app
- **Loading States**: Implement proper loading states for all async operations
- **Accessibility**: Add accessibility support for all UI elements
- **Localization**: Consider internationalization support
- **Testing**: Add unit tests and UI tests
- **Code Organization**: Further organize code into proper MVVM or similar architecture
