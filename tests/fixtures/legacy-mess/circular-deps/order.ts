// order.ts - imports user.ts which imports order.ts
import { User } from './user';
import { Product, updateInventory } from './product';
import { sendNotification } from './notification';

export interface Order {
  id: string;
  userId: string;
  products: Product[];
  total: number;
  status: string;
}

const orders: Order[] = [];

export function createOrder(user: User, products: Product[]): Order {
  const total = products.reduce((sum, p) => sum + p.price, 0);
  const order: Order = {
    id: generateId(),
    userId: user.id,
    products,
    total,
    status: 'pending'
  };
  orders.push(order);

  // Update inventory - circular through product
  for (const product of products) {
    updateInventory(product.id, -1);
  }

  // Notify user - circular through notification -> user
  sendNotification(user.id, `Order ${order.id} created`);

  return order;
}

export function getOrdersByUser(userId: string): Order[] {
  return orders.filter(o => o.userId === userId);
}

export function getOrderById(orderId: string): Order | undefined {
  return orders.find(o => o.id === orderId);
}

function generateId(): string {
  return Math.random().toString(36).slice(2);
}
