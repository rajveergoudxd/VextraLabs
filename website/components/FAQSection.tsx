'use client'

import { useState } from 'react'

interface FAQItemProps {
    question: string
    answer: string
    isOpen: boolean
    onToggle: () => void
}

function FAQItem({ question, answer, isOpen, onToggle }: FAQItemProps) {
    return (
        <div className={`faq-item ${isOpen ? 'open' : ''}`}>
            <button className="faq-question" onClick={onToggle}>
                <span>{question}</span>
                <span className="faq-icon">{isOpen ? '−' : '+'}</span>
            </button>
            <div className="faq-answer">
                <p>{answer}</p>
            </div>
        </div>
    )
}

interface FAQSectionProps {
    title: string
    items: Array<{ question: string; answer: string }>
}

export function FAQSection({ title, items }: FAQSectionProps) {
    const [openIndex, setOpenIndex] = useState<number | null>(0)

    return (
        <section className="faq-section" id="faq">
            <div className="container">
                <div className="section-header">
                    <h2>{title}</h2>
                </div>
                <div className="faq-list">
                    {items.map((item, index) => (
                        <FAQItem
                            key={index}
                            question={item.question}
                            answer={item.answer}
                            isOpen={openIndex === index}
                            onToggle={() => setOpenIndex(openIndex === index ? null : index)}
                        />
                    ))}
                </div>
            </div>
        </section>
    )
}
