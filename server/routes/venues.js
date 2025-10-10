const express = require('express');
const router = express.Router();
const database = require('../services/database');

// GET /api/venues - Get all venues
router.get('/', async (req, res) => {
  try {
    const venues = await database.getVenues();
    
    res.json({
      success: true,
      data: venues,
      count: venues.length
    });

  } catch (error) {
    console.error('Error fetching venues:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/venues/:id - Get specific venue
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const venue = await database.getVenue(id);
    
    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found'
      });
    }

    res.json({
      success: true,
      data: venue
    });

  } catch (error) {
    console.error('Error fetching venue:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/venues - Create new venue
router.post('/', async (req, res) => {
  try {
    const { id, name, city, state, country, homeTeamId } = req.body;
    
    if (!id || !name) {
      return res.status(400).json({
        success: false,
        message: 'Venue id and name are required'
      });
    }

    const venue = { id, name, city, state, country, homeTeamId };
    await database.saveVenue(venue);

    res.json({
      success: true,
      data: venue,
      message: 'Venue created successfully'
    });

  } catch (error) {
    console.error('Error creating venue:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
