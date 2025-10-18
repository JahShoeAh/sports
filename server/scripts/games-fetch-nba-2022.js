#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const API_BASE = 'https://v2.nba.api-sports.io/games';
const API_KEY = process.env.NBA_API_SPORTS_KEY || '9316aa1d2d0c2d55eb84b0dc566fc21a';
const SEASON = 2022;
const LEAGUE = 'standard';

const OUTPUT_DIR = path.join(__dirname, '..', 'raw_api');
const OUTPUT_JSON = path.join(OUTPUT_DIR, 'raw-nba-2022.json');

function writeJson(filePath, data) {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

function buildUrl() {
    const url = new URL(API_BASE);
    url.searchParams.set('season', String(SEASON));
    url.searchParams.set('league', LEAGUE);
    return url.toString();
}

async function main() {
    const url = buildUrl();
    console.log(`Requesting: ${url}`);

    const res = await fetch(url, {
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'x-apisports-key': API_KEY,
        },
    });

    if (!res.ok) {
        const text = await res.text().catch(() => '');
        throw new Error(`HTTP ${res.status}: ${text}`);
    }

    const json = await res.json();
    writeJson(OUTPUT_JSON, json);
    console.log(`Wrote raw response to ${OUTPUT_JSON}`);
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

ensureFetch()
    .then(() => main())
    .catch((err) => {
        console.error(err);
        process.exitCode = 1;
    });


