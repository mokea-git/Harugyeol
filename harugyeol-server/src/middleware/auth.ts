import { FastifyRequest, FastifyReply } from 'fastify';
import { getUserFromToken } from '../lib/supabase';

// 요청에 user를 붙여주는 훅
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

  // request에 user 정보 주입
  (request as any).user = user;
}
