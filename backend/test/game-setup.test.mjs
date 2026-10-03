import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readdirSync, readFileSync } from 'node:fs';
import worker from '../.test-build/index.js';

function database() {
  const db = new DatabaseSync(':memory:');
  for (const name of readdirSync('migrations').sort()) {
    db.exec(readFileSync(`migrations/${name}`, 'utf8'));
  }
  const wrapper = {
    prepare(sql) {
      const statement = db.prepare(sql);
      let args = [];
      return {
        bind(...values) { args = values; return this; },
        async first() { return statement.get(...args) ?? null; },
        async all() { return { results: statement.all(...args) }; },
        async run() { return statement.run(...args); },
      };
    },
    async batch(statements) {
      db.exec('BEGIN');
      try {
        const results = [];
        for (const statement of statements) results.push(await statement.run());
        db.exec('COMMIT');
        return results;
      } catch (error) { db.exec('ROLLBACK'); throw error; }
    },
  };
  return { db, wrapper };
}

const boundary = [[52.5,5.7],[52.5,5.72],[52.52,5.72],[52.52,5.7]];
const questions = ['Ben je op de fiets?', 'Draag je een jas?', 'Heb je een hond?'];

test('register, create, list and reopen preserve questions and polygon in migrated SQLite', async () => {
  const {db, wrapper} = database();
  const env = {DB: wrapper, PLAYER_TOKEN_SECRET: 'test-only-signing-secret', ADMIN_API_TOKEN: 'test-only'};
  let token;
  async function call(path, body) {
    return worker.fetch(new Request(`https://test.invalid${path}`, {
      method: body ? 'POST' : 'GET',
      headers: { 'content-type': 'application/json', ...(token ? {authorization: `Bearer ${token}`} : {}) },
      ...(body ? {body: JSON.stringify(body)} : {}),
    }), env);
  }
  try {
    const registration = await call('/api/v1/auth/player', {profileName: 'Testspeler'});
    assert.equal(registration.status, 201);
    token = (await registration.json()).token;
    const body = {
      id: 'setup-test', name: 'Gebiedstest', startsAt: new Date(Date.now()+3600000).toISOString(),
      maxParticipants: 10, durationMinutes: 120, isPublic: true,
      questionsEnabled: true, questionCount: 3, customQuestions: questions, playBoundary: boundary,
    };
    const created = await call('/api/v1/games', body);
    assert.equal(created.status, 201, await created.clone().text());
    for (const path of ['/api/v1/games', '/api/v1/games/setup-test']) {
      const response = await call(path);
      assert.equal(response.status, 200);
      const data = await response.json();
      const game = data.game ?? data.games[0];
      assert.deepEqual(JSON.parse(game.custom_questions), questions);
      assert.deepEqual(JSON.parse(game.play_boundary), boundary);
      assert.equal(game.question_count, 3);
      assert.equal(game.participant_count, 1);
    }
    assert.equal(db.prepare('SELECT count(*) AS n FROM games').get().n, 1);
    const invalid = [
      {questionCount: 4, customQuestions: [...questions, 'Extra?']},
      {customQuestions: [' ', 'Draag je een jas?', 'Heb je een hond?']},
      {customQuestions: ['Fiets?', 'Draag je een jas?', 'Heb je een hond?']},
      {customQuestions: ['Vraag?', 'vraag?', 'Anders?']},
      {customQuestions: ['x'.repeat(161), 'Twee?', 'Drie?']},
      {playBoundary: [[52,5],[53,6],[52,6],[53,5]]},
      {playBoundary: [[52,5],[52,5],[52,5]]},
      {playBoundary: [[999,5],[53,6],[52,6]]},
      {playBoundary: []},
      {questionsEnabled: false},
    ];
    for (const overrides of invalid) {
      const result = await call('/api/v1/games', {...body, id: 'invalid', ...overrides});
      assert.equal(result.status, 400, JSON.stringify(overrides));
    }
    assert.equal(db.prepare('SELECT count(*) AS n FROM games').get().n, 1);
    const five = await call('/api/v1/games', {...body, id:'five', questionCount:5,
      customQuestions:[...questions,'Heb je een fiets?','Draag je een bril?']});
    assert.equal(five.status, 201);
    const disabled = await call('/api/v1/games', {...body, id:'disabled', questionsEnabled:false,customQuestions:[]});
    assert.equal(disabled.status, 201);
    const {playBoundary, customQuestions, ...legacy} = body;
    assert.equal((await call('/api/v1/games', {...legacy,id:'legacy'})).status,201);
    const old = (await (await call('/api/v1/games/legacy')).json()).game;
    assert.equal(old.play_boundary, '[]');
    assert.equal(old.custom_questions, '[]');
  } finally { db.close(); }
});
