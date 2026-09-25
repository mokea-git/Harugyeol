import { FastifyRequest, FastifyReply } from 'fastify';
import { getUserFromToken } from '../lib/supabase';

export async function requireAuth(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  const authHeader = request.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return reply.code(401).send({ error: 'Missing Authorization header' });
  }

  const token = authHeader.slice(7);
  const user = await getUserFromToken(token);

  if (!user) {
    return reply.code(401).send({ error: 'Invalid or expired token' });
  }

  request.user = user;
}
