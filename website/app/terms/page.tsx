'use client'

import { Navbar } from '@/components/Navbar'
import { Footer } from '@/components/Footer'
import { AnimatedSection } from '@/components/Animations'
import { brand } from '@/lib/site-config'

export default function TermsOfServicePage() {
    const lastUpdated = 'December 25, 2025'
    const effectiveDate = 'December 25, 2025'

    return (
        <>
            <Navbar />
            <main className="legal-page">
                <div className="legal-hero">
                    <div className="legal-hero-bg"></div>
                    <div className="container">
                        <span className="legal-badge">Legal</span>
                        <h1>Terms of Service</h1>
                        <p className="legal-meta">
                            Last updated: {lastUpdated} • Effective: {effectiveDate}
                        </p>
                    </div>
                </div>

                <AnimatedSection className="legal-content">
                    <div className="container legal-container">
                        <nav className="legal-toc">
                            <h3>Contents</h3>
                            <ul>
                                <li><a href="#acceptance">Acceptance of Terms</a></li>
                                <li><a href="#service-description">Description of Service</a></li>
                                <li><a href="#user-accounts">User Accounts</a></li>
                                <li><a href="#user-content">User Content</a></li>
                                <li><a href="#prohibited-conduct">Prohibited Conduct</a></li>
                                <li><a href="#third-party-services">Third-Party Services</a></li>
                                <li><a href="#intellectual-property">Intellectual Property</a></li>
                                <li><a href="#disclaimers">Disclaimers</a></li>
                                <li><a href="#limitation-liability">Limitation of Liability</a></li>
                                <li><a href="#indemnification">Indemnification</a></li>
                                <li><a href="#termination">Termination</a></li>
                                <li><a href="#changes">Changes to Terms</a></li>
                                <li><a href="#governing-law">Governing Law</a></li>
                                <li><a href="#contact">Contact Us</a></li>
                            </ul>
                        </nav>

                        <article className="legal-article">
                            <section id="acceptance">
                                <h2>1. Acceptance of Terms</h2>
                                <p>
                                    Welcome to {brand.name}! These Terms of Service ("Terms") govern your access to and use of the {brand.name} mobile
                                    application, website, and related services (collectively, the "Service") provided by Vextra Labs ("we," "us," or "our").
                                </p>
                                <p>
                                    By creating an account, accessing, or using our Service, you agree to be bound by these Terms. If you do not agree
                                    to these Terms, please do not use our Service.
                                </p>
                                <p>
                                    You must be at least 13 years old (or 16 in certain jurisdictions) to use our Service. By using the Service,
                                    you represent and warrant that you meet this age requirement.
                                </p>
                            </section>

                            <section id="service-description">
                                <h2>2. Description of Service</h2>
                                <p>
                                    {brand.name} is an AI-powered content management system that helps creators manage their digital presence.
                                    Our Service enables you to:
                                </p>
                                <ul>
                                    <li><strong>Create Content:</strong> Write and design posts with AI-assisted tools in a distraction-free editor</li>
                                    <li><strong>Manage Your Work:</strong> Organize drafts, ideas, and published content in a unified library</li>
                                    <li><strong>Publish Across Platforms:</strong> Connect social media accounts and publish content directly to platforms like LinkedIn</li>
                                    <li><strong>Engage with the Community:</strong> Share ideas on our Inspire feed and connect with other creators through real-time chat</li>
                                    <li><strong>Access from Anywhere:</strong> Use our mobile-first application with cloud synchronization</li>
                                </ul>
                                <p>
                                    We continuously improve and evolve our Service. Features may be added, modified, or removed as we develop {brand.name}.
                                </p>
                            </section>

                            <section id="user-accounts">
                                <h2>3. User Accounts</h2>

                                <h3>3.1 Account Registration</h3>
                                <p>
                                    To use certain features of our Service, you must create an account. When you register, you agree to:
                                </p>
                                <ul>
                                    <li>Provide accurate, current, and complete information</li>
                                    <li>Maintain and promptly update your account information</li>
                                    <li>Keep your password secure and confidential</li>
                                    <li>Accept responsibility for all activities under your account</li>
                                    <li>Notify us immediately of any unauthorized access</li>
                                </ul>

                                <h3>3.2 Account Security</h3>
                                <p>
                                    You are responsible for maintaining the security of your account credentials. We strongly recommend using a unique,
                                    strong password and enabling any additional security features we offer.
                                </p>
                                <p>
                                    We are not liable for any loss or damage arising from your failure to protect your account credentials.
                                </p>

                                <h3>3.3 One Account Per Person</h3>
                                <p>
                                    Each person may maintain only one personal account. Creating multiple accounts to evade bans, manipulate our
                                    systems, or deceive other users is prohibited.
                                </p>
                            </section>

                            <section id="user-content">
                                <h2>4. User Content</h2>

                                <h3>4.1 Your Ownership</h3>
                                <p>
                                    You retain ownership of all content you create, upload, or share through our Service ("User Content").
                                    {brand.name} does not claim ownership of your content.
                                </p>

                                <h3>4.2 License to {brand.name}</h3>
                                <p>
                                    By using our Service, you grant us a limited license to use your User Content solely to:
                                </p>
                                <ul>
                                    <li>Operate and provide the Service (including publishing to your connected platforms)</li>
                                    <li>Display your content in the Inspire feed (for content you choose to share publicly)</li>
                                    <li>Process your content through our AI features at your request</li>
                                    <li>Create backups and maintain the Service</li>
                                </ul>
                                <p>
                                    This license is non-exclusive, royalty-free, and limited to what's necessary to operate the Service.
                                    We will not use your content for advertising or sell your content to third parties without your consent.
                                </p>

                                <h3>4.3 Content Responsibility</h3>
                                <p>You are solely responsible for your User Content and agree that:</p>
                                <ul>
                                    <li>You own or have the right to use all content you post</li>
                                    <li>Your content does not infringe on others' intellectual property rights</li>
                                    <li>Your content complies with all applicable laws and these Terms</li>
                                    <li>You have consent from any individuals appearing in your content</li>
                                </ul>

                                <h3>4.4 Content Guidelines</h3>
                                <p>All content shared through our Service must adhere to our community standards:</p>
                                <ul>
                                    <li>Be respectful and constructive</li>
                                    <li>Add value to the community</li>
                                    <li>Respect others' privacy and rights</li>
                                    <li>Be authentic and original (or properly attributed)</li>
                                </ul>
                            </section>

                            <section id="prohibited-conduct">
                                <h2>5. Prohibited Conduct</h2>
                                <p>When using our Service, you agree NOT to:</p>

                                <h3>5.1 Harmful Content</h3>
                                <ul>
                                    <li>Post content that is illegal, harmful, threatening, abusive, harassing, defamatory, or discriminatory</li>
                                    <li>Share content that promotes violence, self-harm, or dangerous activities</li>
                                    <li>Upload sexually explicit content or content exploiting minors</li>
                                    <li>Spread misinformation or deceptive content</li>
                                </ul>

                                <h3>5.2 Platform Abuse</h3>
                                <ul>
                                    <li>Use automated systems (bots) without our permission</li>
                                    <li>Spam, send unsolicited messages, or engage in deceptive practices</li>
                                    <li>Attempt to manipulate our systems, algorithms, or other users</li>
                                    <li>Create fake accounts or impersonate others</li>
                                    <li>Circumvent any security measures or access restrictions</li>
                                </ul>

                                <h3>5.3 Technical Violations</h3>
                                <ul>
                                    <li>Reverse engineer, decompile, or disassemble any part of the Service</li>
                                    <li>Attempt to gain unauthorized access to our systems or user accounts</li>
                                    <li>Introduce viruses, malware, or other harmful code</li>
                                    <li>Interfere with or disrupt the Service or servers</li>
                                    <li>Scrape or harvest data from our Service</li>
                                </ul>

                                <h3>5.4 Social Platform Violations</h3>
                                <ul>
                                    <li>Violate the terms of service of connected social platforms</li>
                                    <li>Use our Service to spam or manipulate social platforms</li>
                                    <li>Post content through our Service that violates platform-specific rules</li>
                                </ul>
                            </section>

                            <section id="third-party-services">
                                <h2>6. Third-Party Services</h2>

                                <h3>6.1 Social Platform Integration</h3>
                                <p>
                                    {brand.name} integrates with third-party social media platforms to enable cross-platform publishing.
                                    When you connect your accounts:
                                </p>
                                <ul>
                                    <li>You must comply with each platform's terms of service</li>
                                    <li>Content published through {brand.name} is subject to the destination platform's policies</li>
                                    <li>We are not responsible for content once it's published to third-party platforms</li>
                                    <li>Changes to third-party APIs may affect our integration features</li>
                                </ul>

                                <h3>6.2 Currently Supported Platforms</h3>
                                <ul>
                                    <li><strong>LinkedIn:</strong> Publish professional content directly to your LinkedIn profile</li>
                                    <li><strong>Inspire Feed:</strong> Share with the {brand.name} creator community</li>
                                </ul>

                                <h3>6.3 Coming Soon</h3>
                                <ul>
                                    <li>Twitter/X Integration</li>
                                    <li>Instagram Integration</li>
                                    <li>Facebook Integration</li>
                                </ul>

                                <h3>6.4 Disclaimer</h3>
                                <p>
                                    Third-party platforms may change their APIs, terms, or features at any time. We are not responsible for
                                    any disruption to the Service caused by third-party changes. We will work to maintain integrations but
                                    cannot guarantee uninterrupted availability.
                                </p>
                            </section>

                            <section id="intellectual-property">
                                <h2>7. Intellectual Property</h2>

                                <h3>7.1 Our Property</h3>
                                <p>
                                    The {brand.name} Service, including its design, features, code, graphics, logos, and other materials
                                    (excluding User Content) are owned by Vextra Labs and protected by intellectual property laws.
                                </p>
                                <p>
                                    You may not copy, modify, distribute, sell, or lease any part of our Service without our written permission.
                                </p>

                                <h3>7.2 Trademarks</h3>
                                <p>
                                    "{brand.name}," the {brand.name} logo, and other marks are trademarks of Vextra Labs.
                                    You may not use these marks without our prior written consent.
                                </p>

                                <h3>7.3 Feedback</h3>
                                <p>
                                    If you provide suggestions, ideas, or feedback about our Service, we may use them without any obligation
                                    to compensate you. By submitting feedback, you grant us a perpetual, irrevocable license to use it.
                                </p>
                            </section>

                            <section id="disclaimers">
                                <h2>8. Disclaimers</h2>
                                <p>
                                    <strong>THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND.</strong>
                                </p>
                                <p>To the maximum extent permitted by law, we disclaim all warranties, including:</p>
                                <ul>
                                    <li>Implied warranties of merchantability, fitness for a particular purpose, and non-infringement</li>
                                    <li>Warranties that the Service will be uninterrupted, error-free, or completely secure</li>
                                    <li>Warranties regarding the accuracy of any content or information</li>
                                    <li>Warranties that defects will be corrected</li>
                                </ul>
                                <p>
                                    We do not guarantee that content published through our Service will be accepted by third-party platforms
                                    or that integrations will always function as expected.
                                </p>
                            </section>

                            <section id="limitation-liability">
                                <h2>9. Limitation of Liability</h2>
                                <p>
                                    <strong>TO THE MAXIMUM EXTENT PERMITTED BY LAW, VEXTRA LABS SHALL NOT BE LIABLE FOR:</strong>
                                </p>
                                <ul>
                                    <li>Any indirect, incidental, special, consequential, or punitive damages</li>
                                    <li>Loss of profits, data, goodwill, or other intangible losses</li>
                                    <li>Damages resulting from unauthorized access to your account</li>
                                    <li>Damages arising from third-party services or content</li>
                                    <li>Damages caused by your reliance on any content or information</li>
                                </ul>
                                <p>
                                    In no event shall our total liability exceed the amount you paid us (if any) in the twelve months
                                    preceding the claim, or $100 USD, whichever is greater.
                                </p>
                                <p>
                                    Some jurisdictions do not allow limitation of certain damages. In such cases, our liability
                                    is limited to the maximum extent permitted by applicable law.
                                </p>
                            </section>

                            <section id="indemnification">
                                <h2>10. Indemnification</h2>
                                <p>
                                    You agree to indemnify, defend, and hold harmless Vextra Labs and its officers, directors, employees,
                                    and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:
                                </p>
                                <ul>
                                    <li>Your use of the Service</li>
                                    <li>Your User Content</li>
                                    <li>Your violation of these Terms</li>
                                    <li>Your violation of any third-party rights</li>
                                    <li>Your violation of any applicable laws</li>
                                </ul>
                            </section>

                            <section id="termination">
                                <h2>11. Termination</h2>

                                <h3>11.1 Termination by You</h3>
                                <p>
                                    You may stop using our Service and delete your account at any time. To delete your account,
                                    use the account settings in the app or contact us at hello@vextralabs.com.
                                </p>

                                <h3>11.2 Termination by Us</h3>
                                <p>We may suspend or terminate your access to the Service if:</p>
                                <ul>
                                    <li>You violate these Terms or our community guidelines</li>
                                    <li>You engage in prohibited conduct</li>
                                    <li>We are required to do so by law</li>
                                    <li>Your account appears to be compromised</li>
                                    <li>We discontinue the Service (with reasonable notice)</li>
                                </ul>

                                <h3>11.3 Effect of Termination</h3>
                                <p>Upon termination:</p>
                                <ul>
                                    <li>Your right to use the Service immediately ceases</li>
                                    <li>We may delete your account data after a reasonable period</li>
                                    <li>Content you've published to third-party platforms remains there (subject to those platforms' policies)</li>
                                    <li>Provisions of these Terms that should survive termination will remain in effect</li>
                                </ul>
                            </section>

                            <section id="changes">
                                <h2>12. Changes to Terms</h2>
                                <p>
                                    We may modify these Terms from time to time. When we make material changes:
                                </p>
                                <ul>
                                    <li>We will update the "Last Updated" date at the top of this page</li>
                                    <li>We will notify you via email or in-app notification for significant changes</li>
                                    <li>Your continued use after changes constitutes acceptance</li>
                                </ul>
                                <p>
                                    If you disagree with the updated Terms, you should stop using the Service and delete your account
                                    before the changes take effect.
                                </p>
                            </section>

                            <section id="governing-law">
                                <h2>13. Governing Law</h2>
                                <p>
                                    These Terms shall be governed by and construed in accordance with the laws of India,
                                    without regard to conflict of law principles.
                                </p>
                                <p>
                                    Any disputes arising from these Terms or the Service shall be subject to the exclusive jurisdiction
                                    of the courts in India.
                                </p>
                                <p>
                                    If any provision of these Terms is found to be unenforceable, the remaining provisions will continue
                                    in full force and effect.
                                </p>
                            </section>

                            <section id="contact">
                                <h2>14. Contact Us</h2>
                                <p>
                                    If you have questions, concerns, or need clarification about these Terms, please contact us:
                                </p>
                                <div className="contact-info">
                                    <p><strong>Vextra Labs</strong></p>
                                    <p>Email: <a href="mailto:hello@vextralabs.com">hello@vextralabs.com</a></p>
                                    <p>Website: <a href="/contact">Contact Form</a></p>
                                </div>
                                <p>
                                    We're committed to working with you to resolve any issues and will respond to all inquiries
                                    within a reasonable timeframe.
                                </p>
                            </section>

                            <section className="legal-closing">
                                <p>
                                    By using {brand.name}, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
                                </p>
                                <p>
                                    Thank you for choosing {brand.name}. We're excited to help you create, manage, and share your content with the world!
                                </p>
                            </section>
                        </article>
                    </div>
                </AnimatedSection>
            </main>
            <Footer />
        </>
    )
}
