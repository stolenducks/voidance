# AI Helper Guide - droid

Complete documentation for the **droid** AI assistant included in Void Linux XFCE - AI Edition.

## Overview

**droid** is an offline command-line AI assistant that helps you troubleshoot and learn Void Linux. It uses a lightweight AI model (Qwen 2.5 Coder 3B) with embedded Void Linux documentation to provide accurate, contextual answers.

**Key Features:**
- ✅ Works completely offline
- ✅ Knows Void Linux specifics (xbps, runit)
- ✅ Fast responses (~1-2 seconds on typical hardware)
- ✅ Easy to remove when no longer needed
- ✅ Privacy-focused (no data leaves your machine)

---

## Commands

### Ask a Question

```bash
droid "your question here"
```

**Examples:**
```bash
droid "how do I install firefox"
droid "what is the command to remove a file"
droid "how do I connect to wifi"
droid "restart network manager"
```

**Tips:**
- Be specific in your questions
- Use natural language
- Don't worry about perfect grammar

### Check Status

```bash
droid status
```

Shows:
- Ollama installation status
- Service running state
- Model availability
- Documentation cache size
- Initialization state

**Example output:**
```
=== Droid AI Helper Status ===

✓ ollama: installed
✓ ollama service: running
✓ model: void-qwen (ready)
✓ void docs: 15M
✓ initialized: yes
```

### Setup/Repair

```bash
droid setup
```

**When to use:**
- First-time initialization (usually automatic)
- Repair broken installation
- Recreate AI model after manual deletion

**What it does:**
1. Enables ollama service
2. Waits for ollama to start
3. Creates void-qwen model from local GGUF
4. Marks system as initialized

### Update Documentation

```bash
droid update-docs
```

**Requires internet connection.**

Updates the local mirror of Void Linux documentation. Use this periodically to get the latest official docs.

**What it downloads:**
- docs.voidlinux.org (HTML only)
- Skips images/CSS to save space (~10-20MB total)

### Uninstall

```bash
droid uninstall
```

**Completely removes the AI helper** and reclaims disk space (~2-3GB).

**What gets removed:**
- Ollama service
- AI model (Qwen 2.5 Coder 3B)
- Offline documentation
- Model cache and data
- Optionally: ollama package itself

**What stays:**
- droid command (as a small stub)
- Core Void Linux system (unaffected)

---

## How It Works

### Architecture

```
┌─────────────┐
│ User Query  │
└──────┬──────┘
       │
       v
┌─────────────────┐
│  droid CLI      │  ← You are here
└──────┬──────────┘
       │
       v
┌──────────────────────┐
│ Context Extraction   │  ← ripgrep searches /opt/void-docs
└──────┬───────────────┘
       │
       v
┌──────────────────────┐
│ Ollama + Qwen Model  │  ← Local AI inference
└──────┬───────────────┘
       │
       v
┌──────────────────────┐
│ Response             │  ← Answer with Void Linux context
└──────────────────────┘
```

### Context Augmentation

When you ask a question:

1. **droid** searches `/opt/void-docs` using `ripgrep`
2. Extracts relevant snippets (max 3 matches, 10 lines)
3. Sends question + context to the AI model
4. Model generates answer using both its training and the docs

**Example:**

Query: `droid "how do I install a package"`

Context extracted:
```
To install packages on Void Linux, use xbps-install:
  sudo xbps-install -S <package>

The -S flag updates the repository database first.
```

Response:
```
To install a package on Void Linux:
  sudo xbps-install -S <package-name>

Example:
  sudo xbps-install -S firefox

The -S flag ensures the package database is up-to-date before installing.
```

---

## Model Details

### Qwen 2.5 Coder 3B

**Why this model?**
- Specifically trained for code and technical content
- Excellent Linux/CLI knowledge
- Lightweight (~2GB quantized)
- Fast inference on laptops (1-2 sec responses)

