// product.ts - imports order.ts for sales stats
import { getOrderById } from './order';

export interface Product {
  id: string;
  name: string;
  price: number;
  inventory: number;
}

const products: Map<string, Product> = new Map();

export function createProduct(name: string, price: number, inventory: number): Product {
  const product: Product = {
    id: generateId(),
    name,
    price,
    inventory
  };
  products.set(product.id, product);
  return product;
}

export function getProduct(id: string): Product | undefined {
  return products.get(id);
}

export function updateInventory(productId: string, delta: number): void {
  const product = products.get(productId);
  if (product) {
    product.inventory += delta;
  }
}

// This creates circular dependency with order.ts
export function getProductSalesCount(productId: string, orderId: string): number {
  const order = getOrderById(orderId); // imports from order.ts
  if (!order) return 0;
  return order.products.filter(p => p.id === productId).length;
}

function generateId(): string {
  return Math.random().toString(36).slice(2);
}
