---
name: Modern Boutique
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f4'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#43474b'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#73777b'
  outline-variant: '#c3c7cb'
  surface-tint: '#51606b'
  primary: '#202f38'
  on-primary: '#ffffff'
  primary-container: '#36454f'
  on-primary-container: '#a2b2be'
  inverse-primary: '#b9c9d5'
  secondary: '#7a5642'
  on-secondary: '#ffffff'
  secondary-container: '#fecdb4'
  on-secondary-container: '#795541'
  tertiary: '#352c1c'
  on-tertiary: '#ffffff'
  tertiary-container: '#4c4230'
  on-tertiary-container: '#bdaf98'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e5f1'
  primary-fixed-dim: '#b9c9d5'
  on-primary-fixed: '#0e1d26'
  on-primary-fixed-variant: '#3a4953'
  secondary-fixed: '#ffdbca'
  secondary-fixed-dim: '#ecbda4'
  on-secondary-fixed: '#2e1506'
  on-secondary-fixed-variant: '#603f2d'
  tertiary-fixed: '#f0e0c8'
  tertiary-fixed-dim: '#d3c5ad'
  on-tertiary-fixed: '#221b0b'
  on-tertiary-fixed-variant: '#4f4533'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display-lg:
    fontFamily: Playfair Display
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Playfair Display
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-max: 1200px
  stack-xs: 4px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  stack-xl: 40px
  gutter: 20px
  margin-mobile: 20px
  margin-desktop: 60px
---

## Brand & Style

This design system embodies the "Modern Boutique" aesthetic, tailored specifically for the ambitious, style-conscious professional woman. The brand personality is sophisticated, curated, and effortlessly chic, functioning less like a utility and more like a high-end digital concierge.

The UI leverages a refined **Minimalism** blended with **Soft Tonal Layering**. It prioritizes extreme clarity and expansive white space to let high-quality editorial photography of garments take center stage. The emotional response should be one of calm, organized luxury—removing the friction of daily dressing through a structured, premium visual environment.

## Colors

The palette is anchored by **Charcoal (#36454F)**, providing a grounding, professional weight for primary actions and core typography. **Dusty Rose (#DCAE96)** serves as a soft, feminine accent for highlights and active states, while **Champagne (#F7E7CE)** is used sparingly for subtle background fills and decorative elements.

The background is a curated "Off-White" (#FCFAFA) to reduce the harshness of pure white while maintaining a crisp, editorial feel. Use high-contrast Charcoal for readability in all body text, and Dusty Rose for interactive elements like selected tabs or primary buttons.

## Typography

The typographic strategy relies on the tension between the editorial elegance of **Playfair Display** and the functional precision of **Inter**. 

- **Headlines:** Use Playfair Display for all titles and section headers. High-level displays should use tight letter spacing to emphasize the serif's geometry.
- **Body & UI:** Inter is used for all functional text, ensuring high legibility on mobile devices.
- **Labels:** Small labels and category tags should use Inter with a medium or semi-bold weight and increased letter spacing for a "luxury brand" label effect.

## Layout & Spacing

The design system utilizes a **Fixed Grid** for desktop and a **Fluid Grid** for mobile. 
- **Desktop:** A 12-column centered layout with 60px side margins and 20px gutters. 
- **Mobile:** A 4-column layout with 20px side margins. 

The vertical rhythm is spacious. Avoid "cramming" content; use `stack-xl` between major sections to maintain the boutique feel. Elements should be grouped logically using `stack-md` for internal component spacing, ensuring the interface feels breathable and easy to navigate under pressure.

## Elevation & Depth

Hierarchy is established through **Ambient Shadows** and **Tonal Layers**. 

1. **Base:** The background (#FCFAFA) is the lowest level.
2. **Cards & Surfaces:** Use pure white (#FFFFFF) for cards and containers, elevated by a very soft, diffused shadow (e.g., `0px 10px 30px rgba(54, 69, 79, 0.05)`). The shadow should use a hint of the Charcoal color rather than pure black to keep the depth "warm."
3. **Floating Elements:** Primary Action Buttons and Modals use a slightly more pronounced shadow to indicate interactivity and focus.
4. **Interactive States:** On hover or tap, cards should subtly lift (shadow deepens and element scales by 1-2%) to provide tactile feedback.

## Shapes

The shape language is defined by **large, soft radii**. This removes the clinical feel of sharp corners and aligns with the "Modern Boutique" aesthetic. 

- **Standard Elements:** Buttons, input fields, and small cards use a 0.5rem (8px) radius.
- **Large Containers:** Image galleries and main content cards use a `rounded-xl` 1.5rem (24px) radius.
- **Iconography:** Use "Thin" or "Light" weight line icons with rounded caps to mirror the typography's refinement. Avoid filled icons unless indicating an active state (e.g., a filled heart for a "Saved" item).

## Components

- **Buttons:** Primary buttons are solid Charcoal with white Inter Medium text. Secondary buttons are outlined in Dusty Rose or Ghost buttons with a subtle Champagne fill on hover. All buttons use 8px rounded corners.
- **Input Fields:** Minimalist design with a bottom-border only or a very light gray (#E0E0E0) full border. Focus state shifts the border color to Dusty Rose.
- **Cards:** White surfaces with 24px corner radius. Image-heavy. For a "Lookbook" card, the image should occupy 80% of the card area with a small typography block at the bottom.
- **Chips/Filters:** Pill-shaped (fully rounded) with a Champagne background and Charcoal text. Active filters switch to a Dusty Rose background.
- **Lists:** High-density lists are avoided. Instead, use "Row Cards" with significant vertical padding (16px-24px) and subtle dividers.
- **Specialty Component - "The Hanger":** A specialized navigation or progress indicator using a thin horizontal line and a minimalist hanger icon to denote where the user is in the "Curating" process.