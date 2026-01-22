// notification.ts - imports user.ts to get email
import { User } from './user';

// This would normally import a user service, creating the cycle:
// user -> notification -> user

const users: Map<string, User> = new Map(); // Local cache to "break" cycle (bad pattern)

export function registerUser(user: User): void {
  users.set(user.id, user);
}

export function sendNotification(userId: string, message: string): void {
  const user = users.get(userId);
  if (user) {
    console.log(`Sending to ${user.email}: ${message}`);
  } else {
    // Fallback - but this hides the architectural problem
    console.log(`Queuing notification for user ${userId}: ${message}`);
  }
}

export function sendEmail(userId: string, subject: string, body: string): void {
  const user = users.get(userId);
  if (user) {
    console.log(`Email to ${user.email}: ${subject}`);
  }
}
