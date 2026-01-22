// user.ts - imports order.ts which imports user.ts
import { Order, getOrdersByUser } from './order';
import { sendNotification } from './notification';

export interface User {
  id: string;
  email: string;
  name: string;
}

export function createUser(email: string, name: string): User {
  const user = { id: generateId(), email, name };
  sendNotification(user.id, 'Welcome!'); // notification imports user
  return user;
}

export function getUserOrders(userId: string): Order[] {
  return getOrdersByUser(userId); // order imports user
}

export function deleteUser(userId: string): void {
  // Cancel all orders first
  const orders = getUserOrders(userId);
  for (const order of orders) {
    // This creates a dependency mess
    order.status = 'cancelled';
  }
}

function generateId(): string {
  return Math.random().toString(36).slice(2);
}
