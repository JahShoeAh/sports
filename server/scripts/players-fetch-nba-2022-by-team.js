#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

// External API configuration
const API_BASE = 'https://v2.nba.api-sports.io/players';
const API_KEY = process.env.NBA_API_SPORTS_KEY || '9316aa1d2d0c2d55eb84b0dc566fc21a';
const SEASON = 2022;

// Output location
const OUTPUT_DIR = path.join(__dirname, '..', 'raw_api');

/**
 * Team IDs to fetch, matching user's database-supported mapping.
 * Any numbers not present here are intentionally skipped.
 */
const TEAM_IDS = [
    1,  // ATL
    2,  // BOS
    4,  // BKN
    5,  // CHA
    6,  // CHI
    7,  // CLE
    8,  // DAL
    9,  // DEN
    10, // DET
    11, // GSW
    14, // HOU
    15, // IND
    16, // LAC
    17, // LAL
    19, // MEM
    20, // MIA
    21, // MIL
    22, // MIN
    23, // NOP
    24, // NYK
    25, // OKC
    26, // ORL
    27, // PHI
    28, // PHX
    29, // POR
    30, // SAC
    31, // SAS
    38, // TOR
    40, // UTA
    41, // WAS
];

function ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
}

function writeJson(filePath, data) {
    ensureDir(path.dirname(filePath));
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

function buildUrl(teamId) {
    const url = new URL(API_BASE);
    url.searchParams.set('season', String(SEASON));
    url.searchParams.set('team', String(teamId));
    return url.toString();
}

async function fetchPlayersForTeam(teamId) {
    const url = buildUrl(teamId);
    const res = await fetch(url, {
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'x-apisports-key': API_KEY,
        },
    });

    if (res.status === 429) {
        return { status: 429 };
    }

    if (!res.ok) {
        const text = await res.text().catch(() => '');
        throw new Error(`HTTP ${res.status} team=${teamId}: ${text}`);
    }

    const json = await res.json();
    return { status: res.status, json };
}

async function ensureFetch() {
    if (typeof fetch === 'function') return;
    try {
        const { default: nodeFetch } = await import('node-fetch');
        global.fetch = nodeFetch;
    } catch (err) {
        throw new Error('fetch is not available. Use Node 18+ or install node-fetch.');
    }
}

async function main() {
    ensureDir(OUTPUT_DIR);

    // Hard-coded starting team ID for manual resume
    const START_TEAM_ID = 25; // change as needed
    const startIndex = Math.max(0, TEAM_IDS.indexOf(START_TEAM_ID));
    console.log(`Fetching NBA players for season=${SEASON} starting at teamId=${TEAM_IDS[startIndex]} (index=${startIndex})`);

    for (let i = startIndex; i < TEAM_IDS.length; i++) {
        const teamId = TEAM_IDS[i];
        const outFile = path.join(OUTPUT_DIR, `raw-players-${teamId}.json`);

        // Skip if file already exists to avoid refetching
        if (fs.existsSync(outFile)) {
            console.log(`Already exists, skipping team ${teamId} -> ${path.basename(outFile)}`);
            continue;
        }

        console.log(`Requesting players for team=${teamId} (${i + 1}/${TEAM_IDS.length})`);

        let result;
        try {
            result = await fetchPlayersForTeam(teamId);
        } catch (err) {
            console.error(`Error fetching team ${teamId}:`, err.message);
            return;
        }

        if (result.status === 429) {
            console.warn(`Rate limited while fetching team ${teamId}. Stopping.`);
            return;
        }

        const { json } = result;
        writeJson(outFile, json);
        console.log(`Wrote ${outFile}`);

        // Small delay between calls to reduce chance of 429
        await new Promise((r) => setTimeout(r, 350));
    }

    console.log('Completed fetching players for all configured teams.');
}

ensureFetch()
    .then(() => main())
    .catch((err) => {
        console.error(err);
        process.exitCode = 1;
    });


