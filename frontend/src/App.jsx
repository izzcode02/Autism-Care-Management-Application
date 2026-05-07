import { useState, useEffect, useRef } from 'react'
import { Link } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import './App.css'

// ── SVG Icons ──────────────────────────────────────────────────────────────────
const IconMap = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" /><circle cx="12" cy="10" r="3" />
  </svg>
)
const IconBrain = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 5a3 3 0 1 0-5.997.125 4 4 0 0 0-2.526 5.77 4 4 0 0 0 .556 6.588A4 4 0 1 0 12 18Z" />
    <path d="M12 5a3 3 0 1 1 5.997.125 4 4 0 0 1 2.526 5.77 4 4 0 0 1-.556 6.588A4 4 0 1 1 12 18Z" />
    <path d="M15 13a4.5 4.5 0 0 1-3-4 4.5 4.5 0 0 1-3 4" />
    <path d="M17.599 6.5a3 3 0 0 0 .399-1.375M6.003 5.125A3 3 0 0 0 6.401 6.5M3.477 10.896a4 4 0 0 1 .585-.396M19.938 10.5a4 4 0 0 1 .585.396M6 18a4 4 0 0 1-1.967-.516M19.967 17.484A4 4 0 0 1 18 18" />
  </svg>
)
const IconCalendar = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="4" width="18" height="18" rx="2" ry="2" /><line x1="16" y1="2" x2="16" y2="6" /><line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
  </svg>
)
const IconMsg = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
  </svg>
)
const IconShield = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </svg>
)
const IconArrow = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" />
  </svg>
)
const IconCheck = () => (
  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="20 6 9 17 4 12" />
  </svg>
)
const IconMenu = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <line x1="3" y1="12" x2="21" y2="12" /><line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="18" x2="21" y2="18" />
  </svg>
)
const IconX = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
  </svg>
)
const IconApple = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
    <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
  </svg>
)
const IconAndroid = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
    <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" />
  </svg>
)

// ── Animated counter ───────────────────────────────────────────────────────────
function Counter({ to, suffix = '' }) {
  const [count, setCount] = useState(0)
  const ref = useRef(null)
  const triggered = useRef(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !triggered.current) {
        triggered.current = true
        const duration = 2000
        const start = Date.now()
        const tick = () => {
          const progress = Math.min((Date.now() - start) / duration, 1)
          const eased = 1 - Math.pow(1 - progress, 3)
          setCount(Math.floor(eased * to))
          if (progress < 1) requestAnimationFrame(tick)
        }
        requestAnimationFrame(tick)
      }
    }, { threshold: 0.5 })
    obs.observe(el)
    return () => obs.disconnect()
  }, [to])

  return <span ref={ref}>{count}{suffix}</span>
}

// ── Animation variants ─────────────────────────────────────────────────────────
const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.4, 0, 0.2, 1] } }
}
const fadeLeft = {
  hidden: { opacity: 0, x: -30 },
  visible: { opacity: 1, x: 0, transition: { duration: 0.6, ease: [0.4, 0, 0.2, 1] } }
}
const fadeRight = {
  hidden: { opacity: 0, x: 30 },
  visible: { opacity: 1, x: 0, transition: { duration: 0.6, ease: [0.4, 0, 0.2, 1] } }
}
const stagger = {
  visible: { transition: { staggerChildren: 0.08 } }
}

