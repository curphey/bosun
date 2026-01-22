// partial-types.ts - TypeScript used inconsistently
// Some things are fully typed, others use 'any' or no types
// Shows a codebase in transition from JS to TS

// Well-typed interface
interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user' | 'guest';
  createdAt: Date;
  preferences: UserPreferences;
}

interface UserPreferences {
  theme: 'light' | 'dark';
  notifications: boolean;
  language: string;
}

// Another good interface
interface Product {
  id: string;
  name: string;
  price: number;
  inventory: number;
  category: string;
}

// Then suddenly... any everywhere
interface Order {
  id: string;
  userId: string;
  items: any[]; // Should be OrderItem[]
  total: any; // Should be number
  metadata: any; // What's in here?
  status: any; // Should be union type
}

// Well-typed function
function createUser(email: string, name: string, role: User['role']): User {
  return {
    id: generateId(),
    email,
    name,
    role,
    createdAt: new Date(),
    preferences: {
      theme: 'light',
      notifications: true,
      language: 'en',
    },
  };
}

// Partially typed - return type missing
function updateUser(userId: string, updates: Partial<User>) {
  // Return type is implicitly any
  const user = getUser(userId);
  if (!user) return null;
  return { ...user, ...updates };
}

// Not typed at all - JS habits
function processOrder(order, paymentInfo) {
  // order and paymentInfo are implicitly any
  const total = order.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  return {
    orderId: order.id,
    charged: total,
    payment: paymentInfo,
  };
}

// Uses 'any' as escape hatch
function handleWebhook(event: any): any {
  switch (event.type) {
    case 'payment.success':
      return processPaymentSuccess(event.data);
    case 'payment.failed':
      return processPaymentFailed(event.data);
    default:
      return { handled: false };
  }
}

// Type assertion abuse
function getOrderTotal(order: Order): number {
  return (order.total as number) || 0; // Why cast if it should already be number?
}

function getOrderStatus(order: Order): string {
  return order.status as string; // Casting 'any' to string
}

// Inconsistent null handling
function getUser(id: string): User | null {
  // Properly returns null
  const users: User[] = [];
  return users.find((u) => u.id === id) || null;
}

function getProduct(id: string): Product | undefined {
  // Returns undefined instead of null
  const products: Product[] = [];
  return products.find((p) => p.id === id);
}

function getOrder(id: string) {
  // No return type annotation, returns undefined implicitly
  const orders: Order[] = [];
  return orders.find((o) => o.id === id);
}

// Generic function, but then uses any
function fetchData<T>(url: string): Promise<T> {
  return fetch(url).then((res) => res.json());
}

async function loadUserData(userId: string) {
  const user = await fetchData<any>(`/api/users/${userId}`); // Why any?
  const orders = await fetchData<any>(`/api/orders?userId=${userId}`); // any again
  return { user, orders };
}

// Properly typed generic
async function fetchTyped<T>(url: string): Promise<T> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json() as Promise<T>;
}

// But then not used
async function loadProducts(): Promise<any[]> {
  return fetchTyped<any[]>('/api/products'); // Still any[]
}

// Type that should be more specific
type EventHandler = (event: any) => void; // What events?

type ApiResponse = {
  data: any; // What data?
  error?: string;
  meta?: any; // What meta?
};

// Enum would be better
const ORDER_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;

// But then not used consistently
function setOrderStatus(orderId: string, status: string) {
  // Should be: status: typeof ORDER_STATUS[keyof typeof ORDER_STATUS]
  console.log(`Setting order ${orderId} to ${status}`);
}

// Utility with implicit any
function groupBy(array, key) {
  // array and key are any
  return array.reduce((groups, item) => {
    const value = item[key];
    groups[value] = groups[value] || [];
    groups[value].push(item);
    return groups;
  }, {});
}

// Should be generic
function groupByTyped<T>(array: T[], key: keyof T): Record<string, T[]> {
  return array.reduce((groups, item) => {
    const value = String(item[key]);
    groups[value] = groups[value] || [];
    groups[value].push(item);
    return groups;
  }, {} as Record<string, T[]>);
}

// Helper with no types
function generateId() {
  return Math.random().toString(36).slice(2);
}

// @ts-ignore sprinkled throughout
function legacyFunction(data) {
  // @ts-ignore - TODO: fix types later
  return data.process();
}

// @ts-expect-error used incorrectly
function anotherLegacy(input) {
  // @ts-expect-error
  return input.doSomething(); // This should have proper types
}
