/**
 * Vextra Landing Page - Site Configuration
 * 
 * This file contains all configurable content for the landing page.
 * Update this file to change any text, features, team info, etc.
 * No content should be hardcoded in components.
 */

// Brand Information
export const brand = {
    name: 'Vextra',
    tagline: 'Create once. Publish everywhere.',
    description: 'The first AI-Powered Content Management System designed to help you break free from platform chaos. Manage, publish, and scale your voice—all from one place.',
    shortDescription: 'Your entire content ecosystem in your pocket.',
    logo: '/vextra_logo.png',
    logoDark: '/vextra_logo_dark.png',
} as const;

// Navigation Links
export const navigation = {
    links: [
        { label: 'Features', href: '/#features' },
        { label: 'How it Works', href: '/#how-it-works' },
        { label: 'Team', href: '/#team' },
        { label: 'Contact', href: '/contact' },
    ],
    cta: {
        label: 'Download App',
        href: '/#download',
        download: false,
    },
} as const;

// Hero Section
export const hero = {
    titleLine1: 'Create once.',
    titleLine2: 'Publish',
    titleHighlight: 'everywhere.',
    subtitle: brand.description,
    cta: {
        primary: { label: 'Download Vextra', href: '/app-arm64-v8a-release.apk', download: true },
        secondary: { label: 'Learn More', href: '/#features' },
    },
    pledge: brand.shortDescription,
} as const;

// Problem/Pain Points
export const problems = {
    title: 'Why is creating content so hard?',
    items: [
        {
            icon: '⚡',
            title: 'The Chaos',
            description: 'You have a brilliant idea. You write it down. Then the chaos begins. Formatting, resizing, tweaking.',
        },
        {
            icon: '🔄',
            title: 'The Switch',
            description: "Switching between five different apps just to get one post out destroys your flow.",
        },
        {
            icon: '📉',
            title: 'The Burnout',
            description: "By the time you hit publish, the excitement is gone. Content creation shouldn't feel like a chore.",
        },
    ],
} as const;

// Solution/Intro Section
export const solution = {
    title: 'Meet Vextra.',
    subtitle: 'Your new creative command center.',
    description: "Vextra is the unifying layer for your digital presence. It's a mobile-first ACMS that brings creation, management, and publishing under one roof. No more app switching. Just pure creative flow.",
} as const;

// How It Works Steps
export const howItWorks = {
    title: 'Order from chaos.',
    steps: [
        {
            number: '01',
            title: 'Create',
            description: 'Use our distraction-free editor to craft text and media content with AI assistance.',
        },
        {
            number: '02',
            title: 'Manage',
            description: 'Organize your drafts and ideas in a unified library accessible anywhere.',
        },
        {
            number: '03',
            title: 'Publish',
            description: 'Push directly to LinkedIn, Inspire feed, and soon everywhere else with a single tap.',
        },
        {
            number: '04',
            title: 'Collaborate',
            description: 'Chat with your community and get feedback in real-time.',
        },
    ],
} as const;

// Features
export const features = {
    title: 'Feature Highlights',
    items: [
        {
            icon: '✏️',
            title: 'AI-Powered Editor',
            description: 'Writing, reimagined. A clean, powerful editor with AI assistance that gets out of your way.',
        },
        {
            icon: '💼',
            title: 'LinkedIn Publishing',
            description: 'Go specific, go viral. Seamless OAuth integration with LinkedIn for instant publishing.',
        },
        {
            icon: '💬',
            title: 'Real-Time Chat',
            description: 'Built for creators. WebSocket-based messaging keeps your community in sync.',
        },
        {
            icon: '✨',
            title: 'Inspire Feed',
            description: 'Never run out of ideas. Tap into the Vextra creator community for inspiration.',
        },
        {
            icon: '📱',
            title: 'Mobile-First',
            description: 'Creativity strikes anywhere. Vextra is built from the ground up for your phone.',
        },
        {
            icon: '☁️',
            title: 'Cloud Sync',
            description: 'Your content, everywhere. Automatic cloud backup and sync across devices.',
        },
    ],
} as const;

// Why Vextra / Differentiators
export const differentiators = {
    title: 'Not just another tool.',
    subtitle: 'A new way of working.',
    items: [
        {
            icon: '🔗',
            title: 'Unified Platform',
            description: 'Stop stitching together disjointed tools and losing precious time switching between apps. Vextra brings everything under one roof—create, manage, schedule, and publish from a single dashboard. Your content workflow, simplified.',
        },
        {
            icon: '📱',
            title: 'Mobile-First Design',
            description: 'Creativity strikes anywhere—on your commute, during lunch, or at midnight. Vextra is engineered from the ground up for mobile devices, giving you the full power of a desktop content studio in your pocket.',
        },
        {
            icon: '🎨',
            title: 'Creator-Focused Experience',
            description: "We don't just build features; we build superpowers for creators. Every interaction is designed to amplify your creative flow, not interrupt it. Beautiful interfaces, intuitive controls, zero learning curve.",
        },
        {
            icon: '🤖',
            title: 'AI-Enhanced Productivity',
            description: 'Let artificial intelligence handle the heavy lifting. From generating captions and optimizing hashtags to suggesting posting times—our AI assistant helps you create better content faster, so you can focus on what matters.',
        },
    ],
} as const;

