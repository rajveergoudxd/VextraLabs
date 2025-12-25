import type { Metadata } from 'next'
import { Outfit, Space_Grotesk } from 'next/font/google'
import './globals.css'
import { Navbar } from '@/components/Navbar'
import { Footer } from '@/components/Footer'

const outfit = Outfit({
    subsets: ['latin'],
    variable: '--font-heading',
    display: 'swap',
})

const spaceGrotesk = Space_Grotesk({
    subsets: ['latin'],
    variable: '--font-body',
    display: 'swap',
})

export const metadata: Metadata = {
    title: 'Vextra | Create once. Publish everywhere.',
    description: 'Vextra is the first AI-Powered Content Management System designed to help you break free from platform chaos.',
}

export default function RootLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <html lang="en" className={`${outfit.variable} ${spaceGrotesk.variable}`} suppressHydrationWarning>
            <body suppressHydrationWarning>
                <Navbar />
                {children}
                <Footer />
            </body>
        </html>
    )
}
