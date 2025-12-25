'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { navigation, brand } from '@/lib/site-config'

export function Navbar() {
    const [isMenuOpen, setIsMenuOpen] = useState(false)
    const [isScrolled, setIsScrolled] = useState(false)
    const [activeSection, setActiveSection] = useState('')

    // Handle scroll effects
    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 50)

            // Determine active section
            const sections = ['features', 'how-it-works', 'preview', 'team']
            for (const section of sections) {
                const element = document.getElementById(section)
                if (element) {
                    const rect = element.getBoundingClientRect()
                    if (rect.top <= 100 && rect.bottom >= 100) {
                        setActiveSection(section)
                        break
                    }
                }
            }
        }

        window.addEventListener('scroll', handleScroll, { passive: true })
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    return (
        <>
            <nav className={`navbar ${isScrolled ? 'navbar-scrolled' : ''}`}>
                {/* Animated background */}
                <div className="navbar-bg">
                    <div className="navbar-gradient"></div>
                </div>

                <div className="container nav-container">
                    {/* Logo with glow */}
                    <Link href="/" className="logo">
                        <div className="logo-glow"></div>
                        <Image
                            src={brand.logoDark}
                            alt={brand.name}
                            width={140}
                            height={40}
                            className="logo-image"
                            priority
                        />
                    </Link>

                    {/* Desktop Navigation */}
                    <div className="nav-links">
                        {navigation.links.map((link, index) => (
                            <Link
                                key={link.href}
                                href={link.href}
                                className={`nav-link ${activeSection === link.href.replace('/#', '') ? 'active' : ''}`}
                                style={{ '--delay': `${index * 0.1}s` } as React.CSSProperties}
                            >
                                <span className="nav-link-text">{link.label}</span>
                                <span className="nav-link-indicator"></span>
                            </Link>
                        ))}
                    </div>

                    {/* CTA Button with glow */}
                    <a
                        href={navigation.cta.href}
                        className="nav-cta-btn"
                        download={navigation.cta.download}
                    >
                        <span className="cta-glow"></span>
                        <span className="cta-icon">⚡</span>
                        <span className="cta-text">{navigation.cta.label}</span>
                    </a>

                    {/* Mobile Menu Toggle */}
                    <button
                        className={`mobile-menu-toggle ${isMenuOpen ? 'active' : ''}`}
                        onClick={() => setIsMenuOpen(!isMenuOpen)}
                        aria-label="Toggle menu"
                    >
                        <span className="hamburger-line"></span>
                        <span className="hamburger-line"></span>
                        <span className="hamburger-line"></span>
                    </button>
                </div>
            </nav>

            {/* Mobile Menu */}
            <div className={`mobile-menu ${isMenuOpen ? 'open' : ''}`}>
                <div className="mobile-menu-bg"></div>
                <div className="mobile-menu-content">
                    {navigation.links.map((link, index) => (
                        <Link
                            key={link.href}
                            href={link.href}
                            onClick={() => setIsMenuOpen(false)}
                            className="mobile-nav-link"
                            style={{ '--delay': `${index * 0.1}s` } as React.CSSProperties}
                        >
                            <span className="mobile-link-number">0{index + 1}</span>
                            <span className="mobile-link-text">{link.label}</span>
                        </Link>
                    ))}
                    <a
                        href={navigation.cta.href}
                        className="mobile-cta-btn"
                        download={navigation.cta.download}
                        onClick={() => setIsMenuOpen(false)}
                    >
                        <span className="cta-icon">⚡</span>
                        {navigation.cta.label}
                    </a>
                </div>
            </div>

            {/* Overlay */}
            {isMenuOpen && (
                <div
                    className="mobile-menu-overlay"
                    onClick={() => setIsMenuOpen(false)}
                />
            )}
        </>
    )
}
