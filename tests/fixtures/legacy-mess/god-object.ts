// AppManager.ts - "The class that does everything"
// Original author left 3 years ago. Nobody wants to touch this.
// Last meaningful refactor: never

import { db } from './db';
import { logger } from './logger';
import { cache } from './cache';
import { emailService } from './email';
import { smsService } from './sms';
import { paymentGateway } from './payment';
import { analyticsTracker } from './analytics';
import { featureFlags } from './features';

interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  role: string;
  preferences: Record<string, any>;
  createdAt: Date;
  lastLogin?: Date;
}

interface Order {
  id: string;
  userId: string;
  items: OrderItem[];
  total: number;
  status: string;
  createdAt: Date;
}

interface OrderItem {
  productId: string;
  quantity: number;
  price: number;
}

interface Product {
  id: string;
  name: string;
  price: number;
  inventory: number;
  category: string;
}

// THE GOD OBJECT - handles users, orders, products, notifications, payments, reports, and more
export class AppManager {
  private static instance: AppManager;
  private users: Map<string, User> = new Map();
  private orders: Map<string, Order> = new Map();
  private products: Map<string, Product> = new Map();
  private sessions: Map<string, any> = new Map();
  private rateLimits: Map<string, number[]> = new Map();
  private notificationQueue: any[] = [];
  private reportCache: Map<string, any> = new Map();

  private constructor() {
    // Singleton - because of course it is
  }

  static getInstance(): AppManager {
    if (!AppManager.instance) {
      AppManager.instance = new AppManager();
    }
    return AppManager.instance;
  }

  // ========== USER MANAGEMENT (should be UserService) ==========

  async createUser(email: string, name: string, role: string = 'user'): Promise<User> {
    const id = this.generateId();
    const user: User = {
      id,
      email,
      name,
      role,
      preferences: {},
      createdAt: new Date()
    };

    await db.query('INSERT INTO users VALUES ($1, $2, $3, $4)', [id, email, name, role]);
    this.users.set(id, user);
    cache.set(`user:${id}`, user);

    // Send welcome email - why is this here?
    await this.sendWelcomeEmail(user);

    // Track analytics - why is this here too?
    analyticsTracker.track('user_created', { userId: id });

    logger.info(`User created: ${id}`);
    return user;
  }

  async getUser(id: string): Promise<User | null> {
    // Check memory cache
    if (this.users.has(id)) {
      return this.users.get(id)!;
    }

    // Check distributed cache
    const cached = await cache.get(`user:${id}`);
    if (cached) {
      this.users.set(id, cached);
      return cached;
    }

    // Database fallback
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    if (result.rows.length === 0) return null;

    const user = result.rows[0];
    this.users.set(id, user);
    cache.set(`user:${id}`, user);
    return user;
  }

  async updateUser(id: string, updates: Partial<User>): Promise<User | null> {
    const user = await this.getUser(id);
    if (!user) return null;

    const updated = { ...user, ...updates };
    await db.query('UPDATE users SET email=$2, name=$3 WHERE id=$1', [id, updated.email, updated.name]);
    this.users.set(id, updated);
    cache.set(`user:${id}`, updated);

    // Notify about profile change - really shouldn't be here
    if (updates.email) {
      await this.sendEmailChangeNotification(user.email, updates.email);
    }

    return updated;
  }

  async deleteUser(id: string): Promise<boolean> {
    const user = await this.getUser(id);
    if (!user) return false;

    // Cancel all pending orders - tight coupling
    const userOrders = await this.getOrdersByUser(id);
    for (const order of userOrders) {
      if (order.status === 'pending') {
        await this.cancelOrder(order.id);
      }
    }

    await db.query('DELETE FROM users WHERE id = $1', [id]);
    this.users.delete(id);
    cache.del(`user:${id}`);

    // GDPR compliance mixed in
    await this.anonymizeUserData(id);

    logger.info(`User deleted: ${id}`);
    return true;
  }

  async authenticateUser(email: string, password: string): Promise<string | null> {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) return null;

    const user = result.rows[0];
    // Password check would be here...

    const sessionId = this.generateId();
    this.sessions.set(sessionId, { userId: user.id, createdAt: new Date() });

    user.lastLogin = new Date();
    await this.updateUser(user.id, { lastLogin: user.lastLogin });