**Quantization:** Q4_K_M
- Good balance of quality and size
- 4-bit quantization with mixed precision
- ~1.2-2.0GB file size

**System Prompt:**
```
You are a helpful AI assistant specialized in Void Linux
system administration and command-line operations.

Key Guidelines:
- Provide concise, actionable CLI commands
- Prefer xbps over other package managers
- Use runit (sv command), NOT systemd
- Always prioritize safety
- Give exact commands with brief explanations

Void Linux Specifics:
- Package management: xbps-install, xbps-remove, xbps-query
- Service management: sv start/stop/restart/status
- Services location: /etc/sv/, enabled via /var/service/
- Init system: runit (NOT systemd)

Response Style:
- Start with the command/solution
- Follow with brief explanation if needed
- Be direct and helpful
```

---

## Privacy & Security

### What Stays Local

✅ **100% Local Processing:**
- AI model runs on your CPU
- No API keys required
- No cloud services used
- No telemetry or analytics

✅ **Your Data:**
- Questions never leave your machine
- Command history is local
- No logging to external servers

### Internet Usage

❌ **Never uses internet for:**
- AI inference
- Answering questions
- Processing commands

✅ **Uses internet only for:**
- Initial download during ISO build
- `droid update-docs` (optional command)

---

## Performance

### System Requirements

**Minimum:**
- 4GB RAM
- 2GB disk space
- x86_64 processor

**Recommended:**
- 8GB+ RAM
- 3GB disk space
- Modern Intel/AMD processor (2015+)

### Response Times

**Typical hardware (i5/i7 laptop):**
- Simple queries: 0.5-1 second
- Complex queries: 1-2 seconds
- First query after boot: 2-3 seconds (model loading)

**Older hardware:**
- May take 3-5 seconds per query
- Still usable, just slower

---

## Troubleshooting

### "ollama is not installed"

```bash
# Check if ollama package exists
xbps-query -l | grep ollama

# If missing, you'll need to build or obtain ollama for Void
# (Not yet in official repos as of 2025-01)
```

### "ollama service is not running"

```bash
# Enable and start ollama
sudo ln -sf /etc/sv/ollama /var/service/
sleep 2
sudo sv status ollama
```

### "Model 'void-qwen' not found"

```bash
# Recreate the model
droid setup

# Or manually
cd /opt/droid
ollama create void-qwen -f Modelfile
```

### Slow responses

```bash
# Check CPU usage
htop

# Check if model is loaded
ollama list

# Restart ollama service
sudo sv restart ollama
```

### Out of memory

```bash
# Check memory usage
free -h

# Stop ollama when not in use
sudo sv stop ollama

# Remove AI entirely
droid uninstall
```

---

## Advanced Usage

### Custom Questions

You can pipe output to droid:

```bash
# Analyze error messages
some-command 2>&1 | droid "what does this error mean"

# Get help with files
cat /var/log/xbps.log | droid "any installation errors here?"
```

### Integration with Shell

Add to your `.bashrc` or `.zshrc`:

```bash
# Quick alias
alias d='droid'

# Function for common tasks
explain() {
    droid "explain the command: $*"
}

# Usage:
# d "how do I..."
# explain ls -la
```

### Offline Documentation

The embedded documentation is located at:
```
/opt/void-docs/
```

You can browse it directly:
```bash
# List available docs
ls /opt/void-docs/

# Search manually
rg "xbps-install" /opt/void-docs/

# View in browser (if GUI available)
firefox /opt/void-docs/index.html
```

---

## Limitations

### What droid CAN do:

✅ Explain Void Linux commands  
✅ Help with package management (xbps)  
✅ Guide service management (runit)  
✅ Troubleshoot common issues  
✅ Provide CLI examples  
✅ Reference official documentation  

### What droid CANNOT do:

❌ Execute commands for you  
❌ Modify your system directly  
❌ Access files without permission  
❌ Connect to internet  
❌ Replace reading documentation  
❌ Guarantee 100% accuracy (always verify)  

---

## Examples

