---
name: bosun-seo-llm
description: SEO and LLM optimization for web content. Use when optimizing content for search engines and AI systems, implementing structured data, or improving content discoverability. Provides SEO patterns and LLM-friendly content guidance.
tags: [seo, llm, structured-data, schema, content-optimization]
---

# Bosun SEO/LLM Skill

SEO and LLM optimization knowledge base for content discoverability.

## When to Use

- Optimizing web content for search engines
- Implementing structured data (Schema.org)
- Making content LLM-friendly
- Improving meta tags and descriptions
- Setting up sitemaps and robots.txt

## When NOT to Use

- Backend implementation (use language skills)
- Security review (use bosun-security)
- UI design (use bosun-ux-ui)

## Essential Meta Tags

```html
<head>
  <!-- Primary Meta Tags -->
  <title>Page Title - Brand Name</title>
  <meta name="description" content="Concise description (150-160 chars)">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <!-- Open Graph (Facebook, LinkedIn) -->
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Description for social">
  <meta property="og:image" content="https://example.com/image.jpg">
  <meta property="og:url" content="https://example.com/page">

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Description">

  <!-- Canonical URL -->
  <link rel="canonical" href="https://example.com/page">
</head>
```

## Structured Data (Schema.org)

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Article Title",
  "author": {
    "@type": "Person",
    "name": "Author Name"
  },
  "datePublished": "2024-01-15",
  "description": "Article description",
  "image": "https://example.com/image.jpg"
}
```

### Common Schema Types

| Type | Use Case |
|------|----------|
| Article | Blog posts, news |
| Product | E-commerce items |
| Organization | Company info |
| FAQ | Question/answer content |
| HowTo | Tutorial content |
| BreadcrumbList | Navigation path |

## LLM-Friendly Content

### Structure for AI Understanding

1. **Clear headings** - Use semantic H1-H6 hierarchy
2. **Concise paragraphs** - One idea per paragraph
3. **Lists and tables** - Structured data is easier to parse
4. **Explicit definitions** - Define terms on first use
5. **Summaries** - TL;DR at the start of long content

### Content Patterns

```markdown
# Topic Title

**Summary:** One-paragraph overview of the entire content.

## What is [Topic]?

Clear definition in the first sentence.

## Key Concepts

| Concept | Definition |
|---------|------------|
| Term 1 | Explanation |
| Term 2 | Explanation |

## How to [Action]

1. Step one
2. Step two
3. Step three

## FAQ

### Question 1?
Answer to question 1.

### Question 2?
Answer to question 2.
```

## Technical SEO

### robots.txt

```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Sitemap: https://example.com/sitemap.xml
```

### Sitemap

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-15</lastmod>
    <priority>1.0</priority>
  </url>
</urlset>
```

## Performance Impact on SEO

- [ ] Core Web Vitals optimized (LCP, FID, CLS)
- [ ] Images optimized and lazy-loaded
- [ ] CSS/JS minified
- [ ] Proper caching headers
- [ ] Mobile-friendly design

## References

See `references/` directory for detailed documentation:
- `seo-llm-research.md` - Comprehensive SEO/LLM patterns
