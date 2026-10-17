# Design review site (template)

A static site for a **major** change's Mobi screens, with an "Ask about this design" bot that answers only from the spec folder and cites its sources. It lives in the spec folder at `review-site/`, so its source is committed with the spec.

## Use it

1. Copy this folder to `docs/superpowers/specs/<date>-<topic>/review-site/`.
2. Fill in `site.config.json`:
   - `feature`, `issue` and `approver`;
   - `guideDirs` (for example `["../../../../wiki/mobi/<section>"]`);
   - two to six `examples`.
3. Add one page per screen, named `<slug>.html`. Each page needs:
   - a `<title>` (the part before ` · ` is the screen's name);
   - a `<details class="review"><summary>…</summary><ul><li>…</li></ul></details>` note saying what to review;
   - the button `<a class="ask-fab" href="ask.html?screen=<slug>">Ask about this design</a>`, with `ask-fab.css` linked.

   Use `mobi-proto.css` for Mobi's tokens.
4. Build: `node scripts/build-knowledge.mjs`.
   - It writes `index.html` (from `index.template.html`, listing every screen), `ask.html`, and the bot's knowledge in `api/`.
   - It refuses to write anything if a customer name or a secret is found anywhere it would publish (the documents, every page, style and script, and the config values), or if there's no names list on this machine (`VSD_CUSTOMER_NAMES` or `~/.config/verosoft/customer-names.txt`).
   - The generated files are gitignored, so the spec has no second copy. Deploys still upload them, because Vercel follows `.vercelignore`.
5. Deploy: `npm install`, then `vercel deploy --prod --scope verosoft-design`. The bot uses the AI Gateway model `anthropic/claude-sonnet-5.5`.

## What the bot never sees

- Decision-log rows whose ID starts with `SEC`.
- Anything between `<!-- internal -->` and `<!-- /internal -->`.

Any other mention of a security ID (`SEC…` followed by a number) stops the build, so mark it internal before deploying.

The site is public to anyone with the link. If the spec holds security findings or anything internal, mark them that way, or turn on Vercel deployment protection.
