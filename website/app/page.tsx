'use client'

import Link from 'next/link'
import { FeatureCard } from '@/components/FeatureCard'
import { TeamMember } from '@/components/TeamMember'
import { FAQSection } from '@/components/FAQSection'
import { AppShowcase } from '@/components/AppShowcase'
import { HeroPhone } from '@/components/HeroPhone'
import {
    AnimatedSection,
    AnimatedCard,
    TiltCard,
    MagneticButton,
    FloatingGradients,
    Sparkles
} from '@/components/Animations'
import {
    hero,
    problems,
    solution,
    howItWorks,
    features,
    differentiators,
    techStack,
    roadmap,
    team,
    faq,
} from '@/lib/site-config'

export default function HomePage() {
    return (
        <>
            {/* Hero Section */}
            <header className="hero">
                <div className="hero-bg-gradient"></div>
                <div className="hero-grid-bg"></div>
                <Sparkles />
                <div className="container hero-content">
                    <div className="hero-text">
                        <div className="hero-badge">
                            <span className="badge-dot"></span>
                            <span>Now in Early Access</span>
                        </div>
                        <h1 className="hero-title">
                            {hero.titleLine1}<br />
                            {hero.titleLine2} <span className="gradient-text animate-gradient">{hero.titleHighlight}</span>
                        </h1>
                        <p className="hero-subtitle">
                            {hero.subtitle}
                        </p>
                        <div className="hero-cta">
                            <div className="hero-buttons">
                                <MagneticButton
                                    href={hero.cta.primary.href}
                                    className="btn btn-primary btn-lg btn-glow"
                                    download={hero.cta.primary.download}
                                >
                                    <span className="btn-icon">📱</span>
                                    {hero.cta.primary.label}
                                </MagneticButton>
                                <MagneticButton href={hero.cta.secondary.href} className="btn btn-secondary btn-lg">
                                    {hero.cta.secondary.label}
                                </MagneticButton>
                            </div>
                            <p className="hero-pledge">{hero.pledge}</p>
                        </div>

                        {/* Stats */}
                        <div className="hero-stats">
                            <div className="stat-item">
                                <span className="stat-number counter-animate">5+</span>
                                <span className="stat-label">Platforms</span>
                            </div>
                            <div className="stat-divider"></div>
                            <div className="stat-item">
                                <span className="stat-number">AI</span>
                                <span className="stat-label">Powered</span>
                            </div>
                            <div className="stat-divider"></div>
                            <div className="stat-item">
                                <span className="stat-number">∞</span>
                                <span className="stat-label">Possibilities</span>
                            </div>
                        </div>
                    </div>

                    <HeroPhone />
                </div>

                {/* Scroll indicator */}
                <div className="scroll-indicator">
                    <div className="scroll-mouse">
                        <div className="scroll-wheel"></div>
                    </div>
                    <span>Scroll to explore</span>
                </div>
            </header>

            {/* Problem Section */}
            <AnimatedSection className="problem-section" id="problem">
                <FloatingGradients />
                <div className="container">
                    <div className="section-header">
                        <span className="section-tag animate-tag">The Problem</span>
                        <h2 className="section-title-animate">{problems.title}</h2>
                    </div>
                    <div className="problem-grid">
                        {problems.items.map((problem, index) => (
                            <TiltCard key={index} className="problem-card-wrapper">
                                <AnimatedCard delay={index * 150} className="problem-card">
                                    <div className="problem-icon-wrapper">
                                        <div className="icon animate-bounce-in">{problem.icon}</div>
                                    </div>
                                    <h3>{problem.title}</h3>
                                    <p>{problem.description}</p>
                                    <div className="card-glow"></div>
                                </AnimatedCard>
                            </TiltCard>
                        ))}
                    </div>
                </div>
            </AnimatedSection>

            {/* Intro Section */}
            <AnimatedSection className="intro-section">
                <div className="container">
                    <div className="intro-content">
                        <span className="section-tag animate-tag">The Solution</span>
                        <h2 className="intro-title">
                            {solution.title} <span className="brand-highlight">{solution.subtitle}</span>
                        </h2>
                        <p className="intro-text">
                            {solution.description}
                        </p>
                        <div className="intro-visual">
                            <div className="orbit-ring ring-1"></div>
                            <div className="orbit-ring ring-2"></div>
                            <div className="orbit-ring ring-3"></div>
                        </div>
                    </div>
                </div>
            </AnimatedSection>

            {/* App Showcase - 3D Section */}
            <AppShowcase />

            {/* How It Works */}
            <AnimatedSection className="how-it-works" id="how-it-works">
                <Sparkles />
                <div className="container">
                    <div className="section-header">
                        <span className="section-tag animate-tag">How It Works</span>
                        <h2>{howItWorks.title}</h2>
                    </div>
                    <div className="steps-container">
                        <div className="steps-line animate-line"></div>
                        <div className="steps-grid">
                            {howItWorks.steps.map((step, index) => (
                                <AnimatedCard key={index} delay={index * 200} className="step-card">
                                    <div className="step-number-wrapper pulse-ring">
                                        <div className="step-number">{step.number}</div>
                                    </div>
                                    <h3>{step.title}</h3>
                                    <p>{step.description}</p>
                                    <div className="step-connector"></div>
                                </AnimatedCard>
                            ))}
                        </div>
                    </div>
                </div>
            </AnimatedSection>

            {/* Features Section */}
            <AnimatedSection className="features-section" id="features">
                <FloatingGradients />
                <div className="container">
                    <div className="section-header">
                        <span className="section-tag animate-tag">Features</span>
                        <h2>{features.title}</h2>
                    </div>
                    <div className="features-grid">
                        {features.items.map((feature, index) => (
                            <TiltCard key={index} className="feature-card-wrapper">
                                <AnimatedCard delay={index * 100} className="feature-card">
                                    <div className="feature-icon animate-float" style={{ animationDelay: `${index * 0.2}s` }}>
                                        {feature.icon}
                                    </div>
                                    <h3>{feature.title}</h3>
                                    <p>{feature.description}</p>
                                    <div className="feature-shine"></div>
                                </AnimatedCard>
                            </TiltCard>
                        ))}
                    </div>
                </div>
            </AnimatedSection>

            {/* Why Vextra */}
            <AnimatedSection className="why-vextra" id="why">
                <div className="container">
                    <div className="why-content">
                        <div className="section-header">
                            <span className="section-tag animate-tag">Why Choose Us</span>
                            <h2>
                                {differentiators.title}<br />
                                <span className="gradient-text animate-gradient">{differentiators.subtitle}</span>
                            </h2>
                        </div>
                        <ul className="differentiators">
                            {differentiators.items.map((item, index) => (
                                <AnimatedCard key={index} delay={index * 150}>
                                    <li className="differentiator-item">
                                        <span className="check-circle animate-pop">
                                            <span className="check">✓</span>
                                        </span>
                                        <div className="differentiator-content">
                                            <strong>{item.title}</strong>
                                            <p>{item.description}</p>
                                        </div>
                                        <div className="item-glow"></div>
                                    </li>
                                </AnimatedCard>
                            ))}
                        </ul>
                    </div>
                </div>
            </AnimatedSection>

            {/* Tech Section */}
            <AnimatedSection className="tech-section">
                <div className="container">
                    <h2>{techStack.title}</h2>
                    <div className="tech-stack">
                        {techStack.items.map((tech, index) => (
                            <AnimatedCard key={index} delay={index * 100}>
                                <MagneticButton className="tech-item">
                                    <span className="tech-icon">⚡</span>
                                    {tech}
                                </MagneticButton>
                            </AnimatedCard>
                        ))}
                    </div>
                </div>
            </AnimatedSection>

            {/* Roadmap Section */}
            <AnimatedSection className="roadmap-section" id="roadmap">
                <Sparkles />
                <div className="container">
                    <div className="section-header">
                        <span className="section-tag animate-tag">Coming Soon</span>
                        <h2>{roadmap.title}</h2>
                    </div>
                    <div className="roadmap-grid">
                        {roadmap.items.map((item, index) => (
                            <TiltCard key={index} className="roadmap-card-wrapper">
                                <AnimatedCard delay={index * 150} className="roadmap-item">
                                    <div className="roadmap-icon animate-bounce-in">{item.icon}</div>
                                    <h3>{item.title}</h3>
                                    <p>{item.description}</p>
                                    <div className="coming-soon-badge pulse">Coming Soon</div>
                                    <div className="card-border-glow"></div>
                                </AnimatedCard>
                            </TiltCard>
                        ))}
                    </div>
                </div>
            </AnimatedSection>

            {/* Team Section */}
            <AnimatedSection className="team-section" id="team">
                <FloatingGradients />
                <div className="container">
                    <div className="section-header">
                        <span className="section-tag animate-tag">Our Team</span>
                        <h2>{team.title}</h2>
                        <p className="section-subtitle">{team.subtitle}</p>
                    </div>
                    <div className="team-grid">
                        {team.members.map((member, index) => (
                            <AnimatedCard key={index} delay={index * 100}>
                                <TeamMember
                                    name={member.name}
                                    role={member.role}
                                    linkedin={member.linkedin}
                                />
                            </AnimatedCard>
                        ))}
                    </div>
                </div>
            </AnimatedSection>

            {/* FAQ Section */}
            <FAQSection title={faq.title} items={[...faq.items]} />
        </>
    )
}
