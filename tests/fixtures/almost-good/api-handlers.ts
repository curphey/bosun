// api-handlers.ts - Inconsistent style throughout
// Some functions use async/await, some use promises
// Some use camelCase, some use snake_case
// Spacing and formatting varies

import { Request, Response } from 'express';
import { db } from './database';

// Style 1: async/await, camelCase, single quotes
export async function getUser(req: Request, res: Response) {
  const userId = req.params.id;
  try {
    const user = await db.findUser(userId);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Failed to get user' });
  }
}

// Style 2: promise chains, snake_case, double quotes
export function get_orders(req: Request, res: Response) {
  const user_id = req.params.id;
  db.findOrders(user_id)
    .then(function(orders) {
      res.json(orders);
    })
    .catch(function(err) {
      res.status(500).json({ "error": "Failed to get orders" });
    });
}

// Style 3: callback-ish with no error handling
export const createProduct = (req: Request,res: Response) => {
  const {name,price,description} = req.body
  db.insertProduct({name,price,description}).then(product=>{
    res.status(201).json(product)
  })
}

// Style 4: mixed - async function but then chains
export async function updateUser(req: Request, res: Response)
{
  const userId = req.params.id
  const updates = req.body

  db.updateUser(userId, updates).then((user) =>
  {
    res.json(user)
  }).catch((err) =>
  {
    res.status(500).json({error: "Update failed"})
  })
}

// Style 5: proper async/await but inconsistent naming
export async function Delete_User(req: Request, res: Response) {
  const USER_ID = req.params.id;

  try {
    await db.deleteUser(USER_ID);
    res.status(204).send();
  }
  catch(error) {
    res.status(500).json({ Error: 'Delete failed' });
  }
}

// Style 6: arrow function, different brace style
export const listProducts = async (req: Request, res: Response) =>
{
    const category = req.query.category;
    const limit = req.query.limit || 10;

    const products = await db.findProducts({ category, limit });
    res.json(products);
}

// Some helper functions with inconsistent patterns
function formatPrice(price: number): string {
  return '$' + price.toFixed(2);
}

const format_date = (date: Date): string => {
  return date.toISOString().split('T')[0]
}

function FormatName(first: string, last: string): string
{
    return `${first} ${last}`;
}

// Inconsistent error responses
export async function searchProducts(req: Request, res: Response) {
  const query = req.query.q;

  if (!query) {
    return res.status(400).json({ error: 'Query required' }); // lowercase 'error'
  }

  try {
    const results = await db.searchProducts(query as string);
    res.json({ data: results, count: results.length });
  } catch (e) {
    res.status(500).json({ Error: 'Search failed', message: (e as Error).message }); // uppercase 'Error'
  }
}

// Inconsistent response formats
export async function getProductById(req: Request, res: Response) {
  const product = await db.findProduct(req.params.id);

  if (!product) {
    res.status(404).json({ message: 'Not found' }); // just message
    return;
  }

  res.json(product); // raw object
}

export async function getOrderById(req: Request, res: Response) {
  const order = await db.findOrder(req.params.id);

  if (!order) {
    res.status(404).json({ error: 'Order not found', code: 'NOT_FOUND' }); // error + code
    return;
  }

  res.json({ data: order, success: true }); // wrapped in data
}
