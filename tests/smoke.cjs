// Deterministic, dependency-free smoke tests for the inline local-first MVP.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const { randomUUID } = require("node:crypto");

const html = fs.readFileSync("index.html", "utf8");
const js = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert(js, "Expected inline app script");

const storage = new Map();
const nodes = new Map();
function node(id) {
  if (!nodes.has(id)) {
    nodes.set(id, {
      value: "", innerHTML: "", textContent: "", onclick: null,
      style: {},
      classList: { add() {}, remove() {}, toggle() {} },
      addEventListener() {}, focus() {}, setSelectionRange() {}, click() {}
    });
  }
  return nodes.get(id);
}

const ctx = vm.createContext({
  console, Date, Number, Math, JSON, String, Array, URL, Blob,
  structuredClone, crypto: { randomUUID },
  window: { open() {} },
  document: { documentElement: {lang: "zh-CN"}, getElementById: node, createElement: () => node("a") },
  localStorage: {
    getItem(key) {return storage.get(key) ?? null},
    setItem(key,value) {storage.set(key,value)}
  },
  alert(message) {throw new Error(String(message))},
  confirm() {return true},
  setTimeout() {}
});
vm.runInContext(js, ctx);
const evaluate = (expr) => vm.runInContext(expr, ctx);
assert.equal(evaluate("db.exercises.length"), 26);
assert.equal(evaluate("getFiltered().length"), 26);

// Bilingual names and cross-language search are based on the same ID.
evaluate('switchLang("en")');
assert.equal(evaluate('nm(ex("seed-0"))'), "Romanian Deadlift");
evaluate('setFilter("罗马尼亚")');
assert.equal(evaluate("getFiltered().length"), 1);
assert.equal(evaluate("getFiltered()[0].id"), "seed-0");
evaluate('switchLang("zh")');
assert.equal(evaluate('nm(ex("seed-0"))'), "罗马尼亚硬拉");

// Start a template session, record a set, and save it.
evaluate('go("workout")');
evaluate('startWorkout("tpl-legs")');
assert.equal(evaluate("db.draft.exercises.length"), 4);
evaluate('changeSet(1,0,"weight_kg","60")');
evaluate('changeSet(1,0,"reps","8")');
evaluate("toggleSet(1,0)");
evaluate("finishWorkout()");
assert.equal(evaluate("db.sessions.length"), 1);
assert.equal(evaluate("db.draft"), null);

// Reopening a fresh session pre-fills last recorded result.
evaluate('go("workout")');
evaluate("startWorkout(null)");
evaluate("pickExercise('draft')");
evaluate("appendExercise('seed-0')");
assert.equal(evaluate("db.draft.exercises[0].sets[0].weight_kg"), 60);
assert.equal(evaluate("db.draft.exercises[0].sets[0].reps"), 8);

// Progress persists locally, and locale toggles do not delete the draft.
evaluate('switchLang("en")');
assert.equal(evaluate("db.draft.exercises.length"), 1);
const saved = JSON.parse(storage.get("bilingual-workout-v1"));
assert.equal(saved.sessions.length, 1);
assert.equal(saved.draft.exercises.length, 1);
assert.equal(saved.lang, "en");

console.log("MVP smoke tests passed: catalog, bilingual search, template, logging, history, prefill, persistence.");
