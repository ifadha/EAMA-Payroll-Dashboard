---
name: EAMA Payroll System
colors:
  surface: '#fcf8ff'
  surface-dim: '#d8d7fb'
  surface-bright: '#fcf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f2ff'
  surface-container: '#efecff'
  surface-container-high: '#e8e6ff'
  surface-container-highest: '#e2dfff'
  on-surface: '#181934'
  on-surface-variant: '#494552'
  inverse-surface: '#2d2e4a'
  inverse-on-surface: '#f2efff'
  outline: '#7a7583'
  outline-variant: '#cac4d3'
  surface-tint: '#674db0'
  primary: '#644aae'
  on-primary: '#ffffff'
  primary-container: '#7d63c8'
  on-primary-container: '#fffbff'
  inverse-primary: '#cebdff'
  secondary: '#5d5d68'
  on-secondary: '#ffffff'
  secondary-container: '#e3e1ee'
  on-secondary-container: '#63636e'
  tertiary: '#715c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c8a935'
  on-tertiary-container: '#4d3e00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e8ddff'
  primary-fixed-dim: '#cebdff'
  on-primary-fixed: '#21005e'
  on-primary-fixed-variant: '#4e3397'
  secondary-fixed: '#e3e1ee'
  secondary-fixed-dim: '#c6c5d2'
  on-secondary-fixed: '#1a1b24'
  on-secondary-fixed-variant: '#464650'
  tertiary-fixed: '#ffe17b'
  tertiary-fixed-dim: '#e5c44e'
  on-tertiary-fixed: '#231b00'
  on-tertiary-fixed-variant: '#564500'
  background: '#fcf8ff'
  on-background: '#181934'
  surface-variant: '#e2dfff'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  sidebar-width: 240px
  sidebar-collapsed-width: 80px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 32px
  card-padding: 24px
---

## Brand & Style

This design system is engineered for the modern human resources and payroll environment, prioritizing clarity, trust, and operational efficiency. The brand personality is **Professional, Systematic, and Precise**, reflecting the critical nature of financial data management while maintaining an approachable feel that reduces the cognitive load of complex administrative tasks.

The visual style follows a **Modern Corporate** aesthetic with a strong emphasis on **Functional Minimalism**. It utilizes a card-based architecture to organize dense information into digestible units. A light-saturated color palette conveys transparency and cleanliness, while a sophisticated purple accent provides a sense of premium quality and focus. High-contrast typography and generous whitespace ensure that numerical data and employee records remain legible and easy to navigate.

## Colors

The palette is anchored by a vibrant **Amethyst Purple** primary color, used strategically for action-oriented elements and brand identity. 

- **Primary & Secondary:** The primary purple is balanced by a very soft secondary lavender shade, used primarily for hover states and subtle backgrounds behind active navigation items.
- **Surfaces:** The background utilizes a neutral "off-white" gray to provide depth, allowing white card surfaces to stand out prominently. 
- **Functional Colors:** Success, Error, and Warning colors follow standard semantic expectations but are slightly desaturated to maintain the professional, understated look of the platform. 
- **Neutral Scale:** Grays are slightly tinted with blue/cool tones to prevent a muddy appearance and maintain a crisp, clean feel.

## Typography

This design system uses **Inter** as the primary typeface due to its exceptional legibility in data-heavy interfaces and its geometric yet neutral character.

The hierarchy is built on a high-contrast scale to separate high-level metrics from granular data. **Display** and **Headline** styles utilize semi-bold and bold weights to ground the page, while **Body** text remains at a standard 14px size for optimal balance between information density and readability. **Labels** are used for metadata, table headers, and form captions, often employing a slightly heavier weight or uppercase transformation to differentiate them from interactive body text.

## Layout & Spacing

The layout is based on a **12-column fluid grid** for the main content area, paired with a **fixed persistent sidebar**. 

- **Sidebar:** The sidebar remains at 240px on desktop to provide clear navigation labels. On smaller screens or when minimized, it collapses to 80px, showing only icons.
- **Rhythm:** A 24px gutter is used between cards to provide "visual breathing room," preventing the interface from feeling cluttered during heavy payroll processing.
- **Padding:** Internal card padding is set to a generous 24px, ensuring that data points don't feel cramped.
- **Breakpoints:** 
  - *Mobile (< 768px):* Sidebar moves to a bottom nav or hidden drawer; margins reduce to 16px.
  - *Desktop (> 1024px):* Content max-width of 1440px to prevent extreme line lengths in tables.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Ambient Shadows**. This design system avoids heavy gradients or complex skeuomorphism in favor of subtle depth.

- **Level 0 (Background):** The base layer uses the light gray background color.
- **Level 1 (Cards/Sidebar):** Primary surfaces are pure white, sitting atop the background. They feature a very soft, diffused shadow (Blur: 10px, Y: 4px, Color: Black at 4% opacity) to provide a gentle lift.
- **Level 2 (Overlays/Dropdowns):** Modals and context menus use a more pronounced shadow (Blur: 20px, Y: 8px, Color: Black at 8% opacity) to signify a clear break from the main interface.
- **Interactive Depth:** When a card or button is hovered, the shadow intensifies slightly, and the border may gain a 1px primary-colored tint to signify focus.

## Shapes

The design system utilizes **Rounded** shapes to soften the "industrial" feel of payroll software, making the application feel more modern and user-friendly.

- **Main UI Elements:** Buttons, input fields, and standard cards use a 0.5rem (8px) corner radius.
- **Large Containers:** Large dashboard panels or secondary backgrounds use a 1rem (16px) corner radius for a more distinctive, "app-like" appearance.
- **Badges/Chips:** Status indicators use a fully rounded (pill) shape to distinguish them from interactive buttons.
- **Sidebar Selection:** The active state indicator in the sidebar uses a soft, rounded rectangle that doesn't quite touch the edge, creating a floating effect.

## Components

### Buttons
- **Primary:** Solid purple background with white text. High-contrast and easily identifiable.
- **Secondary:** Lavender background (#F4F2FF) with purple text. Used for less critical actions.
- **Ghost:** Transparent background with purple text/icon, used for navigation and subtle actions.

### Cards
- White surfaces with 8px-16px rounded corners.
- Used for dashboard widgets, employee profiles, and payroll summaries.
- Headers within cards should use `headline-sm` with a light bottom border separator.

### Status Badges
- **Success (Paid):** Soft green background with dark green text.
- **Warning (Pending):** Soft amber background with dark amber text.
- **Error (Failed):** Soft red background with dark red text.
- All badges are pill-shaped with `label-sm` typography.

### Input Fields
- White background with a 1px light gray border.
- On focus: Border changes to primary purple with a soft purple outer glow.
- Labels sit above the field using `label-md`.

### Sidebar Navigation
- Vertical stack of icons and labels.
- **Active State:** The item is highlighted with the secondary lavender color and the text/icon turns primary purple.
- **Icons:** Use thin-stroke (2px) linear icons for a clean, modern look.

### Data Tables
- Clean, row-based layout with no vertical borders.
- Header row uses a light gray background or bold `label-sm` typography.
- Alternating row highlights (zebra striping) should be avoided in favor of subtle hover states.