    analyticsTracker.track('user_login', { userId: user.id });
    return sessionId;
  }

  async logout(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (session) {
      analyticsTracker.track('user_logout', { userId: session.userId });
    }
    this.sessions.delete(sessionId);
  }

  // ========== ORDER MANAGEMENT (should be OrderService) ==========

  async createOrder(userId: string, items: OrderItem[]): Promise<Order> {
    const user = await this.getUser(userId);
    if (!user) throw new Error('User not found');

    // Check inventory - why is this inline?
    for (const item of items) {
      const product = await this.getProduct(item.productId);
      if (!product || product.inventory < item.quantity) {
        throw new Error(`Insufficient inventory for ${item.productId}`);
      }
    }

    const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    const id = this.generateId();

    const order: Order = {
      id,
      userId,
      items,
      total,
      status: 'pending',
      createdAt: new Date()
    };

    await db.query('INSERT INTO orders VALUES ($1, $2, $3, $4)', [id, userId, total, 'pending']);
    this.orders.set(id, order);

    // Update inventory - tight coupling
    for (const item of items) {
      await this.decrementInventory(item.productId, item.quantity);
    }

    // Send confirmation - shouldn't be here
    await this.sendOrderConfirmation(user, order);

    analyticsTracker.track('order_created', { orderId: id, total });
    return order;
  }

  async getOrder(id: string): Promise<Order | null> {
    if (this.orders.has(id)) {
      return this.orders.get(id)!;
    }

    const result = await db.query('SELECT * FROM orders WHERE id = $1', [id]);
    if (result.rows.length === 0) return null;

    const order = result.rows[0];
    this.orders.set(id, order);
    return order;
  }

  async getOrdersByUser(userId: string): Promise<Order[]> {
    const result = await db.query('SELECT * FROM orders WHERE user_id = $1', [userId]);
    return result.rows;
  }

  async updateOrderStatus(id: string, status: string): Promise<Order | null> {
    const order = await this.getOrder(id);
    if (!order) return null;

    order.status = status;
    await db.query('UPDATE orders SET status = $1 WHERE id = $2', [status, id]);
    this.orders.set(id, order);

    // Notifications based on status - complex branching
    const user = await this.getUser(order.userId);
    if (user) {
      switch (status) {
        case 'confirmed':
          await this.sendOrderConfirmedNotification(user, order);
          break;
        case 'shipped':
          await this.sendShippingNotification(user, order);
          break;
        case 'delivered':
          await this.sendDeliveryNotification(user, order);
          await this.requestReview(user, order);
          break;
        case 'cancelled':
          await this.sendCancellationNotification(user, order);
          // Restore inventory
          for (const item of order.items) {
            await this.incrementInventory(item.productId, item.quantity);
          }
          break;
      }
    }

    return order;
  }

  async cancelOrder(id: string): Promise<boolean> {
    return (await this.updateOrderStatus(id, 'cancelled')) !== null;
  }

  // ========== PRODUCT MANAGEMENT (should be ProductService) ==========

  async createProduct(name: string, price: number, inventory: number, category: string): Promise<Product> {
    const id = this.generateId();
    const product: Product = { id, name, price, inventory, category };

    await db.query('INSERT INTO products VALUES ($1, $2, $3, $4, $5)', [id, name, price, inventory, category]);
    this.products.set(id, product);
    cache.set(`product:${id}`, product);

    // Invalidate category cache
    cache.del(`products:category:${category}`);

    return product;
  }

  async getProduct(id: string): Promise<Product | null> {
    if (this.products.has(id)) {
      return this.products.get(id)!;
    }

    const cached = await cache.get(`product:${id}`);
    if (cached) {
      this.products.set(id, cached);
      return cached;
    }

    const result = await db.query('SELECT * FROM products WHERE id = $1', [id]);
    if (result.rows.length === 0) return null;

    const product = result.rows[0];
    this.products.set(id, product);
    cache.set(`product:${id}`, product);
    return product;
  }

  async updateProduct(id: string, updates: Partial<Product>): Promise<Product | null> {
    const product = await this.getProduct(id);
    if (!product) return null;

    const updated = { ...product, ...updates };
    await db.query('UPDATE products SET name=$2, price=$3, inventory=$4 WHERE id=$1',
      [id, updated.name, updated.price, updated.inventory]);

    this.products.set(id, updated);
    cache.set(`product:${id}`, updated);

    // Price change notification - really?
    if (updates.price && updates.price < product.price) {
      await this.notifyPriceDropWatchers(product, updates.price);
    }

    return updated;
  }

  async decrementInventory(productId: string, quantity: number): Promise<void> {
    const product = await this.getProduct(productId);
    if (!product) throw new Error('Product not found');

    product.inventory -= quantity;
    await db.query('UPDATE products SET inventory = $1 WHERE id = $2', [product.inventory, productId]);
    this.products.set(productId, product);
    cache.set(`product:${productId}`, product);

    // Low stock alert - shouldn't be here
    if (product.inventory < 10) {
      await this.sendLowStockAlert(product);
    }
  }

  async incrementInventory(productId: string, quantity: number): Promise<void> {
    const product = await this.getProduct(productId);
    if (!product) throw new Error('Product not found');

    product.inventory += quantity;
    await db.query('UPDATE products SET inventory = $1 WHERE id = $2', [product.inventory, productId]);
    this.products.set(productId, product);
    cache.set(`product:${productId}`, product);
  }

  async getProductsByCategory(category: string): Promise<Product[]> {
    const cached = await cache.get(`products:category:${category}`);
    if (cached) return cached;

    const result = await db.query('SELECT * FROM products WHERE category = $1', [category]);
    cache.set(`products:category:${category}`, result.rows, 300); // 5 min TTL
    return result.rows;
  }

  // ========== NOTIFICATION MANAGEMENT (should be NotificationService) ==========

  private async sendWelcomeEmail(user: User): Promise<void> {
    await emailService.send({
      to: user.email,
      subject: 'Welcome!',
      template: 'welcome',
      data: { name: user.name }
    });
  }

  private async sendEmailChangeNotification(oldEmail: string, newEmail: string): Promise<void> {
    await emailService.send({
      to: oldEmail,
      subject: 'Email Changed',
      template: 'email-changed',
      data: { newEmail }
    });
  }

  private async sendOrderConfirmation(user: User, order: Order): Promise<void> {
    await emailService.send({
      to: user.email,
      subject: `Order Confirmed: ${order.id}`,
      template: 'order-confirmation',
      data: { order }
    });

    if (user.phone) {
      await smsService.send(user.phone, `Order ${order.id} confirmed. Total: $${order.total}`);
    }
  }

  private async sendOrderConfirmedNotification(user: User, order: Order): Promise<void> {
    await emailService.send({
      to: user.email,
      subject: `Order ${order.id} Processing`,
      template: 'order-processing',
      data: { order }
    });
  }

  private async sendShippingNotification(user: User, order: Order): Promise<void> {
    await emailService.send({
      to: user.email,
      subject: `Order ${order.id} Shipped`,
      template: 'order-shipped',
      data: { order }
    });

    if (user.phone) {
      await smsService.send(user.phone, `Order ${order.id} has shipped!`);
    }
  }

  private async sendDeliveryNotification(user: User, order: Order): Promise<void> {
    await emailService.send({
      to: user.email,
      subject: `Order ${order.id} Delivered`,
      template: 'order-delivered',
      data: { order }
    });
  }

  private async sendCancellationNotification(user: User, order: Order): Promise<void> {
    await emailService.send({
      to: user.email,
      subject: `Order ${order.id} Cancelled`,
      template: 'order-cancelled',
      data: { order }
    });
  }

  private async requestReview(user: User, order: Order): Promise<void> {
    // Queue review request for 3 days later - scheduling in a god object??
    this.notificationQueue.push({
      type: 'review_request',
      userId: user.id,
      orderId: order.id,
      sendAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)
    });
  }

  private async sendLowStockAlert(product: Product): Promise<void> {
    // Email ops team - hardcoded!
    await emailService.send({
      to: 'ops@company.com',
      subject: `Low Stock Alert: ${product.name}`,
      template: 'low-stock',
      data: { product }
    });
  }

  private async notifyPriceDropWatchers(product: Product, newPrice: number): Promise<void> {
    const watchers = await db.query('SELECT user_id FROM price_watchers WHERE product_id = $1', [product.id]);
    for (const row of watchers.rows) {
      const user = await this.getUser(row.user_id);
      if (user) {
        await emailService.send({
          to: user.email,
          subject: `Price Drop: ${product.name}`,
          template: 'price-drop',
          data: { product, newPrice, oldPrice: product.price }
        });
      }
    }
  }

  // ========== PAYMENT PROCESSING (should be PaymentService) ==========

  async processPayment(orderId: string, paymentMethod: any): Promise<boolean> {
    const order = await this.getOrder(orderId);
    if (!order) throw new Error('Order not found');

    // Rate limiting - why is this here??
    const userId = order.userId;
    if (!this.checkRateLimit(userId, 'payment', 5, 60000)) {
      throw new Error('Too many payment attempts');
    }

    try {
      const result = await paymentGateway.charge({
        amount: order.total,
        currency: 'USD',
        method: paymentMethod
      });

      if (result.success) {
        await this.updateOrderStatus(orderId, 'confirmed');
        analyticsTracker.track('payment_success', { orderId, amount: order.total });
        return true;
      } else {
        analyticsTracker.track('payment_failed', { orderId, reason: result.error });
        return false;
      }
    } catch (error) {
      logger.error('Payment processing failed', { orderId, error });
      throw error;
    }
  }

  async refundOrder(orderId: string): Promise<boolean> {
    const order = await this.getOrder(orderId);
    if (!order) throw new Error('Order not found');

    try {
      const result = await paymentGateway.refund({
        orderId,
        amount: order.total
      });

      if (result.success) {
        await this.updateOrderStatus(orderId, 'refunded');

        const user = await this.getUser(order.userId);
        if (user) {
          await emailService.send({
            to: user.email,
            subject: `Refund Processed: ${orderId}`,
            template: 'refund-processed',
            data: { order }
          });
        }

        return true;
      }
      return false;
    } catch (error) {
      logger.error('Refund processing failed', { orderId, error });
      throw error;
    }
  }

  // ========== REPORTING (should be ReportService) ==========

  async generateSalesReport(startDate: Date, endDate: Date): Promise<any> {
    const cacheKey = `report:sales:${startDate.toISOString()}:${endDate.toISOString()}`;

    if (this.reportCache.has(cacheKey)) {
      return this.reportCache.get(cacheKey);
    }

    const orders = await db.query(
      'SELECT * FROM orders WHERE created_at BETWEEN $1 AND $2',
      [startDate, endDate]
    );

    const report = {
      period: { start: startDate, end: endDate },
      totalOrders: orders.rows.length,
      totalRevenue: orders.rows.reduce((sum: number, o: any) => sum + o.total, 0),
      averageOrderValue: 0,
      ordersByStatus: {} as Record<string, number>,
      topProducts: [] as any[]
    };

    report.averageOrderValue = report.totalRevenue / report.totalOrders || 0;

    // Count by status
    for (const order of orders.rows) {
      report.ordersByStatus[order.status] = (report.ordersByStatus[order.status] || 0) + 1;
    }

    this.reportCache.set(cacheKey, report);
    return report;
  }

  async generateUserReport(): Promise<any> {
    const users = await db.query('SELECT * FROM users');
    const orders = await db.query('SELECT user_id, COUNT(*) as order_count, SUM(total) as total_spent FROM orders GROUP BY user_id');

    return {
      totalUsers: users.rows.length,
      usersByRole: this.groupBy(users.rows, 'role'),
      topSpenders: orders.rows.sort((a: any, b: any) => b.total_spent - a.total_spent).slice(0, 10)
    };
  }

  // ========== UTILITY METHODS (mixed concerns) ==========

  private generateId(): string {
    return Math.random().toString(36).substring(2, 15);
  }

  private checkRateLimit(key: string, action: string, limit: number, windowMs: number): boolean {
    const fullKey = `${key}:${action}`;
    const now = Date.now();
    const timestamps = this.rateLimits.get(fullKey) || [];

    // Remove old timestamps
    const validTimestamps = timestamps.filter(t => now - t < windowMs);

    if (validTimestamps.length >= limit) {
      return false;
    }

    validTimestamps.push(now);
    this.rateLimits.set(fullKey, validTimestamps);
    return true;
  }

  private groupBy(array: any[], key: string): Record<string, any[]> {
    return array.reduce((groups, item) => {
      const value = item[key];
      groups[value] = groups[value] || [];
      groups[value].push(item);
      return groups;
    }, {});
  }

  private async anonymizeUserData(userId: string): Promise<void> {
    // GDPR data anonymization
    await db.query('UPDATE users SET email = $1, name = $2 WHERE id = $3',
      [`deleted-${userId}@anonymized.com`, 'Deleted User', userId]);
    await db.query('UPDATE orders SET user_id = $1 WHERE user_id = $2', ['anonymized', userId]);
  }

  // ========== FEATURE FLAGS (why is this here??) ==========

  isFeatureEnabled(feature: string, userId?: string): boolean {
    return featureFlags.isEnabled(feature, userId);
  }

  // ========== SEARCH (definitely should be SearchService) ==========

  async searchProducts(query: string): Promise<Product[]> {
    // Basic search - no indexing, will be slow
    const result = await db.query(
      "SELECT * FROM products WHERE name ILIKE $1 OR category ILIKE $1",
      [`%${query}%`]
    );
    return result.rows;
  }

  async searchUsers(query: string): Promise<User[]> {
    const result = await db.query(
      "SELECT * FROM users WHERE email ILIKE $1 OR name ILIKE $1",
      [`%${query}%`]
    );
    return result.rows;
  }
}

// The singleton export that makes testing impossible
export const appManager = AppManager.getInstance();
