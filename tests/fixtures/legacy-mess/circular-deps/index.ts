// index.ts - the tangled web of imports
// Circular dependency chain:
// user -> order -> product -> order (cycle!)
// user -> notification -> user (cycle!)

export * from './user';
export * from './order';
export * from './product';
export * from './notification';

// This barrel export makes it even harder to trace dependencies
// and can cause initialization order issues
