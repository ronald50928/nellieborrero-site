## Nellie Borrero — Site + Infra

### Structure
- `site/`: Astro static site with Tailwind
- `infra/`: Terraform modules and prod env
- `.github/workflows/deploy.yml`: CI/CD (OIDC to AWS)

### Build locally
```bash
cd site
npm i
npm run build
```

### Deploy pipeline
- PR to `main`: Build + Lighthouse CI gate (≥95 on all categories)
- Push to `main`: Build → S3 sync (HTML 300s; assets 30d immutable) → CloudFront invalidation

### Terraform (validate only for now)
```bash
cd infra/envs/prod
terraform init
terraform validate
```

Variables of interest:
- `domain_name` (default `nellieborrero.com`)
- `price_class` (default `PriceClass_100`)
- `html_ttl_seconds` (default 300)
- `asset_ttl_seconds` (default 2592000)

Est. cost: $5–$15/mo (CloudFront dominates). No servers/DBs.

