'use client'

import { useEffect, useRef } from 'react'
import Image from 'next/image'

const screenshots = [
    {
        src: '/screenshot-craft.jpg',
        alt: 'Craft Post Screen',
        title: 'Create with AI',
        description: 'Craft perfect posts with AI-powered suggestions',
    },
    {
        src: '/screenshot-review.jpg',
        alt: 'Review & Publish Screen',
        title: 'Review & Publish',
        description: 'Preview and publish to multiple platforms',
    },
    {
        src: '/screenshot-profile-filter.jpg',
        alt: 'Profile with Filters',
        title: 'Edit Media',
        description: 'Professional editing tools at your fingertips',
    },
]

export function AppShowcase() {
    const containerRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        const container = containerRef.current
        if (!container) return

        const handleMouseMove = (e: MouseEvent) => {
            const cards = container.querySelectorAll('.phone-card')
            const rect = container.getBoundingClientRect()
            const centerX = rect.left + rect.width / 2
            const centerY = rect.top + rect.height / 2

            const mouseX = e.clientX - centerX
            const mouseY = e.clientY - centerY

            cards.forEach((card, index) => {
                const element = card as HTMLElement
                const depth = (index - 1) * 0.5
                const rotateY = (mouseX / rect.width) * 15 + depth * 10
                const rotateX = -(mouseY / rect.height) * 10
                const translateZ = 50 + index * 20

                element.style.transform = `
          perspective(1000px)
          rotateY(${rotateY}deg)
          rotateX(${rotateX}deg)
          translateZ(${translateZ}px)
        `
            })
        }

        const handleMouseLeave = () => {
            const cards = container.querySelectorAll('.phone-card')
            cards.forEach((card, index) => {
                const element = card as HTMLElement
                element.style.transform = ''
            })
        }

        container.addEventListener('mousemove', handleMouseMove)
        container.addEventListener('mouseleave', handleMouseLeave)

        return () => {
            container.removeEventListener('mousemove', handleMouseMove)
            container.removeEventListener('mouseleave', handleMouseLeave)
        }
    }, [])

    return (
        <section className="app-showcase" id="preview">
            <div className="container">
                <div className="section-header">
                    <h2>Experience <span className="gradient-text">Vextra</span></h2>
                    <p className="section-subtitle">See the app in action</p>
                </div>

                <div className="showcase-wrapper" ref={containerRef}>
                    <div className="floating-elements">
                        <div className="floating-circle c1"></div>
                        <div className="floating-circle c2"></div>
                        <div className="floating-circle c3"></div>
                    </div>

                    <div className="phone-carousel">
                        {screenshots.map((screenshot, index) => (
                            <div
                                key={index}
                                className={`phone-card phone-${index}`}
                                style={{ '--i': index } as React.CSSProperties}
                            >
                                <div className="phone-frame">
                                    <div className="phone-notch"></div>
                                    <div className="phone-screen">
                                        <Image
                                            src={screenshot.src}
                                            alt={screenshot.alt}
                                            fill
                                            style={{ objectFit: 'cover' }}
                                            sizes="(max-width: 768px) 200px, 280px"
                                        />
                                    </div>
                                </div>
                                <div className="phone-info">
                                    <h4>{screenshot.title}</h4>
                                    <p>{screenshot.description}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    )
}
