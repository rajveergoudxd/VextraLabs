'use client'

import { Navbar } from '@/components/Navbar'
import { Footer } from '@/components/Footer'
import { brand } from '@/lib/site-config'

export default function PrivacyPolicyPage() {
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
                        <h1>Privacy Policy</h1>
                        <p className="legal-meta">
                            Last updated: {lastUpdated} • Effective: {effectiveDate}
                        </p>
                    </div>
                </div>

                <div className="legal-content">
                    <div className="container legal-container">
                        <nav className="legal-toc">
                            <h3>Contents</h3>
                            <ul>
                                <li><a href="#introduction">Introduction</a></li>
                                <li><a href="#information-we-collect">Information We Collect</a></li>
                                <li><a href="#how-we-collect">How We Collect Information</a></li>
                                <li><a href="#how-we-use">How We Use Your Information</a></li>
                                <li><a href="#information-sharing">Information Sharing</a></li>
                                <li><a href="#data-security">Data Security</a></li>
                                <li><a href="#your-rights">Your Rights</a></li>
                                <li><a href="#third-party-services">Third-Party Services</a></li>
                                <li><a href="#childrens-privacy">Children's Privacy</a></li>
                                <li><a href="#policy-changes">Changes to This Policy</a></li>
                                <li><a href="#contact">Contact Us</a></li>
                            </ul>
                        </nav>

                        <article className="legal-article">
                            <section id="introduction">
                                <h2>1. Introduction</h2>
                                <p>
                                    Welcome to {brand.name}. We respect your privacy and are committed to protecting your personal data.
                                    This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our
                                    mobile application and related services (collectively, the "Service").
                                </p>
                                <p>
                                    By using {brand.name}, you agree to the collection and use of information in accordance with this policy.
                                    If you do not agree with our policies and practices, please do not use our Service.
                                </p>
                                <p>
                                    {brand.name} is operated by Vextra Labs. Throughout this policy, "we," "us," and "our" refer to Vextra Labs,
                                    and "you" or "your" refers to you, the user of our Service.
                                </p>
                            </section>

                            <section id="information-we-collect">
                                <h2>2. Information We Collect</h2>

                                <h3>2.1 Personal Information You Provide</h3>
                                <p>When you create an account or use our Service, you may provide us with:</p>
                                <ul>
                                    <li><strong>Account Information:</strong> Your name, email address, username, and profile picture</li>
                                    <li><strong>Authentication Data:</strong> Passwords and security credentials (stored securely using encryption)</li>
                                    <li><strong>Profile Information:</strong> Bio, links, and other information you choose to add to your profile</li>
                                    <li><strong>Content:</strong> Posts, drafts, images, videos, and other content you create through our Service</li>
                                    <li><strong>Communications:</strong> Messages you send through our chat feature and any correspondence with us</li>
                                </ul>

                                <h3>2.2 Social Media Information</h3>
                                <p>When you connect social media accounts to {brand.name}, we receive:</p>
                                <ul>
                                    <li><strong>LinkedIn:</strong> Profile information, access tokens, and permission to publish on your behalf</li>
                                    <li><strong>Future Integrations:</strong> Similar information from Twitter, Instagram, and Facebook when those integrations become available</li>
                                </ul>
                                <p>
                                    We only request the minimum permissions necessary to provide our Service. You can revoke these permissions at any time
                                    through your social media account settings.
                                </p>

                                <h3>2.3 Automatically Collected Information</h3>
                                <p>When you use our Service, we automatically collect:</p>
                                <ul>
                                    <li><strong>Device Information:</strong> Device type, operating system, unique device identifiers</li>
                                    <li><strong>Usage Data:</strong> Features you use, content you view, and actions you take</li>
                                    <li><strong>Log Data:</strong> Access times, error logs, and referring pages</li>
                                    <li><strong>Location Data:</strong> General location based on IP address (we do not collect precise GPS location)</li>
                                </ul>
                            </section>

                            <section id="how-we-collect">
                                <h2>3. How We Collect Information</h2>

                                <h3>3.1 Direct Collection</h3>
                                <p>
                                    We collect information directly from you when you register for an account, create content, update your profile,
                                    connect social media accounts, or contact our support team.
                                </p>

                                <h3>3.2 OAuth Authentication</h3>
                                <p>
                                    When you connect social media platforms like LinkedIn, we use OAuth 2.0, an industry-standard secure authorization protocol.
                                    This means:
                                </p>
                                <ul>
                                    <li>We never see or store your social media passwords</li>
                                    <li>You grant us specific, limited permissions</li>
                                    <li>You can revoke access at any time from your social media settings</li>
                                    <li>Access tokens are stored securely and encrypted</li>
                                </ul>

                                <h3>3.3 Automatic Collection</h3>
                                <p>
                                    We use standard technologies like cookies and analytics tools to automatically collect usage information.
                                    This helps us understand how you use our Service and improve your experience.
                                </p>
                            </section>

                            <section id="how-we-use">
                                <h2>4. How We Use Your Information</h2>
                                <p>We use your information to:</p>
                                <ul>
                                    <li><strong>Provide Our Service:</strong> Create and manage your account, enable content creation and publishing, and facilitate social platform integrations</li>
                                    <li><strong>Improve Our Service:</strong> Analyze usage patterns, identify bugs, and develop new features</li>
                                    <li><strong>Personalize Your Experience:</strong> Customize content recommendations in our Inspire feed</li>
                                    <li><strong>Communicate With You:</strong> Send important updates, respond to inquiries, and provide customer support</li>
                                    <li><strong>Ensure Security:</strong> Detect and prevent fraud, abuse, and security threats</li>
                                    <li><strong>AI Features:</strong> Power our AI-assisted writing and content enhancement tools (your content is processed securely and not used to train AI models)</li>
                                </ul>
                            </section>

                            <section id="information-sharing">
                                <h2>5. Information Sharing</h2>

                                <h3>5.1 Social Platforms</h3>
                                <p>
                                    When you publish content through {brand.name} to connected social platforms, your content is shared according to
                                    those platforms' terms and privacy policies. This is the core functionality of our Service and requires sharing
                                    your content with the platforms you've chosen.
                                </p>

                                <h3>5.2 Service Providers</h3>
                                <p>We work with trusted third-party companies to:</p>
                                <ul>
                                    <li><strong>Cloud Hosting:</strong> Google Cloud Platform securely stores your data</li>
                                    <li><strong>AI Services:</strong> Process content enhancements (data is not retained after processing)</li>
                                    <li><strong>Analytics:</strong> Understand usage patterns to improve our Service</li>
                                </ul>

                                <h3>5.3 Legal Requirements</h3>
                                <p>We may disclose your information if required to:</p>
                                <ul>
                                    <li>Comply with applicable laws, regulations, or legal processes</li>
                                    <li>Respond to lawful requests from public authorities</li>
                                    <li>Protect our rights, privacy, safety, or property</li>
                                    <li>Enforce our Terms of Service</li>
                                </ul>

                                <h3>5.4 What We Never Do</h3>
                                <ul>
                                    <li>We never sell your personal information to third parties</li>
                                    <li>We never share your content for advertising purposes without your consent</li>
                                    <li>We never use your private content to train AI models</li>
                                </ul>
                            </section>

                            <section id="data-security">
                                <h2>6. Data Security</h2>
                                <p>
                                    We take the security of your data seriously and implement industry-standard measures to protect it:
                                </p>
                                <ul>
                                    <li><strong>Encryption:</strong> All data is encrypted in transit (TLS/HTTPS) and at rest</li>
                                    <li><strong>Secure Storage:</strong> Data is stored on Google Cloud Platform with enterprise-grade security</li>
                                    <li><strong>Access Controls:</strong> Strict internal access controls limit who can access your data</li>
                                    <li><strong>Password Security:</strong> Passwords are hashed using industry-standard algorithms</li>
                                    <li><strong>Token Security:</strong> OAuth tokens are encrypted and stored securely</li>
                                    <li><strong>Regular Audits:</strong> We regularly review and update our security practices</li>
                                </ul>
                                <p>
                                    While we strive to protect your information, no method of transmission over the internet is 100% secure.
                                    We cannot guarantee absolute security but are committed to implementing best practices.
                                </p>
                            </section>

                            <section id="your-rights">
                                <h2>7. Your Rights</h2>
                                <p>You have the right to:</p>
                                <ul>
                                    <li><strong>Access Your Data:</strong> Request a copy of the personal information we hold about you</li>
                                    <li><strong>Correct Your Data:</strong> Update or correct inaccurate information through your profile settings</li>
                                    <li><strong>Delete Your Data:</strong> Request deletion of your account and associated data</li>
                                    <li><strong>Export Your Data:</strong> Request a portable copy of your content and data</li>
                                    <li><strong>Revoke Permissions:</strong> Disconnect social media accounts or revoke specific permissions</li>
                                    <li><strong>Opt Out:</strong> Unsubscribe from marketing communications at any time</li>
                                </ul>
                                <p>
                                    To exercise these rights, contact us at hello@vextralabs.com or use the settings within the app.
                                    We will respond to your request within 30 days.
                                </p>
                            </section>

                            <section id="third-party-services">
                                <h2>8. Third-Party Services</h2>

                                <h3>8.1 Social Media Platforms</h3>
                                <p>
                                    {brand.name} integrates with social media platforms to enable cross-platform publishing. When you connect these accounts,
                                    their respective privacy policies also apply:
                                </p>
                                <ul>
                                    <li><a href="https://www.linkedin.com/legal/privacy-policy" target="_blank" rel="noopener noreferrer">LinkedIn Privacy Policy</a></li>
                                    <li><a href="https://twitter.com/en/privacy" target="_blank" rel="noopener noreferrer">Twitter/X Privacy Policy</a> (Coming Soon)</li>
                                    <li><a href="https://privacycenter.instagram.com/policy" target="_blank" rel="noopener noreferrer">Instagram Privacy Policy</a> (Coming Soon)</li>
                                    <li><a href="https://www.facebook.com/privacy/policy" target="_blank" rel="noopener noreferrer">Facebook Privacy Policy</a> (Coming Soon)</li>
                                </ul>

                                <h3>8.2 Third-Party Links</h3>
                                <p>
                                    Our Service may contain links to third-party websites or services. We are not responsible for the privacy practices
                                    of these external sites. We encourage you to review their privacy policies before providing any personal information.
                                </p>
                            </section>

                            <section id="childrens-privacy">
                                <h2>9. Children's Privacy</h2>
                                <p>
                                    {brand.name} is not intended for users under the age of 13 (or 16 in certain jurisdictions).
                                    We do not knowingly collect personal information from children. If you are a parent or guardian and believe
                                    your child has provided us with personal information, please contact us immediately at hello@vextralabs.com.
                                </p>
                                <p>
                                    If we discover that we have collected information from a child without proper parental consent,
                                    we will take steps to delete that information promptly.
                                </p>
                            </section>

                            <section id="policy-changes">
                                <h2>10. Changes to This Policy</h2>
                                <p>
                                    We may update this Privacy Policy from time to time to reflect changes in our practices, technologies,
                                    legal requirements, or for other operational reasons.
                                </p>
                                <p>When we make changes:</p>
                                <ul>
                                    <li>We will update the "Last Updated" date at the top of this page</li>
                                    <li>For significant changes, we will notify you via email or in-app notification</li>
                                    <li>Your continued use of the Service after changes constitutes acceptance of the updated policy</li>
                                </ul>
                                <p>
                                    We encourage you to review this Privacy Policy periodically to stay informed about how we protect your information.
                                </p>
                            </section>

                            <section id="contact">
                                <h2>11. Contact Us</h2>
                                <p>
                                    If you have questions, concerns, or requests regarding this Privacy Policy or our data practices,
                                    please contact us:
                                </p>
                                <div className="contact-info">
                                    <p><strong>Vextra Labs</strong></p>
                                    <p>Email: <a href="mailto:hello@vextralabs.com">hello@vextralabs.com</a></p>
                                    <p>Website: <a href="/contact">Contact Form</a></p>
                                </div>
                                <p>
                                    We are committed to resolving any concerns about your privacy and will respond to all inquiries
                                    within a reasonable timeframe.
                                </p>
                            </section>
                        </article>
                    </div>
                </div>
            </main>
            <Footer />
        </>
    )
}
