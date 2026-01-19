---
name: bosun-ux-ui
description: UX/UI design principles and accessibility standards. Use when reviewing UI designs, implementing accessibility, creating design systems, or evaluating usability. Provides WCAG guidance, design patterns, and component best practices.
tags: [ux, ui, accessibility, wcag, design-systems, usability]
---

# Bosun UX/UI Skill

UX/UI knowledge base for accessible, usable interface design.

## When to Use

- Reviewing UI implementations
- Implementing accessibility (WCAG)
- Creating design system components
- Evaluating usability
- Setting up responsive designs

## When NOT to Use

- Backend logic (use language skills)
- Security review (use bosun-security)
- API design (use bosun-architect)

## WCAG 2.1 Essentials

### The Four Principles (POUR)

| Principle | Description | Example |
|-----------|-------------|---------|
| **P**erceivable | Content must be perceivable | Alt text, captions |
| **O**perable | Interface must be operable | Keyboard navigation |
| **U**nderstandable | Content must be understandable | Clear language, errors |
| **R**obust | Content must be robust | Valid HTML, ARIA |

### Color Contrast

| Level | Normal Text | Large Text |
|-------|-------------|------------|
| AA | 4.5:1 | 3:1 |
| AAA | 7:1 | 4.5:1 |

### Keyboard Navigation

```html
<!-- Focusable elements need visible focus -->
<style>
:focus {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
</style>

<!-- Skip links for keyboard users -->
<a href="#main" class="skip-link">Skip to main content</a>
```

## Nielsen's 10 Usability Heuristics

1. **Visibility of system status** - Keep users informed
2. **Match between system and real world** - Use familiar language
3. **User control and freedom** - Provide undo/redo
4. **Consistency and standards** - Follow conventions
5. **Error prevention** - Prevent errors before they occur
6. **Recognition over recall** - Make options visible
7. **Flexibility and efficiency** - Support shortcuts
8. **Aesthetic and minimalist design** - Remove clutter
9. **Help users recognize/recover from errors** - Clear error messages
10. **Help and documentation** - Provide guidance

## Atomic Design Components

```
Atoms → Molecules → Organisms → Templates → Pages

Examples:
- Atom: Button, Input, Label
- Molecule: Form Field (Label + Input + Error)
- Organism: Login Form (multiple Form Fields + Button)
- Template: Authentication Page layout
- Page: Login Page with content
```

## Responsive Design

```css
/* Mobile-first breakpoints */
/* Mobile: default styles */
/* Tablet */
@media (min-width: 768px) { }
/* Desktop */
@media (min-width: 1024px) { }
/* Large desktop */
@media (min-width: 1440px) { }
```

## Accessibility Checklist

### Critical
- [ ] All images have alt text
- [ ] Color contrast meets AA standards
- [ ] All interactive elements keyboard accessible
- [ ] Form inputs have labels
- [ ] Page has proper heading hierarchy

### Important
- [ ] Focus indicators visible
- [ ] Error messages descriptive
- [ ] Skip links provided
- [ ] ARIA labels where needed
- [ ] Animations respect reduced-motion

### Recommended
- [ ] Touch targets 44x44px minimum
- [ ] Text resizable to 200%
- [ ] Sufficient line height (1.5)
- [ ] No content requires horizontal scrolling

## References

See `references/` directory for detailed documentation:
- `ux-ui-research.md` - Comprehensive UX/UI patterns
