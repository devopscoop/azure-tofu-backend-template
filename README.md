# OpenTofu remote-state storage template (Azure)

Creates one Azure storage account + blob container to hold the OpenTofu
remote state for one git repository. Vendor it into a repo as a subtree
at `azure-tofu-backend/`:

```sh
git subtree add --prefix=azure-tofu-backend <template-repo-url> main
```

Then run the two-phase procedure below, and the repo has a dedicated,
hardened state store that is itself managed as code.

Requires OpenTofu >= 1.10 and azurerm provider 4.x (set
`ARM_SUBSCRIPTION_ID`, and authenticate via `az login` or a service
principal).

What the storage gets:

- **Blob versioning** — every state write is recoverable; this is the
  safety net for a corrupted or accidentally deleted state file. Old
  versions are deleted after 90 days (configurable) so cost doesn't
  accumulate forever.
- **Soft delete** — deleted blobs and containers remain recoverable for
  30 days (configurable).
- **Encryption at rest** — always on in Azure Storage
  (Microsoft-managed keys, AES-256, cannot be disabled), plus
  infrastructure encryption for a second, independent layer. If your
  compliance posture requires customer-managed keys, add a Key Vault
  key + `azurerm_storage_account_customer_managed_key` as a local
  customization.
- **TLS-only** (`https_traffic_only_enabled`, minimum TLS 1.2) and no
  public blob access.
- **Native state locking** — the `azurerm` backend takes a blob lease
  during operations; nothing to configure.
- **`prevent_destroy`** — `tofu destroy` refuses to delete the storage
  account (and with it, the state) unless you deliberately remove the
  guard.

## Bootstrap procedure

### Phase 1 — create the storage with local state

```sh
tofu init
tofu apply -var repo_name=<repo-name>       # add -var location=... if not eastus
```

The `backend.tf` block is commented out at this point, so state lands in
a local `terraform.tfstate`. The resource group is named
`<repo_name>-tfstate`; the storage account name is derived from
repo_name (hyphens stripped, salted with a hash of the subscription id
for global uniqueness) unless you override `storage_account_name`.

### Phase 2 — migrate the state into the storage it just created

```sh
tofu output resource_group_name
tofu output storage_account_name
```

Uncomment the `terraform { backend "azurerm" { ... } }` block in
`backend.tf`, fill in the values, then:

```sh
tofu init -migrate-state
rm terraform.tfstate terraform.tfstate.backup   # local copy is now redundant
```

Commit everything. The bootstrap config's own state now lives at
`bootstrap/terraform.tfstate` inside the container it manages.

### Phase 3 — point the repo's real configuration at the storage

```sh
tofu output backend_config
```

Paste that block into the repo's main root module and `tofu init`. Use a
distinct `key` per root module (the bootstrap state uses
`bootstrap/terraform.tfstate`; the main config uses `terraform.tfstate`
by default). One storage account per repo, many keys, is fine — the rule
this template enforces is no state storage shared *across* repos.

## Pulling upstream updates

```sh
git subtree pull --prefix=azure-tofu-backend <template-repo-url> main
```

Do not use `--squash`: upstream commits should land individually in the
consuming repo's history so every change is visible, not collapsed into
one opaque sync commit.

Customize by editing these files in place — that includes the required
edits (uncommenting `backend.tf`) and any repo-specific hardening.
Local edits and upstream changes three-way merge on pull; a conflict
means upstream changed something you customized, which is exactly when
you should be looking at it. Resolve by reading the upstream change and
re-applying your customization on top. A clean merge is still worth a
skim: `git log` the new commits after pulling.

## Access notes

- By default the backend authenticates with the storage account access
  key. For a tighter posture, add `use_azuread_auth = true` to the
  backend block and grant principals the **Storage Blob Data
  Contributor** role on the container; you can then set
  `shared_access_key_enabled = false` on the storage account as a local
  customization.
- `replication_type` defaults to ZRS (survives a zone outage). Set it
  to LRS in regions without availability zones.
- Storage account activity can be audited via Azure Monitor /
  diagnostic settings on the blob service — like the AWS template's
  access logging, the log destination (Log Analytics workspace) is an
  org-level resource, so wiring it up is left as a local customization.
