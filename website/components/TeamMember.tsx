'use client'

import { useEffect, useRef } from 'react'

interface TeamMemberProps {
    name: string
    role: string
    linkedin?: string
}

export function TeamMember({ name, role, linkedin }: TeamMemberProps) {
    const cardRef = useRef<HTMLDivElement>(null)

    const initials = name
        .split(' ')
        .map((n) => n[0])
        .join('')
        .toUpperCase()

    // 3D tilt effect
    useEffect(() => {
        const card = cardRef.current
        if (!card) return

        const handleMouseMove = (e: MouseEvent) => {
            const rect = card.getBoundingClientRect()
            const x = e.clientX - rect.left
            const y = e.clientY - rect.top
            const centerX = rect.width / 2
            const centerY = rect.height / 2

            const rotateX = (y - centerY) / 8
            const rotateY = (centerX - x) / 8

            card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(20px)`
        }

        const handleMouseLeave = () => {
            card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) translateZ(0)'
        }

        card.addEventListener('mousemove', handleMouseMove)
        card.addEventListener('mouseleave', handleMouseLeave)

        return () => {
            card.removeEventListener('mousemove', handleMouseMove)
            card.removeEventListener('mouseleave', handleMouseLeave)
        }
    }, [])

    const content = (
        <div className="team-member-card" ref={cardRef}>
            {/* Animated background gradient */}
            <div className="team-card-bg"></div>

            {/* Glowing ring */}
            <div className="team-avatar-ring">
                <div className="team-avatar">
                    <div className="avatar-glow"></div>
                    <span>{initials}</span>
                </div>
            </div>

            {/* Info */}
            <div className="team-info">
                <h4>{name}</h4>
                <p>{role}</p>
            </div>

            {/* Social indicator */}
            {linkedin && (
                <div className="team-social">
                    <div className="social-ripple"></div>
                    <span className="linkedin-icon">in</span>
                </div>
            )}

            {/* Shine effect */}
            <div className="team-card-shine"></div>

            {/* Border glow */}
            <div className="team-card-border"></div>
        </div>
    )

    if (linkedin) {
        return (
            <a
                href={linkedin}
                target="_blank"
                rel="noopener noreferrer"
                className="team-member-link"
            >
                {content}
            </a>
        )
    }

    return content
}
