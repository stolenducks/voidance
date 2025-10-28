# Voidance Governance

## Project Philosophy

Voidance exists to make Linux **accessible, beautiful, and educational** for people who are **learning** and **building**.

### Core Principles

1. **Beginner-First** - If a feature confuses newcomers, it doesn't belong in default configs
2. **Freedom to Learn** - Users should understand what's happening, not just copy commands
3. **Aesthetic Simplicity** - Beauty shouldn't require expertise
4. **Transparent by Default** - Document the "why", not just the "how"
5. **No Gatekeeping** - Everyone was a beginner once

### The Target User

**We build for people like the founder:**
- Curious about Linux but not experts
- Want something that "just works" but is still hackable
- Prefer learning by doing over reading dense wikis
- Value aesthetics and developer experience equally
- Intimidated by Arch, frustrated by Ubuntu

**Important:** As maintainers gain expertise, we must actively resist the urge to optimize for power users at the expense of beginners. The moment we lose sight of the beginner experience, we've failed our mission.

---

## Decision-Making Structure

### Roles

#### Founder
- Sets project vision and philosophy
- Final say on what fits the "Voidance spirit"
- Can veto changes that compromise beginner-friendliness
- Does NOT need to be the most technical person

#### Core Maintainers
- 1-3 trusted contributors with commit access
- Handle technical implementation and code review
- Must prioritize **clarity over cleverness**
- Advocate for the target user in all decisions

#### Contributors
- Anyone who submits PRs, issues, or feedback
- Equal voice in discussions
- No contribution is too small

### Decision Process

1. **Feature Proposals** - Open an issue, discuss impact on beginners
2. **Technical Review** - Maintainers assess implementation quality
3. **Philosophy Check** - Does it align with our principles? (Founder weighs in)
4. **Merge** - If yes to both, merge. If conflict, founder decides.

### Conflict Resolution

When technical best practices conflict with beginner experience:
- **Beginner experience wins** for default configs
- Advanced options can exist but must be opt-in
- Documentation explains tradeoffs in plain English

Example: 
- ❌ "We should use musl because it's more minimal"
- ✅ "We'll use glibc by default (more compatible), with musl as an option for advanced users"

---

## What We Say "Yes" To

- Clearer documentation
- Better error messages
- Sane defaults that work out of the box
- Features that reduce intimidation
- Contributions from beginners (with mentorship)
- Accessibility improvements
- Performance gains that don't sacrifice usability

## What We Say "No" To

- Features that require reading man pages to understand
- "Just use the CLI" without a GUI option
- Configurations that optimize for 1% use cases
- Removing features to be "more minimal" if beginners use them
- Assumptions that users know what runit/xbps/musl mean
- Elitism or condescension toward newcomers

---

## Learning as a Goal

Voidance is not just an OS—it's a **teaching tool**.

### Educational Philosophy

- **Transparent Defaults** - Configs include comments explaining what/why
- **Gentle Onboarding** - First boot experience teaches basic concepts
- **No Magic** - Scripts are readable, not obfuscated one-liners
- **Encourage Tinkering** - Make it easy to experiment safely

### For Contributors

- PRs should include comments explaining non-obvious choices
- New features need user-facing documentation
- Code reviews are teaching moments, not just gatekeeping
- "Stupid questions" don't exist—if it confused someone, we document it

---

## Handoff & Succession

### When the Founder Steps Back

If/when the founder reduces involvement:

1. **Philosophy Steward** - One core maintainer becomes the "keeper of the vision"
2. **Target User Advocate** - Always have at least one relatively new Linux user on the team
3. **Beginner Testing** - Major changes must be tested by someone unfamiliar with the feature
4. **Annual Philosophy Review** - Check if we're still serving our target user

### Red Flags We're Losing Our Way

- Issues from beginners get ignored
- Documentation assumes expert knowledge
- Defaults prioritize advanced users
- Community becomes unwelcoming to newbies
- "This is just like Arch but on Void" becomes the description

If any of these happen, **course correct immediately**.

---

## Freedom & Ownership

### License
Voidance uses **MIT License** - maximum freedom to fork, modify, distribute.

### Forking is Encouraged
If the project evolves in a direction you disagree with, **fork it!** That's the beauty of open source.

### Credit
- Original founder: **Always credited** in README/docs
- Major contributors: Listed in CONTRIBUTORS.md
- Inspiration sources: Acknowledged (Omarchy, Void Linux, Hyprland community)

---

## Code of Conduct

1. **Be patient with beginners** - You were one once
2. **Explain, don't condescend** - "Here's how" beats "RTFM"
3. **Critique ideas, not people** - Focus on what's best for users
4. **Celebrate learning** - First PR? We're excited to help.
5. **No gatekeeping** - Linux belongs to everyone

Violations result in warnings, then bans. We protect the learning environment.

---

## Amendments

This governance doc can be updated via PR, but requires:
- Founder approval (or Philosophy Steward if founder has stepped back)
- 2/3 core maintainer agreement
- Open discussion period (1 week minimum)

**Core principles (beginner-first, freedom to learn) cannot be removed.**

---

## Questions?

Open an issue tagged `governance` to discuss project direction, philosophy, or decision-making.

Remember: **We're all learning. That's the point.**

---

*"The best Linux distro is the one that makes you excited to use Linux." - Voidance Philosophy*
