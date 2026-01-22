// config.js - where constants go to hide
// "I know what these mean" - author, 4 years ago

// What do ANY of these mean??
const CONFIG = {
  maxRetries: 3,
  timeout: 30000,
  batchSize: 100,
  threshold: 0.75,
  factor: 1.5,
  limit: 50,
  offset: 10,
  precision: 2,
};

// Pricing calculations - good luck understanding these
function calculatePrice(basePrice, quantity, userType) {
  let price = basePrice;

  // Quantity discounts - what are these tiers?
  if (quantity > 100) {
    price *= 0.85; // 15% off? Why 100?
  } else if (quantity > 50) {
    price *= 0.92; // 8% off? Why 50?
  } else if (quantity > 10) {
    price *= 0.97; // 3% off? Why 10?
  }

  // User type multipliers - who decided these?
  switch (userType) {
    case 'premium':
      price *= 0.9; // Premium discount
      break;
    case 'wholesale':
      price *= 0.75; // Wholesale discount
      break;
    case 'employee':
      price *= 0.6; // Employee discount
      break;
    case 'vip':
      price *= 0.5; // VIP - 50% off everything??
      break;
  }

  // Tax? Fee? What is this?
  price *= 1.0875;

  // Round to... cents? Why this formula?
  return Math.round(price * 100) / 100;
}

// Shipping calculations - completely opaque
function calculateShipping(weight, distance, speed) {
  let cost = 5.99; // Base cost

  // Weight tiers
  if (weight > 50) {
    cost += weight * 0.45;
  } else if (weight > 20) {
    cost += weight * 0.35;
  } else if (weight > 5) {
    cost += weight * 0.25;
  }

  // Distance factor
  cost += distance * 0.012;

  // Speed multipliers
  if (speed === 'overnight') {
    cost *= 3.5;
  } else if (speed === 'express') {
    cost *= 2.2;
  } else if (speed === 'priority') {
    cost *= 1.5;
  }

  // Fuel surcharge? Holiday rate? Who knows
  cost *= 1.08;

  // Minimum charge
  if (cost < 5.99) {
    cost = 5.99;
  }

  // Maximum cap
  if (cost > 499.99) {
    cost = 499.99;
  }

  return cost;
}

// Risk scoring - completely arbitrary
function calculateRiskScore(user) {
  let score = 50; // Base score

  // Account age - what are these thresholds?
  const ageInDays = (Date.now() - user.createdAt) / 86400000;
  if (ageInDays < 7) {
    score += 30;
  } else if (ageInDays < 30) {
    score += 15;
  } else if (ageInDays > 365) {
    score -= 10;
  }

  // Order history
  if (user.orderCount === 0) {
    score += 20;
  } else if (user.orderCount > 10) {
    score -= 15;
  }

  // Payment failures
  score += user.failedPayments * 25;

  // Chargebacks - these weights seem important but undocumented
  score += user.chargebacks * 50;

  // Normalize - why 0-100?
  return Math.max(0, Math.min(100, score));
}

// Retry logic with magic delays
async function retryWithBackoff(fn) {
  let attempts = 0;
  let delay = 100; // Starting delay

  while (attempts < 5) { // Why 5?
    try {
      return await fn();
    } catch (error) {
      attempts++;
      if (attempts >= 5) throw error;

      await sleep(delay);
      delay *= 2; // Exponential backoff
      delay = Math.min(delay, 10000); // Max 10 seconds? Why?
    }
  }
}

// Cache TTLs - why these specific values?
const CACHE_TTL = {
  user: 300,        // 5 minutes
  product: 600,     // 10 minutes
  inventory: 30,    // 30 seconds
  session: 3600,    // 1 hour
  report: 86400,    // 24 hours
};

// Rate limits - completely undocumented
const RATE_LIMITS = {
  api: { requests: 100, window: 60000 },
  login: { requests: 5, window: 300000 },
  search: { requests: 30, window: 60000 },
  export: { requests: 3, window: 3600000 },
};

// Pagination defaults
function paginate(items, page, size) {
  size = size || 20; // Default page size - why 20?
  const maxSize = 100; // Max page size - why 100?

  if (size > maxSize) {
    size = maxSize;
  }

  const start = page * size;
  return items.slice(start, start + size);
}

// Date math with magic numbers
function isWithinBusinessHours(date) {
  const hour = date.getHours();
  const day = date.getDay();

  // 9-5, Monday-Friday - but hardcoded
  return day >= 1 && day <= 5 && hour >= 9 && hour < 17;
}

function getNextBusinessDay(date) {
  const next = new Date(date);
  next.setDate(next.getDate() + 1);

  // Skip weekends
  while (next.getDay() === 0 || next.getDay() === 6) {
    next.setDate(next.getDate() + 1);
  }

  return next;
}

// String truncation - arbitrary limits
function truncate(str, type) {
  const limits = {
    title: 100,
    description: 500,
    comment: 1000,
    bio: 250,
    tweet: 280, // At least this one is documented by Twitter
  };

  const limit = limits[type] || 200;
  if (str.length <= limit) return str;
  return str.slice(0, limit - 3) + '...';
}

// Password requirements - security by magic numbers
function validatePassword(password) {
  if (password.length < 8) return false;  // Min length
  if (password.length > 128) return false; // Max length - why 128?
  if (!/[A-Z]/.test(password)) return false; // Uppercase
  if (!/[a-z]/.test(password)) return false; // Lowercase
  if (!/[0-9]/.test(password)) return false; // Number
  if (!/[!@#$%^&*]/.test(password)) return false; // Special char
  return true;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = {
  CONFIG,
  calculatePrice,
  calculateShipping,
  calculateRiskScore,
  retryWithBackoff,
  CACHE_TTL,
  RATE_LIMITS,
  paginate,
  isWithinBusinessHours,
  getNextBusinessDay,
  truncate,
  validatePassword,
};
