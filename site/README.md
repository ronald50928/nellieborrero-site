## Nellie Borrero — Static Site (Astro)

- Stack: Astro + Tailwind (no client JS by default)
- Pages: Home (`/`), Services (`/services`), About (`/about`), Privacy (`/privacy`)
- Accessibility: WCAG 2.2 AA, semantic HTML, skip links, visible focus, alt text
- Performance: target Lighthouse ≥95 across Perf/SEO/Best/Access

### Local dev

```bash
npm i
npm run dev
```

### Build

```bash
npm run build
```

### CI/CD

- PR: build + Lighthouse CI gate
- Main: build → sync S3 (HTML ~300s, assets 30d immutable) → CloudFront invalidation

### Config

- `src/config/site.ts` toggles `analyticsEnabled`
- `astro.config.mjs` sets site origin and sitemap

### Assets

- Add `public/portrait.jpg` and press logos under `public/logos/`

### License

Proprietary — © Nellie Borrero
# Astro Starter Kit: Basics

```sh
npm create astro@latest -- --template basics
```

> 🧑‍🚀 **Seasoned astronaut?** Delete this file. Have fun!

## 🚀 Project Structure

Inside of your Astro project, you'll see the following folders and files:

```text
/
├── public/
│   └── favicon.svg
├── src
│   ├── assets
│   │   └── astro.svg
│   ├── components
│   │   └── Welcome.astro
│   ├── layouts
│   │   └── Layout.astro
│   └── pages
│       └── index.astro
└── package.json
```

To learn more about the folder structure of an Astro project, refer to [our guide on project structure](https://docs.astro.build/en/basics/project-structure/).

## 🧞 Commands

All commands are run from the root of the project, from a terminal:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `npm install`             | Installs dependencies                            |
| `npm run dev`             | Starts local dev server at `localhost:4321`      |
| `npm run build`           | Build your production site to `./dist/`          |
| `npm run preview`         | Preview your build locally, before deploying     |
| `npm run astro ...`       | Run CLI commands like `astro add`, `astro check` |
| `npm run astro -- --help` | Get help using the Astro CLI                     |

## 👀 Want to learn more?

Feel free to check [our documentation](https://docs.astro.build) or jump into our [Discord server](https://astro.build/chat).
