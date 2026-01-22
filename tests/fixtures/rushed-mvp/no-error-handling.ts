// User service - shipped fast for demo day
// TODO: add error handling later

import { db } from './db';

interface User {
  id: string;
  email: string;
  name: string;
}

// Fetch user - no error handling, will crash on network failure
export async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return data;
}

// Bulk fetch - unhandled promise rejections
export function prefetchUsers(ids: string[]) {
  ids.forEach(id => {
    fetch(`/api/users/${id}`).then(r => r.json());
  });
}

// Database call - no try/catch, crashes on connection failure
export async function getUserFromDb(id: string): Promise<User> {
  const result = await db.query(`SELECT * FROM users WHERE id = '${id}'`);
  return result.rows[0];
}

// File read - no error handling for missing files
export async function getUserConfig(userId: string) {
  const fs = require('fs').promises;
  const config = await fs.readFile(`/config/users/${userId}.json`, 'utf8');
  return JSON.parse(config);
}

// API call chain - if any step fails, no recovery
export async function enrichUserProfile(userId: string) {
  const user = await getUser(userId);
  const preferences = await fetch(`/api/preferences/${userId}`).then(r => r.json());
  const activity = await fetch(`/api/activity/${userId}`).then(r => r.json());
  const recommendations = await fetch(`/api/recommendations/${userId}`).then(r => r.json());

  return {
    ...user,
    preferences,
    activity,
    recommendations
  };
}

// Event handler - swallows errors silently
export function onUserUpdate(callback: (user: User) => void) {
  db.on('user:updated', (data: any) => {
    callback(data);
  });
}

// No validation on external data
export async function importUsers(url: string) {
  const response = await fetch(url);
  const users = await response.json();

  for (const user of users) {
    await db.query(`INSERT INTO users VALUES ('${user.id}', '${user.email}', '${user.name}')`);
  }

  return users.length;
}
