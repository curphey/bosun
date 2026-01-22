// almost-there.ts - Code that's 90% good but has small issues
// These are the "last 10%" fixes that make code professional

import { Logger } from './logger';

const logger = new Logger('app');

// Good structure, but inconsistent logging
export class UserService {
  async createUser(email: string, name: string) {
    logger.info('Creating user'); // No context
    try {
      const user = await this.saveUser({ email, name });
      console.log('User created:', user.id); // Should use logger
      return user;
    } catch (error) {
      logger.error('Failed to create user'); // No error details
      throw error;
    }
  }

  async getUser(id: string) {
    logger.debug(`Getting user ${id}`); // Good
    const user = await this.findUser(id);
    if (!user) {
      console.warn('User not found:', id); // Inconsistent - should use logger
      return null;
    }
    return user;
  }

  private async saveUser(data: { email: string; name: string }) {
    // Implementation
    return { id: '123', ...data };
  }

  private async findUser(id: string) {
    // Implementation
    return null;
  }
}

// Good error class, but messages inconsistent
export class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// Error messages - some detailed, some not
export function validateEmail(email: string): void {
  if (!email) {
    throw new AppError('VALIDATION_ERROR', 'Email is required', 400);
  }
  if (!email.includes('@')) {
    throw new AppError('VALIDATION_ERROR', 'Invalid email', 400); // Not helpful
  }
}

export function validatePassword(password: string): void {
  if (!password) {
    throw new AppError('VALIDATION_ERROR', 'Password is required', 400);
  }
  if (password.length < 8) {
    throw new AppError(
      'VALIDATION_ERROR',
      'Password must be at least 8 characters long', // Good - specific
      400
    );
  }
  if (!/[A-Z]/.test(password)) {
    throw new AppError('VALIDATION_ERROR', 'Bad password', 400); // Not helpful - what's wrong?
  }
}

// Good async handling, but missing Promise.all opportunity
export async function loadDashboardData(userId: string) {
  // These could run in parallel
  const user = await getUser(userId);
  const orders = await getOrders(userId);
  const notifications = await getNotifications(userId);
  const stats = await getStats(userId);

  return { user, orders, notifications, stats };
}

// Better version (commented out):
// export async function loadDashboardDataFast(userId: string) {
//   const [user, orders, notifications, stats] = await Promise.all([
//     getUser(userId),
//     getOrders(userId),
//     getNotifications(userId),
//     getStats(userId),
//   ]);
//   return { user, orders, notifications, stats };
// }

// Good abstraction, but leaky
export async function sendWelcomeEmail(user: { email: string; name: string }) {
  const html = `
    <h1>Welcome, ${user.name}!</h1>
    <p>Thanks for signing up.</p>
    <p>Click <a href="https://example.com/verify?email=${user.email}">here</a> to verify.</p>
  `; // HTML in business logic - should be template

  await sendEmail({
    to: user.email,
    subject: 'Welcome!',
    html,
  });
}

// Decent validation, but could use a library
export function validateUserInput(input: any): { email: string; name: string } {
  const errors: string[] = [];

  if (!input.email) {
    errors.push('Email required');
  } else if (typeof input.email !== 'string') {
    errors.push('Email must be string');
  } else if (!input.email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
    errors.push('Email invalid');
  }

  if (!input.name) {
    errors.push('Name required');
  } else if (typeof input.name !== 'string') {
    errors.push('Name must be string');
  } else if (input.name.length < 2) {
    errors.push('Name too short');
  } else if (input.name.length > 100) {
    errors.push('Name too long');
  }

  if (errors.length > 0) {
    throw new AppError('VALIDATION_ERROR', errors.join(', '), 400);
  }

  return { email: input.email, name: input.name };
}

// Good separation, but hardcoded config
export const config = {
  database: {
    host: process.env.DB_HOST || 'localhost', // Good - env with fallback
    port: 5432, // Hardcoded - should be from env
    name: 'myapp', // Hardcoded
    maxConnections: 10, // Hardcoded
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: 6379, // Hardcoded
  },
  api: {
    rateLimit: 100, // Should be configurable
    timeout: 30000, // Should be configurable
  },
};

// Stubs for the example
async function getUser(id: string) { return { id }; }
async function getOrders(id: string) { return []; }
async function getNotifications(id: string) { return []; }
async function getStats(id: string) { return {}; }
async function sendEmail(opts: { to: string; subject: string; html: string }) {}