### Package Management

```bash
$ droid "how do I search for packages"
Use xbps-query to search:
  xbps-query -Rs <keyword>

Example:
  xbps-query -Rs firefox

$ droid "install multiple packages at once"
Install multiple packages:
  sudo xbps-install -S package1 package2 package3

Example:
  sudo xbps-install -S firefox git nano
```

### Service Management

```bash
$ droid "how do I start a service"
To start a service in Void Linux (runit):
  sudo sv start <service>

Example:
  sudo sv start sshd

To enable at boot:
  sudo ln -sf /etc/sv/sshd /var/service/

$ droid "list all running services"
To list all running services:
  sudo sv status /var/service/*
```

### Networking

```bash
$ droid "connect to wifi from terminal"
Connect to WiFi using NetworkManager:
  nmcli device wifi connect <SSID> password <PASSWORD>

Example:
  nmcli device wifi connect MyNetwork password MyPassword123

List available networks:
  nmcli device wifi list

$ droid "my wifi keeps disconnecting"
Try these troubleshooting steps:

1. Check NetworkManager status:
   sudo sv status NetworkManager

2. Restart NetworkManager:
   sudo sv restart NetworkManager

3. Check for driver issues:
   dmesg | grep -i wifi

4. Try reconnecting:
   nmcli device disconnect wlan0
   nmcli device connect wlan0
```

---

## Comparison with Other Tools

| Feature | droid | man pages | Online docs | ChatGPT |
|---------|-------|-----------|-------------|---------|
| Offline | ✅ | ✅ | ❌ | ❌ |
| Void-specific | ✅ | ✅ | ✅ | ⚠️ |
| Natural language | ✅ | ❌ | ⚠️ | ✅ |
| Examples | ✅ | ⚠️ | ✅ | ✅ |
| Privacy | ✅ | ✅ | ⚠️ | ❌ |
| Speed | Fast | Instant | Slow | Fast |

**When to use droid:**
- Quick CLI help
- Learning Void Linux
- Offline situations
- Privacy-conscious use

**When NOT to use droid:**
- Deep technical details → use `man` pages
- Official references → use docs.voidlinux.org
- Complex debugging → use community forums

---

## Philosophy

**droid is a learning tool, not a replacement for understanding.**

Goals:
1. Help beginners get unstuck quickly
2. Provide accurate, Void-specific answers
3. Encourage learning through examples
4. Remain completely optional

Non-goals:
1. Replace official documentation
2. Execute commands automatically
3. Be an expert system
4. Prevent users from learning

**Use droid to learn, then graduate to using Void Linux confidently without it.**

---

## FAQ

**Q: Is the AI always accurate?**  
A: No. Always verify important commands. The AI can make mistakes or misunderstand context.

**Q: Does it send my questions to the internet?**  
A: No. Everything runs locally. No data leaves your machine.

**Q: How much disk space does it use?**  
A: ~2-3GB (2GB model + docs + ollama)

**Q: Can I use a different AI model?**  
A: Yes, but you'll need to modify the Modelfile manually.

**Q: Why Qwen and not Llama/Mistral/etc?**  
A: Qwen 2.5 Coder is specifically trained for code/technical content and performs excellently on CLI tasks.

**Q: Will it work without internet?**  
A: Yes, after initial installation. The model and docs are embedded in the ISO.

**Q: Can I keep it forever?**  
A: Yes! Or remove it anytime with `droid uninstall`.

---

## Resources

- [Ollama Documentation](https://github.com/ollama/ollama/tree/main/docs)
- [Qwen 2.5 Coder](https://github.com/QwenLM/Qwen2.5-Coder)
- [Void Linux Handbook](https://docs.voidlinux.org/)
- [Project Repository](https://github.com/stolenducks/voidance/tree/xfce-ai-stock)

---

**Last Updated:** 2025-01-05  
**Version:** 1.0.0  
**Model:** Qwen 2.5 Coder 3B (Q4_K_M)
