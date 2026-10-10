import { PGlite } from '@electric-sql/pglite';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const donor = '00000000-0000-4000-8000-000000000001';
const rescuer = '00000000-0000-4000-8000-000000000002';
const outsider = '00000000-0000-4000-8000-000000000003';
const org = '10000000-0000-4000-8000-000000000001';
const listing = '20000000-0000-4000-8000-000000000001';

async function database() {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema auth to anon, authenticated;
    grant execute on function auth.uid() to anon, authenticated;
    -- Supabase installations may grant broad table privileges by default.
    alter default privileges in schema public grant all on tables to anon, authenticated;
  `);
  for (const file of ['0001_core_schema.sql', '0002_rls.sql', '0003_claim_rescue.sql', '0004_donation_receipts.sql']) {
    const sql = await readFile(new URL(`../supabase/migrations/${file}`, import.meta.url), 'utf8');
    // gen_random_uuid is built into PostgreSQL; this WASM engine does not ship pgcrypto.
    await db.exec(sql.replace('create extension if not exists pgcrypto;', ''));
  }
  await db.exec(`
    insert into auth.users values ('${donor}'), ('${rescuer}'), ('${outsider}');
    insert into public.profiles(id,display_name) values
      ('${donor}','Donor'), ('${rescuer}','Rescuer'), ('${outsider}','Other');
    insert into public.donor_organizations(id,owner_id,name,kind,address_text)
      values ('${org}','${donor}','Donor kitchen','restaurant','Test address');
    insert into public.food_listings(id,donor_id,title,servings,pickup_address,pickup_end)
      values ('${listing}','${donor}','Fresh food',2,'Test pickup',now()+interval '1 hour');
  `);
  return db;
}

async function asUser(db, user, sql, params = []) {
  return db.transaction(async tx => {
    await tx.exec(`set local role ${user ? 'authenticated' : 'anon'}`);
    await tx.query("select set_config('request.jwt.claim.sub', $1, true)", [user || '']);
    return tx.query(sql, params);
  });
}

test('rescuer claims another donor listing and the result persists exactly once', async () => {
  const db = await database();
  try {
    const result = await asUser(db, rescuer, 'select * from public.claim_food_rescue($1)', [listing]);
    assert.equal(result.rows[0].rescuer_id, rescuer);
    const saved = await asUser(db, rescuer, 'select * from public.claims where listing_id=$1', [listing]);
    assert.equal(saved.rows.length, 1);
    assert.equal(saved.rows[0].id, result.rows[0].id);
    assert.equal((await db.query('select status from public.food_listings where id=$1', [listing])).rows[0].status, 'claimed');
    await assert.rejects(asUser(db, outsider, 'select * from public.claim_food_rescue($1)', [listing]));
    assert.equal((await db.query('select count(*)::int as n from public.claims')).rows[0].n, 1);
  } finally { await db.close(); }
});

test('claim rejects anonymous, expired and cancelled requests without partial writes', async () => {
  const db = await database();
  try {
    await assert.rejects(asUser(db, null, 'select * from public.claim_food_rescue($1)', [listing]));
    await db.exec(`update public.food_listings set pickup_start=now()-interval '2 hours', pickup_end=now()-interval '1 hour'`);
    await assert.rejects(asUser(db, rescuer, 'select * from public.claim_food_rescue($1)', [listing]));
    await db.exec(`update public.food_listings set pickup_end=now()+interval '1 hour',status='cancelled'`);
    await assert.rejects(asUser(db, rescuer, 'select * from public.claim_food_rescue($1)', [listing]));
    assert.equal((await db.query('select count(*)::int as n from public.claims')).rows[0].n, 0);
  } finally { await db.close(); }
});

test('listing cannot impersonate another donor organization on insert or update', async () => {
  const db = await database();
  try {
    await assert.rejects(asUser(db, rescuer,
      'insert into public.food_listings(donor_id,organization_id,title,servings,pickup_address,pickup_end) values ($1,$2,\'Other food\',2,\'Pickup\',now()+interval \'1 hour\')', [rescuer, org]));
    const own = await asUser(db, rescuer,
      'insert into public.food_listings(donor_id,title,servings,pickup_address,pickup_end) values ($1,\'Own food\',2,\'Pickup\',now()+interval \'1 hour\') returning id', [rescuer]);
    await assert.rejects(asUser(db, rescuer, 'update public.food_listings set organization_id=$1 where id=$2', [org, own.rows[0].id]));
    const valid = await asUser(db, donor, 'update public.food_listings set organization_id=$1 where id=$2 returning id', [org, listing]);
    assert.equal(valid.rows.length, 1);
  } finally { await db.close(); }
});

test('organization owners cannot self-verify on insert or update', async () => {
  const db = await database();
  try {
    await assert.rejects(asUser(db, donor, 'update public.donor_organizations set verified_at=now() where id=$1', [org]));
    await assert.rejects(asUser(db, rescuer,
      "insert into public.donor_organizations(owner_id,name,kind,address_text,verified_at) values ($1,'Fake verified','restaurant','Address',now())", [rescuer]));
    const changed = await asUser(db, donor, 'update public.donor_organizations set name=$1 where id=$2 returning name', ['Renamed kitchen', org]);
    assert.equal(changed.rows[0].name, 'Renamed kitchen');
  } finally { await db.close(); }
});

test('only organization owner can delete it', async () => {
  const db = await database();
  try {
    const denied = await asUser(db, outsider, 'delete from public.donor_organizations where id=$1 returning id', [org]);
    assert.equal(denied.rows.length, 0);
    const removed = await asUser(db, donor, 'delete from public.donor_organizations where id=$1 returning id', [org]);
    assert.equal(removed.rows.length, 1);
  } finally { await db.close(); }
});
