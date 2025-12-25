'use client'

import { useEffect, useRef, ReactNode } from 'react'

interface AnimatedSectionProps {
    children: ReactNode
    className?: string
    id?: string
    delay?: number
}

export function AnimatedSection({ children, className = '', id, delay = 0 }: AnimatedSectionProps) {
    const sectionRef = useRef<HTMLElement>(null)

    useEffect(() => {
        const section = sectionRef.current
        if (!section) return

        const observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        setTimeout(() => {
                            section.classList.add('animate-in')
                        }, delay)
                        observer.unobserve(section)
                    }
                })
            },
            { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
        )

        observer.observe(section)

        return () => observer.disconnect()
    }, [delay])

    return (
        <section ref={sectionRef} className={`animated-section ${className}`} id={id}>
            {children}
        </section>
    )
}

// Animated card that reveals on scroll
interface AnimatedCardProps {
    children: ReactNode
    className?: string
    delay?: number
}

export function AnimatedCard({ children, className = '', delay = 0 }: AnimatedCardProps) {
    const cardRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        const card = cardRef.current
        if (!card) return

        const observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        setTimeout(() => {
                            card.classList.add('card-animate-in')
                        }, delay)
                        observer.unobserve(card)
                    }
                })
            },
            { threshold: 0.1 }
        )

        observer.observe(card)

        return () => observer.disconnect()
    }, [delay])

    return (
        <div ref={cardRef} className={`animated-card ${className}`}>
            {children}
        </div>
    )
}

// Floating gradient background component
export function FloatingGradients() {
    return (
        <div className="floating-gradients">
            <div className="gradient-blob blob-1"></div>
            <div className="gradient-blob blob-2"></div>
            <div className="gradient-blob blob-3"></div>
        </div>
    )
}

// Sparkle effect component - using fixed positions to avoid hydration mismatch
const sparklePositions = [
    { x: 15, y: 20 },
    { x: 85, y: 15 },
    { x: 25, y: 75 },
    { x: 70, y: 30 },
    { x: 45, y: 60 },
    { x: 90, y: 70 },
    { x: 10, y: 45 },
    { x: 55, y: 85 },
    { x: 35, y: 25 },
    { x: 80, y: 55 },
    { x: 20, y: 90 },
    { x: 65, y: 40 },
    { x: 40, y: 10 },
    { x: 75, y: 80 },
    { x: 50, y: 50 },
]

const sparkleScales = [0.6, 0.8, 0.5, 0.9, 0.7, 0.55, 0.85, 0.65, 0.75, 0.95, 0.5, 0.8, 0.6, 0.7, 0.9]

export function Sparkles() {
    return (
        <div className="sparkles">
            {sparklePositions.map((pos, i) => (
                <div
                    key={i}
                    className="sparkle"
                    style={{
                        '--sparkle-delay': `${i * 0.3}s`,
                        '--sparkle-x': `${pos.x}%`,
                        '--sparkle-y': `${pos.y}%`,
                        '--sparkle-scale': sparkleScales[i],
                    } as React.CSSProperties}
                />
            ))}
        </div>
    )
}

// Animated counter component
interface CounterProps {
    end: number | string
    suffix?: string
    duration?: number
}

export function AnimatedCounter({ end, suffix = '', duration = 2000 }: CounterProps) {
    const counterRef = useRef<HTMLSpanElement>(null)
    const hasAnimated = useRef(false)

    useEffect(() => {
        const counter = counterRef.current
        if (!counter) return

        const observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting && !hasAnimated.current) {
                        hasAnimated.current = true

                        if (typeof end === 'number') {
                            let startTime: number | null = null
                            const startValue = 0

                            const animate = (timestamp: number) => {
                                if (!startTime) startTime = timestamp
                                const progress = Math.min((timestamp - startTime) / duration, 1)
                                const currentValue = Math.floor(progress * (end - startValue) + startValue)

                                if (counter) {
                                    counter.textContent = currentValue + suffix
                                }

                                if (progress < 1) {
                                    requestAnimationFrame(animate)
                                } else {
                                    counter.textContent = end + suffix
                                }
                            }

                            requestAnimationFrame(animate)
                        } else {
                            counter.textContent = end + suffix
                        }

                        observer.unobserve(counter)
                    }
                })
            },
            { threshold: 0.5 }
        )

        observer.observe(counter)

        return () => observer.disconnect()
    }, [end, suffix, duration])

    return <span ref={counterRef} className="animated-counter">0{suffix}</span>
}

