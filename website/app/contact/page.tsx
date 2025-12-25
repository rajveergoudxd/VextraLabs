import type { Metadata } from 'next'
import { contact, seo } from '@/lib/site-config'
import styles from './contact.module.css'

export const metadata: Metadata = {
    title: `Contact | ${seo.title}`,
    description: contact.subtitle,
}

export default function ContactPage() {
    return (
        <section className={`contact-section ${styles.contactPage}`} id="contact">
            <div className="container">
                <div className="contact-content">
                    <div className="contact-header">
                        <h2>{contact.title}</h2>
                        <p>{contact.subtitle}</p>
                    </div>
                    <div className="contact-form-wrapper">
                        <h3>{contact.form.title}</h3>
                        <form className="contact-form">
                            <div className="form-row">
                                <div className="form-group">
                                    <label htmlFor="firstName">First Name</label>
                                    <input
                                        type="text"
                                        id="firstName"
                                        name="firstName"
                                        placeholder="Enter your first name"
                                        required
                                    />
                                </div>
                                <div className="form-group">
                                    <label htmlFor="lastName">Last Name</label>
                                    <input
                                        type="text"
                                        id="lastName"
                                        name="lastName"
                                        placeholder="Enter your last name"
                                        required
                                    />
                                </div>
                            </div>
                            <div className="form-group">
                                <label htmlFor="email">Email Address</label>
                                <input
                                    type="email"
                                    id="email"
                                    name="email"
                                    placeholder="yourname@email.com"
                                    required
                                />
                            </div>
                            <div className="form-group">
                                <label htmlFor="subject">Subject</label>
                                <select id="subject" name="subject">
                                    <option value="general">General Inquiry</option>
                                    <option value="feedback">Feedback</option>
                                    <option value="partnership">Partnership</option>
                                    <option value="support">Support</option>
                                    <option value="other">Other</option>
                                </select>
                            </div>
                            <div className="form-group">
                                <label htmlFor="message">Message</label>
                                <textarea
                                    id="message"
                                    name="message"
                                    rows={5}
                                    placeholder="Tell us what you'd like to discuss — questions, feedback, partnerships, or anything else. We're listening."
                                    required
                                ></textarea>
                            </div>
                            <button type="submit" className="btn btn-primary btn-block">
                                {contact.form.submitLabel}
                            </button>
                        </form>
                    </div>

                    {/* Contact Info */}
                    <div className="contact-info">
                        <div className="contact-info-item">
                            <span className="contact-icon">📧</span>
                            <div>
                                <h4>Email</h4>
                                <a href={`mailto:${contact.email}`}>{contact.email}</a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    )
}
