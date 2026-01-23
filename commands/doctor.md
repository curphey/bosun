---
name: doctor
description: "Check Bosun system requirements and plugin health. Run this to diagnose issues or verify your environment is properly configured."
---

# /doctor Command

Diagnose Bosun installation and check system requirements.

## Usage

```
/doctor           # Full system check
/doctor --quick   # Just check required dependencies
```

## What It Checks

### Required Dependencies
- **Git** - Required for repository operations

### Optional Dependencies (for specific skills)
- **Node.js/npm** - For JavaScript/TypeScript analysis
- **Python** - For Python analysis
- **Go** - For Go analysis
- **Docker** - For container analysis

### Plugin Health
- Skills properly formatted
- Agents reference valid skills
- References exist

## How to Run

When the user runs `/doctor`, execute the check script:

```bash
./scripts/check-requirements.sh
```

## Expected Output

```
Bosun System Check
==================

Required:
  ✓ Git 2.0+ (found: 2.43.0)

Optional:
  ✓ Node.js 18+ (found: 20.11.0)
  ✓ npm (found: 10.2.0)
  ✓ Python 3.8+ (found: 3.12.0)
  ✓ Go 1.21+ (found: 1.22.0)
  ✗ Docker (not found)
    Install with: brew install docker

Plugin Health:
  ✓ 24 skills found
  ✓ 9 agents found
  ✓ All agent skill references valid
  ⚠ 12 missing reference files (run /audit for details)

Status: Ready (1 optional dependency missing)
```

## Error Handling

### Missing Required Dependencies

```
Bosun System Check
==================

Required:
  ✗ Git (not found)
    Install with: brew install git
    Or: https://git-scm.com/downloads

Status: NOT READY - Install required dependencies
```

### All Good

```
Status: Ready
```

### Optional Missing

```
Status: Ready (2 optional dependencies missing)
```

## Troubleshooting

If `/doctor` reports issues:

1. **Git not found**
   - macOS: `brew install git`
   - Ubuntu: `sudo apt install git`
   - Windows: https://git-scm.com/downloads

2. **Node.js not found**
   - macOS: `brew install node`
   - Ubuntu: `sudo apt install nodejs npm`
   - All: https://nodejs.org/

3. **Python not found**
   - macOS: `brew install python`
   - Ubuntu: `sudo apt install python3 python3-pip`
   - All: https://www.python.org/downloads/

4. **Go not found**
   - macOS: `brew install go`
   - Ubuntu: `sudo apt install golang`
   - All: https://go.dev/dl/

5. **Docker not found**
   - All: https://docs.docker.com/get-docker/