// 3D tilt card effect
interface TiltCardProps {
    children: ReactNode
    className?: string
}

export function TiltCard({ children, className = '' }: TiltCardProps) {
    const cardRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        const card = cardRef.current
        if (!card) return

        const handleMouseMove = (e: MouseEvent) => {
            const rect = card.getBoundingClientRect()
            const x = e.clientX - rect.left
            const y = e.clientY - rect.top
            const centerX = rect.width / 2
            const centerY = rect.height / 2

            const rotateX = (y - centerY) / 10
            const rotateY = (centerX - x) / 10

            card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale3d(1.02, 1.02, 1.02)`
        }

        const handleMouseLeave = () => {
            card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale3d(1, 1, 1)'
        }

        card.addEventListener('mousemove', handleMouseMove)
        card.addEventListener('mouseleave', handleMouseLeave)

        return () => {
            card.removeEventListener('mousemove', handleMouseMove)
            card.removeEventListener('mouseleave', handleMouseLeave)
        }
    }, [])

    return (
        <div ref={cardRef} className={`tilt-card ${className}`}>
            {children}
        </div>
    )
}

// Magnetic button effect
interface MagneticButtonProps {
    children: ReactNode
    className?: string
    href?: string
    download?: boolean
    onClick?: () => void
}

export function MagneticButton({ children, className = '', href, download, onClick }: MagneticButtonProps) {
    const buttonRef = useRef<HTMLAnchorElement | HTMLButtonElement>(null)

    useEffect(() => {
        const button = buttonRef.current
        if (!button) return

        const handleMouseMove = (e: Event) => {
            const mouseEvent = e as MouseEvent
            const rect = button.getBoundingClientRect()
            const x = mouseEvent.clientX - rect.left - rect.width / 2
            const y = mouseEvent.clientY - rect.top - rect.height / 2

            button.style.transform = `translate(${x * 0.3}px, ${y * 0.3}px)`
        }

        const handleMouseLeave = () => {
            button.style.transform = 'translate(0, 0)'
        }

        button.addEventListener('mousemove', handleMouseMove)
        button.addEventListener('mouseleave', handleMouseLeave)

        return () => {
            button.removeEventListener('mousemove', handleMouseMove)
            button.removeEventListener('mouseleave', handleMouseLeave)
        }
    }, [])

    if (href) {
        return (
            <a
                ref={buttonRef as React.RefObject<HTMLAnchorElement>}
                href={href}
                download={download}
                className={`magnetic-btn ${className}`}
            >
                {children}
            </a>
        )
    }

    return (
        <button
            ref={buttonRef as React.RefObject<HTMLButtonElement>}
            onClick={onClick}
            className={`magnetic-btn ${className}`}
        >
            {children}
        </button>
    )
}

// Text reveal animation
interface TextRevealProps {
    text: string
    className?: string
}

export function TextReveal({ text, className = '' }: TextRevealProps) {
    const textRef = useRef<HTMLSpanElement>(null)

    useEffect(() => {
        const textElement = textRef.current
        if (!textElement) return

        const observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        textElement.classList.add('revealed')
                        observer.unobserve(textElement)
                    }
                })
            },
            { threshold: 0.5 }
        )

        observer.observe(textElement)

        return () => observer.disconnect()
    }, [])

    return (
        <span ref={textRef} className={`text-reveal ${className}`}>
            {text.split('').map((char, i) => (
                <span
                    key={i}
                    className="text-reveal-char"
                    style={{ '--char-delay': `${i * 0.03}s` } as React.CSSProperties}
                >
                    {char === ' ' ? '\u00A0' : char}
                </span>
            ))}
        </span>
    )
}

// Parallax container
interface ParallaxProps {
    children: ReactNode
    speed?: number
    className?: string
}

export function Parallax({ children, speed = 0.5, className = '' }: ParallaxProps) {
    const parallaxRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        const element = parallaxRef.current
        if (!element) return

        const handleScroll = () => {
            const rect = element.getBoundingClientRect()
            const scrolled = window.innerHeight - rect.top
            const translate = scrolled * speed * 0.1

            element.style.transform = `translateY(${translate}px)`
        }

        window.addEventListener('scroll', handleScroll, { passive: true })

        return () => window.removeEventListener('scroll', handleScroll)
    }, [speed])

    return (
        <div ref={parallaxRef} className={`parallax ${className}`}>
            {children}
        </div>
    )
}
