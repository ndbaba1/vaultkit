---

## 🚀 Quick Start (Local Development)

### 1. Clone the repository
```bash
git clone git@github.com:ndbaba1/vaultkit.git
cd vaultkit
```

### 2. Create secrets
```bash
cp .env.example infra/secrets/.env
```

Edit `infra/secrets/.env`:
```env
POSTGRES_USER=vaultkit
POSTGRES_PASSWORD=secret
POSTGRES_DB=vaultkit_development
DATABASE_URL=postgres://vaultkit:secret@postgres:5432/vaultkit_development
FUNL_URL=http://funl-runtime:8080
RAILS_ENV=development
```

### 3. Add signing keys
```bash
infra/secrets/vkit_pub.pem
infra/secrets/vkit_priv.pem
```

These keys are used to sign and verify access grants.

### 4. Start VaultKit
```bash
cd infra
docker compose up --build
```

**Services:**
- Control Plane → http://localhost:3000
- FUNL Runtime → http://localhost:8080
- Postgres → localhost:5432