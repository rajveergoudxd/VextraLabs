'use client'

import { useEffect, useRef } from 'react'
import Image from 'next/image'

export function HeroPhone() {
    const phoneRef = useRef<HTMLDivElement>(null)
    const glowRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        const phone = phoneRef.current
        const glow = glowRef.current
        if (!phone) return

        let animationId: number
        let mouseX = 0
        let mouseY = 0
        let currentX = 0
        let currentY = 0

        const handleMouseMove = (e: MouseEvent) => {
            const rect = phone.getBoundingClientRect()
            const centerX = rect.left + rect.width / 2
            const centerY = rect.top + rect.height / 2

            mouseX = (e.clientX - centerX) / 20
            mouseY = (e.clientY - centerY) / 20
        }

        const animate = () => {
            currentX += (mouseX - currentX) * 0.1
            currentY += (mouseY - currentY) * 0.1

            phone.style.transform = `
        perspective(1000px)
        rotateY(${currentX}deg)
        rotateX(${-currentY}deg)
        translateZ(0)
      `

            if (glow) {
                glow.style.transform = `translate(${currentX * 5}px, ${currentY * 5}px)`
            }

            animationId = requestAnimationFrame(animate)
        }

        window.addEventListener('mousemove', handleMouseMove)
        animationId = requestAnimationFrame(animate)

        return () => {
            window.removeEventListener('mousemove', handleMouseMove)
            cancelAnimationFrame(animationId)
        }
    }, [])

    return (
        <div className="hero-phone-container">
            <div className="hero-glow-orb" ref={glowRef}></div>
            <div className="hero-phone" ref={phoneRef}>
                <div className="hero-phone-frame">
                    <div className="hero-phone-notch"></div>
                    <div className="hero-phone-screen">
                        <Image
                            src="/screenshot-craft.jpg"
                            alt="Vextra App"
                            fill
                            style={{ objectFit: 'cover' }}
                            priority
                            sizes="(max-width: 768px) 280px, 320px"
                        />
                    </div>
                    <div className="hero-phone-reflection"></div>
                </div>

                {/* Floating UI Elements */}
                <div className="floating-ui floating-ui-1">
                    <span>✨</span> AI Generated
                </div>
                <div className="floating-ui floating-ui-2">
                    <span>📱</span> Multi-Platform
                </div>
                <div className="floating-ui floating-ui-3">
                    <span>🚀</span> One-Click Publish
                </div>
            </div>

            {/* Particle effects - using fixed positions to avoid hydration mismatch */}
            <div className="particles">
                {[
                    { x: 10, y: 15 }, { x: 85, y: 25 }, { x: 30, y: 70 }, { x: 65, y: 10 },
                    { x: 45, y: 55 }, { x: 90, y: 65 }, { x: 15, y: 40 }, { x: 70, y: 80 },
                    { x: 35, y: 20 }, { x: 55, y: 45 }, { x: 80, y: 35 }, { x: 25, y: 85 },
                    { x: 60, y: 60 }, { x: 5, y: 75 }, { x: 50, y: 30 }, { x: 75, y: 50 },
                    { x: 40, y: 90 }, { x: 20, y: 5 }, { x: 95, y: 45 }, { x: 12, y: 58 }
                ].map((pos, i) => (
                    <div key={i} className="particle" style={{ '--delay': `${i * 0.2}s`, '--x': `${pos.x}%`, '--y': `${pos.y}%` } as React.CSSProperties}></div>
                ))}
            </div>
        </div>
    )
}
