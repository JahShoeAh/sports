const express = require('express');
const router = express.Router();
const database = require('../services/database');

// GET /api/rosters - Get all rosters
router.get('/', async (req, res) => {
  try {
    const rosters = await database.getRosters();
    
    res.json({
      success: true,
      data: rosters,
      count: rosters.length
    });

  } catch (error) {
    console.error('Error fetching rosters:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET /api/rosters/:id - Get specific roster
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const roster = await database.getRoster(id);
    
    if (!roster) {
      return res.status(404).json({
        success: false,
        message: 'Roster not found'
      });
    }

    res.json({
      success: true,
      data: roster
    });

  } catch (error) {
    console.error('Error fetching roster:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// POST /api/rosters - Create new roster
router.post('/', async (req, res) => {
  try {
    const { id } = req.body;
    
    if (!id) {
      return res.status(400).json({
        success: false,
        message: 'Roster id is required'
      });
    }

    const roster = { id };
    await database.saveRoster(roster);

    res.json({
      success: true,
      data: roster,
      message: 'Roster created successfully'
    });

  } catch (error) {
    console.error('Error creating roster:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