// Tech Stack
export const techStack = {
    title: 'Built on speed and security',
    items: ['Flutter', 'FastAPI', 'PostgreSQL', 'Google Cloud', 'WebSockets'],
} as const;

// Roadmap / Coming Soon
export const roadmap = {
    title: "What's Coming Next",
    items: [
        {
            icon: '🤖',
            title: 'Advanced AI Generation',
            description: "Let Vextra's AI help you draft, refine, and optimize your posts automatically.",
        },
        {
            icon: '📸',
            title: 'Instagram Integration',
            description: 'Publish directly to Instagram with auto-formatting and hashtag suggestions.',
        },
        {
            icon: '🐦',
            title: 'X (Twitter) Integration',
            description: 'Thread creation and scheduling for X coming soon.',
        },
        {
            icon: '📘',
            title: 'Facebook Integration',
            description: 'Manage your Facebook presence alongside other platforms.',
        },
    ],
} as const;

// Team
export const team = {
    title: 'Meet the Team',
    subtitle: 'Built by creators, for creators.',
    members: [
        {
            name: 'Rajveer Goud',
            role: 'Lead Developer',
            linkedin: 'https://linkedin.com/in/rajveergoud',
            image: '/rajveer.jpeg',
        },
        {
            name: 'Nitin Patel',
            role: 'Developer',
            linkedin: 'https://linkedin.com/in/nitinpatel',
            image: '/nitin.png',
        },
        {
            name: 'Ayush Nagre',
            role: 'Developer',
            linkedin: 'https://linkedin.com/in/ayushnagre',
        },
        {
            name: 'Shivani Gupta',
            role: 'Developer',
            linkedin: 'https://linkedin.com/in/shivanigupta',
        },
        {
            name: 'Pankaj Bairagi',
            role: 'Developer',
            linkedin: 'https://linkedin.com/in/pankajbairagi',
        },
    ],
} as const;

// FAQ
export const faq = {
    title: 'Frequently Asked Questions',
    items: [
        {
            question: 'What is Vextra?',
            answer: 'Vextra is an AI-powered content management system designed for creators. It helps you create, manage, and publish content across multiple platforms from a single mobile app.',
        },
        {
            question: 'Is Vextra free to use?',
            answer: 'Yes! Vextra is currently free during our early access phase. Download the app and start creating today.',
        },
        {
            question: 'Which platforms does Vextra support?',
            answer: 'Currently, Vextra supports publishing to LinkedIn and our built-in Inspire feed. Instagram, X (Twitter), and Facebook integrations are coming soon.',
        },
        {
            question: 'Is my content secure?',
            answer: 'Absolutely. Your content is encrypted and stored securely on Google Cloud infrastructure. We never share your content with third parties.',
        },
        {
            question: 'Can I use Vextra on iOS?',
            answer: 'Vextra is currently available for Android. iOS support is on our roadmap and coming soon.',
        },
        {
            question: 'How does the AI assistance work?',
            answer: 'Our AI helps you generate captions, suggest hashtags, and enhance your content. Simply provide a prompt or upload media, and let AI do the heavy lifting.',
        },
    ],
} as const;

// Download/CTA Section
export const download = {
    title: 'Ready to shape the future of content?',
    subtitle: "Don't let your ideas get lost in the noise.",
    cta: {
        primary: { label: 'Download Vextra APK', href: '/app-arm64-v8a-release.apk', download: true },
        secondary: { label: 'Follow Vextra Labs', href: 'https://linkedin.com/company/vextralabs' },
    },
    note: 'Available for Android. iOS coming soon.',
} as const;

// Footer
export const footer = {
    copyright: '© 2025 Vextra Labs. All rights reserved.',
    links: [
        { label: 'Privacy Policy', href: '/privacy' },
        { label: 'Terms of Service', href: '/terms' },
        { label: 'Contact', href: '/contact' },
    ],
    social: [
        { platform: 'LinkedIn', href: 'https://linkedin.com/company/vextralabs', icon: '💼' },
        { platform: 'Twitter', href: 'https://twitter.com/vextralabs', icon: '🐦' },
        { platform: 'GitHub', href: 'https://github.com/vextralabs', icon: '🐙' },
    ],
} as const;

// Contact Page
export const contact = {
    title: "Let's talk about your ideas",
    subtitle: "Have a question, feedback, or a collaboration in mind? We're here to help. Drop us a message and the Vextra team will get back to you shortly.",
    email: 'hello@vextralabs.com',
    form: {
        title: '📝 Contact Form',
        submitLabel: 'Send Message',
    },
} as const;

// SEO Metadata
export const seo = {
    title: `${brand.name} | ${brand.tagline}`,
    description: brand.description,
    keywords: ['content management', 'AI', 'social media', 'creator tools', 'LinkedIn', 'publishing'],
} as const;
