# ClearRam

A Linux RAM cache cleaner for servers — clears page cache, dentries, and inodes via `/proc/sys/vm/drop_caches` with a clear before/after memory summary.

---

## Usage

```bash
sudo ./ClearRam.sh [-d LEVEL] [-n]
```

| Flag | Description | Default |
|---|---|---|
| `-d` | Drop cache level (1, 2, or 3) | 3 |
| `-n` | Dry run — show memory info without clearing | off |

### Drop cache levels

| Level | Clears |
|---|---|
| `1` | Page cache only |
| `2` | Dentries and inodes |
| `3` | Page cache + dentries + inodes (full) |

---

## Examples

```bash
# Full cache clear (default)
sudo ./ClearRam.sh

# Page cache only
sudo ./ClearRam.sh -d 1

# Check memory state without clearing anything
sudo ./ClearRam.sh -n

# Dentries and inodes only
sudo ./ClearRam.sh -d 2
```

---

## Sample output

```
  ClearRam — Linux Memory Cache Cleaner
  Sat May 30 19:00:00 UTC 2026

  Before
  ────────────────────────────────────
  Total RAM   : 7974 MiB
  Free        : 312 MiB
  Available   : 1843 MiB
  Cached      : 1420 MiB
  Buffers     : 210 MiB
  Swap total  : 2048 MiB
  Swap used   : 128 MiB
  Swap free   : 1920 MiB

  Syncing filesystem...
  Dropping caches: page cache + dentries + inodes (level 3)...

  After
  ────────────────────────────────────
  Total RAM   : 7974 MiB
  Free        : 1654 MiB
  Available   : 3180 MiB
  Cached      : 87 MiB
  ...

  Done. Available memory: 3180 MiB
```

---

## When to use

Useful on servers where applications accumulate cache over time and available memory drops to uncomfortable levels. Common scenarios:

- Java applications with large heap leaving residual cache
- Database servers after bulk data loads
- Systems with memory leaks that have been restarted but left cache behind

> **Note:** The Linux kernel manages cache intelligently — cached memory is not wasted memory. Only clear caches when you have a specific reason and observe measurable benefit.

---

## Requirements

- Linux only (uses `/proc/meminfo` and `/proc/sys/vm/drop_caches`)
- Must be run as root (`sudo`)

---

## Author

Julio Mauro · [github.com/juliomauro](https://github.com/juliomauro)