// ── Header ─────────────────────────────────────────────────────────────────────
function Header() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const links = [
    { label: 'Fitur', href: '#features' },
    { label: 'Aplikasi', href: '#showcase' },
    { label: 'Tentang', href: '#about' },
    { label: 'Hubungi', href: '#contact' },
    { label: 'Muat Turun', href: '#download'},
  ]

  return (
    <motion.header
      className={`header ${scrolled ? 'scrolled' : ''}`}
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6, ease: 'easeOut' }}
    >
      <div className="container header-inner">
        <a href="#" className="logo">
          <div className="logo-icon-box"><img src='/public/logo.png'></img></div>
          <span className="logo-text">AutiCare</span>
        </a>

        <nav className="nav">
          {links.map(l => <a key={l.href} href={l.href}>{l.label}</a>)}
        </nav>

        <div className="header-actions">
          <Link to="/auth" className="btn btn-emerald" style={{ padding: '10px 22px', fontSize: 13 }}>
            Log Masuk Admin
          </Link>
          <button className="menu-toggle" onClick={() => setOpen(o => !o)}>
            {open ? <IconX /> : <IconMenu />}
          </button>
        </div>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            className="nav-mobile"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.25 }}
          >
            {links.map(l => (
              <a key={l.href} href={l.href} onClick={() => setOpen(false)}>{l.label}</a>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  )
}

// ── Hero ───────────────────────────────────────────────────────────────────────
function Hero() {
  return (
    <section className="hero">
      {/* Mesh blobs */}
      <div className="mesh-blob" style={{ top: '8%', right: '-5%', width: 600, height: 600, background: 'radial-gradient(circle, rgba(34,197,94,0.12) 0%, transparent 70%)' }} />
      <div className="mesh-blob" style={{ bottom: '8%', left: '-10%', width: 400, height: 400, background: 'radial-gradient(circle, rgba(212,168,83,0.07) 0%, transparent 70%)' }} />

      <div className="container">
        <div className="hero-grid">
          {/* Left text */}
          <motion.div initial="hidden" animate="visible" variants={stagger}>
            <motion.div variants={fadeUp} className="hero-eyebrow">
              <div className="badge-gold">
                <div className="pulse-dot" />
                AutiCare: Autism Care Management Mobile Application
              </div>
            </motion.div>

            <motion.h1 variants={fadeUp} className="hero-title">
              Pusat Autisme<br />
              <em className="text-emerald-grad text-italic">Tepat untuk<br />Anak Anda.</em>
            </motion.h1>

            <motion.p variants={fadeUp} className="hero-subtitle">
              AutiCare membantu ibu bapa dan penjaga mencari pusat autisme yang sesuai
              berdasarkan kriteria, lokasi, dan keperluan anak anda.
            </motion.p>

            <motion.div variants={fadeUp} className="hero-buttons">
              <a href="#download" className="btn btn-emerald">Muat Turun App <IconArrow /></a>
              <a href="#features" className="btn btn-ghost">Lihat Fitur</a>
            </motion.div>

            <motion.div variants={fadeUp} className="hero-stats">
              <div className="hero-stat-item">
                <div className="stat-big">100+</div>
                <div className="stat-small">Pusat Berdaftar</div>
              </div>
              <div className="hero-stat-item">
                <div className="stat-big">500+</div>
                <div className="stat-small">Keluarga Dibantu</div>
              </div>
            </motion.div>
          </motion.div>

          {/* Right – floating cards */}
          <motion.div
            className="hero-cards"
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <motion.div
              className="hero-card"
              animate={{ y: [0, -8, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
            >
              <div className="card-icon-box card-icon-emerald"><IconMap /></div>
              <div>
                <div className="card-label">Cari Pusat Terdekat</div>
                <div className="card-sub">Geolocation & Geofencing</div>
              </div>
              <div className="badge-emerald" style={{ marginLeft: 'auto' }}>Live</div>
            </motion.div>

            <div className="hero-card-row">
              <motion.div
                className="hero-card-sm"
                animate={{ y: [0, 6, 0] }}
                transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut', delay: 0.5 }}
              >
                <div className="card-icon-box card-icon-emerald" style={{ marginBottom: 12 }}><IconBrain /></div>
                <div className="card-label" style={{ fontSize: 14 }}>Cadangan Pintar</div>
                <div className="card-sub">AI-powered</div>
              </motion.div>

              <motion.div
                className="hero-card-sm"
                animate={{ y: [0, -6, 0] }}
                transition={{ duration: 4.5, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
              >
                <div className="card-icon-box card-icon-gold" style={{ marginBottom: 12 }}><IconCalendar /></div>
                <div className="card-label" style={{ fontSize: 14 }}>Jejak Kehadiran</div>
                <div className="card-sub">Auto geofencing</div>
              </motion.div>
            </div>

            <div className="hero-ring hero-ring-lg" />
            <div className="hero-ring hero-ring-sm" />
          </motion.div>
        </div>
      </div>
    </section>
  )
}

// ── Features ───────────────────────────────────────────────────────────────────
const FEATURES = [
  { icon: <IconMap />, title: 'Cari Pusat Autisme', desc: 'Senaraikan dan cari pusat autisme terdekat dengan teknologi geolokasi canggih.', tag: 'Geolocation', color: 'emerald', span: 1 },
  { icon: <IconBrain />, title: 'Cadangan Pintar', desc: 'Cadangan pusat berdasarkan jenis autisme, umur, dan jarak dari rumah melalui AI.', tag: 'AI', color: 'gold', span: 1 },
  { icon: <IconCalendar />, title: 'Jejak Kehadiran Automatik', desc: 'Pengesahan kehadiran automatik dengan geofencing untuk ketenangan fikiran ibu bapa — tanpa perlu log masuk manual setiap hari.', tag: 'Geofencing', color: 'emerald', span: 2 },
  { icon: <IconMsg />, title: 'AI Autism Chatbot', desc: 'Maklumat dan nasihat tentang autisme daripada AI yang terlatih khusus.', tag: 'AI Chat', color: 'gold', span: 1 },
  { icon: <IconShield />, title: 'Pengurusan Aktiviti', desc: 'Rancang dan pantau aktiviti harian anak anda di pusat dengan mudah.', tag: 'Dashboard', color: 'emerald', span: 1 },
]

function Features() {
  return (
    <section id="features" className="section">
      <div className="container">
        <motion.div
          className="features-header"
          initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
        >
          <span className="section-num">01 — Fitur Utama</span>
          <h2>
            Semua yang anda perlukan,{' '}
            <em className="text-emerald-grad text-italic">dalam satu app.</em>
          </h2>
        </motion.div>

        <div className="bento-grid">
          {FEATURES.map((f, i) => (
            <motion.div
              key={i}
              className={`bento-card ${f.span === 2 ? 'span-2' : ''}`}
              initial="hidden" whileInView="visible" viewport={{ once: true }}
              variants={fadeUp}
              transition={{ delay: i * 0.07 }}
            >
              <div
                className="feature-icon-box"
                style={{
                  background: f.color === 'emerald' ? 'rgba(34,197,94,0.1)' : 'rgba(212,168,83,0.1)',
                  border: `1px solid ${f.color === 'emerald' ? 'rgba(34,197,94,0.2)' : 'rgba(212,168,83,0.2)'}`,
                  color: f.color === 'emerald' ? 'var(--emerald)' : 'var(--gold)',
                }}
              >
                {f.icon}
              </div>
              <div style={{ flex: 1 }}>
                <div className="feature-title-row">
                  <h3>{f.title}</h3>
                  <span className="tag-pill">{f.tag}</span>
                </div>
                <p className="feature-desc">{f.desc}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

// ── Showcase ───────────────────────────────────────────────────────────────────
const SCREENS = [
  { title: 'Dashboard Utama', desc: 'Akses pantas kepada semua fitur', accent: 'emerald' },
  { title: 'Cari Pusat', desc: 'Peta interaktif dengan geofencing', accent: 'gold' },
  { title: 'Profil Penjaga', desc: 'Urus kehadiran dan aktiviti harian', accent: 'emerald' },
]

function Showcase() {
  return (
    <section id="showcase" className="section section-alt">
      <div className="container">
        <motion.div
          className="showcase-header"
          initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger}
        >
          <div>
            <motion.span variants={fadeUp} className="section-num">02 — Lihat Aplikasi</motion.span>
            <motion.h2 variants={fadeUp}>
              Antaramuka yang{' '}
              <em style={{ fontStyle: 'italic', color: 'var(--gold)' }}>dirangka dengan teliti.</em>
            </motion.h2>
          </div>
          <motion.p variants={fadeUp}>
            Direka untuk ibu bapa dan penjaga — bukan untuk jurutera. Mudah, cepat, dan intuitif.
          </motion.p>
        </motion.div>

        <motion.div
          className="showcase-grid"
          initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger}
        >
          {SCREENS.map((s, i) => (
            <motion.div key={i} className="showcase-card" variants={fadeUp}>
              <div className="showcase-screen-area">
                <div className="phone-shell">
                  <div className={`phone-inner ${s.accent === 'emerald' ? 'phone-inner-emerald' : 'phone-inner-gold'}`}>
                    <div style={{ color: s.accent === 'emerald' ? 'var(--emerald)' : 'var(--gold)' }}>
                      <IconShield />
                    </div>
                    <div className="phone-bar phone-bar-accent" style={{ background: s.accent === 'emerald' ? 'var(--emerald)' : 'var(--gold)' }} />
                    <div className="phone-bar phone-bar-muted" style={{ width: 32 }} />
                    <div className="phone-bar phone-bar-muted" style={{ width: 44 }} />
                  </div>
                </div>
              </div>
              <div className="showcase-info">
                <h3>{s.title}</h3>
                <p>{s.desc}</p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}

// ── About ──────────────────────────────────────────────────────────────────────
const STATS = [
  { n: 100, suffix: '+', label: 'Pusat Autisme Berdaftar di Malaysia' },
  { n: 500, suffix: '+', label: 'Keluarga Telah Menggunakan AutiCare' },
  { n: 98, suffix: '%', label: 'Kepuasan Pengguna Dalam Beta Testing' },
]

const CHECKS = [
  'Carian berasaskan lokasi yang tepat',
  'Cadangan AI berdasarkan profil anak',
  'Pengesahan kehadiran automatik',
  'Maklumat dan berita autisme terkini',
]

function About() {
  return (
    <section id="about" className="section" style={{ position: 'relative', overflow: 'hidden' }}>
      <div className="mesh-blob" style={{ top: '50%', left: '50%', transform: 'translate(-50%,-50%)', width: 700, height: 700, background: 'radial-gradient(circle, rgba(34,197,94,0.04) 0%, transparent 70%)' }} />

      <div className="container" style={{ position: 'relative', zIndex: 1 }}>
        {/* Stats */}
        <motion.div
          className="stats-row"
          initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger}
        >
          {STATS.map((s, i) => (
            <motion.div key={i} className="stat-card" variants={fadeUp}>
              <div className="stat-display">
                <Counter to={s.n} suffix={s.suffix} />
              </div>
              <div className="stat-label">{s.label}</div>
            </motion.div>
          ))}
        </motion.div>

        {/* About content */}
        <div className="about-grid">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeLeft}>
            <span className="section-num">03 — Kenapa AutiCare</span>
            <h2 className="about-text">
              Dibangunkan dengan{' '}
              <em className="text-emerald-grad text-italic">empati,</em> bukan hanya kod.
            </h2>
            <p style={{ marginTop: '1.5rem' }}>
              AutiCare lahir dari pemahaman mendalam tentang cabaran yang dihadapi ibu bapa
              dan penjaga kanak-kanak autisme di Malaysia. Kami faham betapa susahnya
              mencari rawatan yang tepat untuk anak tersayang.
            </p>
            <p style={{ marginTop: '1rem' }}>
              Dengan teknologi geolokasi dan cadangan berteraskan AI, kami memudahkan
              proses mencari pusat autisme yang memenuhi keperluan khusus setiap anak.
            </p>
            <div className="checklist">
              {CHECKS.map((item, i) => (
                <div key={i} className="check-item">
                  <div className="check-box"><IconCheck /></div>
                  <span className="check-label">{item}</span>
                </div>
              ))}
            </div>
          </motion.div>

          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeRight}>
            <div className="about-panel">
              <div className="panel-logo-row">
                <div className="panel-logo-box"><IconShield /></div>
                <div>
                  <div style={{ fontFamily: 'DM Serif Display, serif', fontSize: '1.4rem', color: 'var(--cream)' }}>AutiCare</div>
                  <div style={{ color: 'var(--muted)', fontSize: 12, fontWeight: 500 }}>Final Year Project · UiTM</div>
                </div>
              </div>
              <div className="panel-divider" />
              <p className="panel-quote">
                "Setiap kanak-kanak autisme berhak mendapat penjagaan terbaik. AutiCare ada untuk
                memastikan keluarga tidak perlu berjuang bersendirian mencari jalan."
              </p>
              <div className="panel-badges">
                <span className="badge-emerald">Geolocation</span>
                <span className="badge-gold">AI-Powered</span>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

// ── Download ───────────────────────────────────────────────────────────────────
const DL_FEATURES = [
  { title: 'Percuma', sub: 'Tiada kos tersembunyi' },
  { title: 'Tiada Iklan', sub: 'Pengalaman yang bersih' },
  { title: 'Selamat', sub: 'Data disulitkan sepenuhnya' },
  { title: 'Kemas kini', sub: 'Sentiasa terkini' },
]

function Download() {
  return (
    <section id="download" className="section section-alt" style={{ overflow: 'hidden' }}>
      <div className="mesh-blob" style={{ bottom: '-10%', right: '-5%', width: 500, height: 500, background: 'radial-gradient(circle, rgba(34,197,94,0.08) 0%, transparent 70%)' }} />

      <div className="container" style={{ position: 'relative', zIndex: 1 }}>
        <motion.div
          className="download-grid"
          initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger}
        >
          <div>
            <motion.div variants={fadeUp} className="download-header">
              <span className="section-num">04 — Muat Turun</span>
              <h2>
                Mula perjalanan penjagaan yang{' '}
                <em className="text-emerald-grad text-italic">lebih baik.</em>
              </h2>
            </motion.div>

            <motion.p variants={fadeUp} className="download-sub">
              Percuma untuk dimuat turun. Tiada iklan. Tiada data dijual. Hanya alat bantu
              yang anda perlukan untuk menjaga anak anda dengan lebih baik.
            </motion.p>

            <motion.div variants={fadeUp} className="store-buttons">
              <a href="#" className="btn-store">
                <IconApple />
                <div>
                  <div className="store-btn-label-small">Download on the</div>
                  <div className="store-btn-label-big">App Store</div>
                </div>
              </a>
              <a href="#" className="btn-store">
                <IconAndroid />
                <div>
                  <div className="store-btn-label-small">Get it on</div>
                  <div className="store-btn-label-big">Google Play</div>
                </div>
              </a>
            </motion.div>

            <motion.div variants={fadeUp} className="download-features">
              {DL_FEATURES.map((f, i) => (
                <div key={i} className="dl-feature">
                  <div className="dl-feature-icon"><IconCheck /></div>
                  <div>
                    <div className="dl-feature-title">{f.title}</div>
                    <div className="dl-feature-sub">{f.sub}</div>
                  </div>
                </div>
              ))}
            </motion.div>
          </div>

          {/* Phone mockup */}
          <motion.div variants={fadeRight} className="phone-mockup-wrap">
            <motion.div
              animate={{ y: [0, -12, 0] }}
              transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
              style={{ position: 'relative' }}
            >
              <div className="phone-mockup-outer">
                <div className="phone-mockup-screen">
                  <div className="phone-notch" />
                  <div className="phone-mockup-icon"><IconShield /></div>
                  <div className="phone-mockup-name">AutiCare</div>
                  <div className="phone-dots">
                    <div className="phone-dot phone-dot-active" />
                    <div className="phone-dot phone-dot-inactive" />
                    <div className="phone-dot phone-dot-inactive" />
                  </div>
                </div>
              </div>
              <div className="phone-glow-ring" />
            </motion.div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

// ── Contact ────────────────────────────────────────────────────────────────────
function Contact() {
  return (
    <section id="contact" className="section">
      <div className="container">
        <motion.div
          className="contact-header"
          initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
        >
          <span className="section-num">05 — Hubungi</span>
          <h2>
            Ada soalan?{' '}
            <em style={{ fontStyle: 'italic', color: 'var(--gold)' }}>Kami sedia membantu.</em>
          </h2>
        </motion.div>

        <div className="contact-grid">
          <motion.form
            className="contact-form"
            initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeLeft}
            onSubmit={e => e.preventDefault()}
          >
            <div className="field-row">
              <input className="field" type="text" placeholder="Nama anda" />
              <input className="field" type="email" placeholder="Alamat emel" />
            </div>
            <input className="field" type="text" placeholder="Subjek" />
            <textarea className="field" rows={5} placeholder="Tulis mesej anda..." style={{ resize: 'vertical' }} />
            <button type="submit" className="btn btn-emerald" style={{ alignSelf: 'flex-start' }}>
              Hantar Mesej <IconArrow />
            </button>
          </motion.form>

          <motion.div
            className="contact-info"
            initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeRight}
          >
            {[
              { label: 'Emel', icon: '✉', value: 'support@auticare.my' },
              { label: 'Institusi', icon: '🏛', value: 'Universiti Teknologi MARA, Malaysia' },
              { label: 'Status', icon: '📍', value: 'Projek Tahun Akhir 2025 — Beta Testing' },
            ].map(item => (
              <div key={item.label} className="info-card">
                <div className="info-card-label">
                  <span>{item.icon}</span> {item.label}
                </div>
                <div className="info-card-value">{item.value}</div>
              </div>
            ))}

            <div className="info-card">
              <div className="info-card-label">🌐 Media Sosial</div>
              <div className="social-row">
                {['Facebook', 'Twitter', 'Instagram'].map(s => (
                  <a key={s} href="#" className="social-btn">{s}</a>
                ))}
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

// ── Footer ─────────────────────────────────────────────────────────────────────
function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <div className="footer-brand">
          <div className="footer-brand-icon"><img src='./public/logo.png'></img></div>
          <span className="footer-brand-name">AutiCare</span>
        </div>

        <nav className="footer-links">
          {['Fitur', 'Tentang', 'Hubungi', 'Privasi'].map(l => (
            <a key={l} href={`#${l.toLowerCase()}`}>{l}</a>
          ))}
        </nav>

        <p className="footer-copy">
          © 2025 AutiCare · UiTM · Dibina dengan <span className="heart">♥</span> untuk komuniti autisme
        </p>
      </div>
    </footer>
  )
}

// ── App ────────────────────────────────────────────────────────────────────────
export default function App() {
  return (
    <div style={{ minHeight: '100vh', background: 'var(--obsidian)' }}>
      <Header />
      <main>
        <Hero />
        <Features />
        <Showcase />
        <About />
        <Download />
        <Contact />
      </main>
      <Footer />
    </div>
  )
}