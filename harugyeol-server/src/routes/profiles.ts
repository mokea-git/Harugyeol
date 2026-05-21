import { FastifyInstance } from 'fastify';
import { requireAuth } from '../middleware/auth';
import {
  ensureProfileFromAuthUser,
  ProfileRecord,
  updateProfileFields,
} from '../lib/sqlite';

function toProfileResponse(profile: ProfileRecord) {
  return {
    id: profile.user_id,
    email: profile.email,
    nickname: profile.name ?? '하루결 사용자',
    avatar_url: profile.image_url,
    plan: profile.plan,
  };
}

export async function profilesRoutes(fastify: FastifyInstance) {
  // POST /profiles/sync
  // OAuth 메타데이터를 기반으로 프로필을 최초 생성/동기화
  fastify.post(
    '/profiles/sync',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const profile = ensureProfileFromAuthUser({
        id: user.id,
        email: user.email,
        user_metadata: user.user_metadata,
      });

      return reply.send(toProfileResponse(profile));
    },
  );

  // GET /profiles/me
  fastify.get(
    '/profiles/me',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const profile = ensureProfileFromAuthUser({
        id: user.id,
        email: user.email,
        user_metadata: user.user_metadata,
      });

      return reply.send(toProfileResponse(profile));
    },
  );

  // PATCH /profiles/me
  fastify.patch<{ Body: { nickname?: string; avatar_url?: string } }>(
    '/profiles/me',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const nickname = request.body?.nickname?.trim();
      const avatarUrl = request.body?.avatar_url?.trim();

      if (!nickname && !avatarUrl) {
        return reply.code(400).send({ error: 'nickname or avatar_url is required' });
      }

      if (avatarUrl && avatarUrl.length > 4 * 1024 * 1024) {
        return reply.code(413).send({ error: 'avatar_url payload is too large' });
      }

      try {
        // 프로필이 없더라도 PATCH가 실패하지 않도록 먼저 보장
        ensureProfileFromAuthUser({
          id: user.id,
          email: user.email,
          user_metadata: user.user_metadata,
        });

        const profile = updateProfileFields(user.id, {
          nickname: nickname || undefined,
          avatarUrl: avatarUrl || undefined,
        });

        return reply.send(toProfileResponse(profile));
      } catch (err) {
        request.log.error({ err }, 'Failed to update profile');
        return reply.code(500).send({ error: 'failed to update profile' });
      }
    },
  );
}
