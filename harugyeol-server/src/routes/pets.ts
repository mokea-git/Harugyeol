import { FastifyInstance } from 'fastify';
import { requireAuth } from '../middleware/auth';
import {
  createPet,
  deletePet,
  listPetsByUser,
  PetKind,
  PetRecord,
  updatePet,
} from '../lib/postgres';

type PetBody = {
  name?: string;
  kind?: string;
  breed?: string;
  enabled?: unknown;
};

function toPetResponse(pet: PetRecord) {
  return {
    id: pet.id,
    user_id: pet.user_id,
    name: pet.name,
    kind: pet.kind,
    breed: pet.breed,
    enabled: pet.enabled,
    created_at: pet.created_at,
    updated_at: pet.updated_at,
  };
}

function normalizeText(value: unknown, maxLength: number): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim().replace(/\s+/g, ' ');
  if (!trimmed) return null;
  return trimmed.slice(0, maxLength);
}

function normalizeBreed(value: unknown): string {
  if (typeof value !== 'string') return '';
  return value.trim().replace(/\s+/g, ' ').slice(0, 80);
}

function normalizeKind(value: unknown): PetKind | null {
  return value === 'dog' || value === 'cat' ? value : null;
}

function normalizeEnabled(value: unknown): Record<string, boolean> | null | undefined {
  if (value == null) return undefined;
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;

  const result: Record<string, boolean> = {};
  for (const [key, enabled] of Object.entries(value)) {
    if (typeof enabled !== 'boolean') return null;
    if (/^[a-zA-Z0-9_-]{1,80}$/.test(key)) {
      result[key] = enabled;
    }
  }
  return result;
}

export async function petsRoutes(fastify: FastifyInstance) {
  fastify.get(
    '/pets',
    { preHandler: requireAuth },
    async (request, reply) => {
      const pets = await listPetsByUser(request.user.id);
      return reply.send(pets.map(toPetResponse));
    },
  );

  fastify.post<{ Body: PetBody }>(
    '/pets',
    { preHandler: requireAuth },
    async (request, reply) => {
      const name = normalizeText(request.body?.name, 60);
      const kind = normalizeKind(request.body?.kind);
      const breed = normalizeBreed(request.body?.breed);
      const enabled = normalizeEnabled(request.body?.enabled);

      if (!name || !kind) {
        return reply.code(400).send({ error: 'name and kind are required' });
      }
      if (enabled === null) {
        return reply.code(400).send({ error: 'enabled must be a boolean map' });
      }

      const pet = await createPet({
        userId: request.user.id,
        name,
        kind,
        breed,
        enabled: enabled ?? {},
      });

      return reply.code(201).send(toPetResponse(pet));
    },
  );

  fastify.patch<{ Params: { id: string }; Body: PetBody }>(
    '/pets/:id',
    { preHandler: requireAuth },
    async (request, reply) => {
      let name: string | undefined;
      if (request.body?.name !== undefined) {
        const normalizedName = normalizeText(request.body.name, 60);
        if (!normalizedName) {
          return reply.code(400).send({ error: 'name cannot be empty' });
        }
        name = normalizedName;
      }

      const breed =
        request.body?.breed === undefined
          ? undefined
          : normalizeBreed(request.body.breed);
      const enabled = normalizeEnabled(request.body?.enabled);

      if (enabled === null) {
        return reply.code(400).send({ error: 'enabled must be a boolean map' });
      }
      if (name === undefined && breed === undefined && enabled === undefined) {
        return reply.code(400).send({ error: 'nothing to update' });
      }

      const updates: { name?: string; breed?: string; enabled?: Record<string, boolean> } = {};
      if (name !== undefined) updates.name = name;
      if (breed !== undefined) updates.breed = breed;
      if (enabled !== undefined) updates.enabled = enabled;

      const pet = await updatePet(request.user.id, request.params.id, updates);
      if (!pet) {
        return reply.code(404).send({ error: 'pet not found' });
      }

      return reply.send(toPetResponse(pet));
    },
  );

  fastify.delete<{ Params: { id: string } }>(
    '/pets/:id',
    { preHandler: requireAuth },
    async (request, reply) => {
      const deleted = await deletePet(request.user.id, request.params.id);
      if (!deleted) {
        return reply.code(404).send({ error: 'pet not found' });
      }
      return reply.code(204).send();
    },
  );
}
