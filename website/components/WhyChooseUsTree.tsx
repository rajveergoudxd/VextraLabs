'use client'

import { useEffect, useRef, useState, useCallback } from 'react'

interface TreeNode {
    icon?: string
    title: string
    description: string
}

interface WhyChooseUsTreeProps {
    items: TreeNode[]
    title?: string
    subtitle?: string
}

export function WhyChooseUsTree({ items, title, subtitle }: WhyChooseUsTreeProps) {
    const containerRef = useRef<HTMLDivElement>(null)
    const trunkFillRef = useRef<HTMLDivElement>(null)
    const trunkGlowRef = useRef<HTMLDivElement>(null)
    const [visibleNodes, setVisibleNodes] = useState<Set<number>>(new Set())
    const currentProgress = useRef(0)
    const targetProgress = useRef(0)
    const animationFrameId = useRef<number | null>(null)

    // Check which nodes are visible based on scroll position
    const checkVisibleNodes = useCallback(() => {
        if (!containerRef.current) return

        const nodes = containerRef.current.querySelectorAll('[data-node-index]')
        const newVisible = new Set<number>()

        nodes.forEach((node) => {
            const rect = node.getBoundingClientRect()
            const windowHeight = window.innerHeight
            const nodeIndex = parseInt(node.getAttribute('data-node-index') || '0')

            // Trigger when node is 20% visible from bottom
            if (rect.top < windowHeight * 0.85) {
                newVisible.add(nodeIndex)
            }
        })

        setVisibleNodes(newVisible)
    }, [])

    // Calculate target scroll progress
    const updateTargetProgress = useCallback(() => {
        if (!containerRef.current) return

        const rect = containerRef.current.getBoundingClientRect()
        const windowHeight = window.innerHeight
        const containerTop = rect.top
        const containerHeight = rect.height

        // Calculate how much of the container has been scrolled through
        const scrolledPast = windowHeight - containerTop
        const totalScrollable = containerHeight + windowHeight * 0.3
        const progress = Math.min(Math.max(scrolledPast / totalScrollable, 0), 1)

        targetProgress.current = progress
    }, [])

    // Smooth animation loop using lerp
    const animateProgress = useCallback(() => {
        const lerp = (start: number, end: number, factor: number) => {
            return start + (end - start) * factor
        }

        // Smoothly interpolate towards target
        currentProgress.current = lerp(currentProgress.current, targetProgress.current, 0.08)

        // Update DOM directly for smooth animation
        if (trunkFillRef.current) {
            trunkFillRef.current.style.height = `${currentProgress.current * 100}%`
        }
        if (trunkGlowRef.current) {
            trunkGlowRef.current.style.height = `${currentProgress.current * 100}%`
            trunkGlowRef.current.style.opacity = currentProgress.current > 0 ? '1' : '0'
        }

        animationFrameId.current = requestAnimationFrame(animateProgress)
    }, [])

    useEffect(() => {
        const handleScroll = () => {
            checkVisibleNodes()
            updateTargetProgress()
        }

        // Initial check
        handleScroll()

        // Start animation loop
        animationFrameId.current = requestAnimationFrame(animateProgress)

        window.addEventListener('scroll', handleScroll, { passive: true })
        window.addEventListener('resize', handleScroll, { passive: true })

        return () => {
            window.removeEventListener('scroll', handleScroll)
            window.removeEventListener('resize', handleScroll)
            if (animationFrameId.current) {
                cancelAnimationFrame(animationFrameId.current)
            }
        }
    }, [checkVisibleNodes, updateTargetProgress, animateProgress])

    return (
        <div className="why-tree-vertical" ref={containerRef}>
            {/* Header */}
            <div className="why-tree-header">
                <span className="section-tag animate-tag">Why Choose Us</span>
                <h2>
                    {title || 'Not just another tool.'}<br />
                    <span className="gradient-text animate-gradient">{subtitle || 'A new way of working.'}</span>
                </h2>
            </div>

            {/* Tree Container */}
            <div className="tree-container">
                {/* Central Trunk Line */}
                <div className="tree-trunk">
                    <div
                        ref={trunkFillRef}
                        className="tree-trunk-fill"
                    />
                    <div
                        ref={trunkGlowRef}
                        className="tree-trunk-glow"
                    />
                </div>

                {/* Nodes */}
                <div className="tree-nodes-container">
                    {items.map((item, index) => {
                        const isLeft = index % 2 === 0
                        const isVisible = visibleNodes.has(index)

                        return (
                            <div
                                key={index}
                                className={`tree-node-row ${isLeft ? 'node-left' : 'node-right'} ${isVisible ? 'visible' : ''}`}
                                data-node-index={index}
                            >
                                {/* Branch Line */}
                                <div className={`tree-branch ${isVisible ? 'animate' : ''}`}>
                                    <svg
                                        className="branch-svg"
                                        viewBox="0 0 100 60"
                                        preserveAspectRatio="none"
                                    >
                                        <path
                                            className="branch-path"
                                            d={isLeft
                                                ? "M 100 30 Q 70 30, 50 30 T 0 30"
                                                : "M 0 30 Q 30 30, 50 30 T 100 30"
                                            }
                                        />
                                    </svg>
                                </div>

                                {/* Node Connector Dot on Trunk */}
                                <div className={`trunk-connector-dot ${isVisible ? 'visible' : ''}`}>
                                    <div className="dot-pulse"></div>
                                </div>

                                {/* Content Card */}
                                <div className={`tree-node-card ${isVisible ? 'visible' : ''}`}>
                                    <div className="node-card-inner">
                                        <div className="node-icon-wrapper">
                                            <div className="node-icon-glow"></div>
                                            <div className="node-icon">
                                                {item.icon || '✓'}
                                            </div>
                                        </div>
                                        <div className="node-text">
                                            <h3>{item.title}</h3>
                                            <p>{item.description}</p>
                                        </div>
                                        <div className="node-card-shine"></div>
                                    </div>
                                </div>
                            </div>
                        )
                    })}
                </div>

                {/* End Dot */}
                <div
                    className={`tree-end-dot ${visibleNodes.size === items.length ? 'visible' : ''}`}
                >
                    <span>✨</span>
                </div>
            </div>
        </div>
    )
}
