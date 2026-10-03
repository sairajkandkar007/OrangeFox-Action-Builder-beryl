# OrangeFox Action Builder — Beryl

GitHub Actions builder for **Xiaomi Beryl** (POCO M7 Pro 5G / Redmi Note 14 5G, MT6855).

Builds **OrangeFox 14.1** and **TWRP 14.1** `vendor_boot` recovery from the **same** OrangeFox-oriented device tree.

## Device tree

https://github.com/sairajkandkar007/android_device_xiaomi_beryl_ofox16

- Target: OrangeFox **fox_14.1** / API **34**
- Recovery architecture: **vendor_boot**
- Do **not** migrate to OFOX 16 / API 36 unless explicitly requested

## Design

```
android_device_xiaomi_beryl_ofox16   (unchanged on GitHub)
              │
    ┌─────────┴─────────┐
    │                   │
OrangeFox.yml        TWRP.yml
    │                   │
native build     temporary overlay
    │                   │
fox_beryl-bp2a-eng   twrp_beryl-bp2a-eng
    │                   │
vendor_boot.img      vendor_boot.img
```

TWRP conversion is **workspace-only** via `scripts/twrp-compat.sh`.  
The device tree repository is never permanently modified.

## Workflows

| Workflow | Lunch | Output |
|----------|--------|--------|
| `OrangeFox.yml` | `fox_beryl-bp2a-eng` | `vendor_boot.img` |
| `TWRP.yml` | `twrp_beryl-bp2a-eng` | `vendor_boot.img` |

Both are **workflow_dispatch** only (manual run).

### Test order

1. Run **OrangeFox.yml** first (untouched tree).
2. Only after that succeeds, run **TWRP.yml**.
3. If TWRP fails: capture the first real error, add the **minimum** temporary fix, rebuild. Do not rewrite BoardConfig / fstab / API / modules speculatively.

## Compatibility script

```bash
./scripts/twrp-compat.sh apply  device/xiaomi/beryl
./scripts/twrp-compat.sh restore device/xiaomi/beryl
```

On apply: backs up and rewrites only `AndroidProducts.mk` to expose TWRP products.  
On restore: puts the original files back.

## Requirements (device tree)

- `fox_beryl.mk`, `twrp_beryl.mk`, `AndroidProducts.mk`, `BoardConfig.mk`, `device.mk`
- Git LFS objects for kernel / DTB / modules (`git lfs pull`)
- `prebuilt/decryption/` for FBE (optional but recommended)
- Preserve: vendor_boot flags, API 34, FBE, modules, kernel offsets

## Create this repo on GitHub

```bash
# If empty repo already created:
git clone https://github.com/sairajkandkar007/OrangeFox-Action-Builder-beryl.git
cd OrangeFox-Action-Builder-beryl
# copy contents of this package, then:
git add .
git commit -m "Initial OrangeFox + TWRP 14.1 builder for beryl"
git push -u origin main
```

Or upload the zip contents via the GitHub web UI.

## License

Build scripts: Apache-2.0 / as applicable to OrangeFox & TWRP projects.
