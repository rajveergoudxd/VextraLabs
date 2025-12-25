import Link from 'next/link'
import { footer, download, brand } from '@/lib/site-config'

export function Footer() {
    return (
        <footer className="footer" id="download">
            <div className="container footer-content">
                {/* Download CTA Section */}
                <div className="footer-cta">
                    <h2>{download.title}</h2>
                    <p>{download.subtitle}</p>
                    <div className="cta-buttons">
                        <a
                            href={download.cta.primary.href}
                            className="btn btn-primary btn-lg"
                            download={download.cta.primary.download}
                        >
                            <span className="btn-icon">📱</span>
                            {download.cta.primary.label}
                        </a>
                        <a
                            href={download.cta.secondary.href}
                            className="btn btn-secondary btn-lg"
                            target="_blank"
                            rel="noopener noreferrer"
                        >
                            {download.cta.secondary.label}
                        </a>
                    </div>
                    <p className="download-note">{download.note}</p>
                </div>

                {/* Footer Links */}
                <div className="footer-grid">
                    <div className="footer-brand">
                        <h3>{brand.name}<span className="dot">.</span></h3>
                        <p>{brand.shortDescription}</p>
                    </div>

                    <div className="footer-links-group">
                        <h4>Quick Links</h4>
                        <div className="footer-quick-links">
                            {footer.links.map((link) => (
                                <Link key={link.href} href={link.href}>
                                    {link.label}
                                </Link>
                            ))}
                        </div>
                    </div>

                    <div className="footer-social-group">
                        <h4>Connect</h4>
                        <div className="footer-social">
                            {footer.social.map((social) => (
                                <a
                                    key={social.platform}
                                    href={social.href}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="social-link"
                                    aria-label={social.platform}
                                >
                                    <span className="social-icon">{social.icon}</span>
                                    <span className="social-label">{social.platform}</span>
                                </a>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Copyright */}
                <div className="footer-bottom">
                    <p>{footer.copyright}</p>
                </div>
            </div>
        </footer>
    )
}
