import { useState } from 'react'
import { BrowserRouter as Router, Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Menu, X, MapPin, Brain, Calendar, MessageCircle, Shield, Heart, Smartphone, ArrowRight, CheckCircle, PlayCircle } from 'lucide-react'
import './App.css'

// Animation variants
const fadeInUp = {
  hidden: { opacity: 0, y: 40 },
  visible: { opacity: 1, y: 0 }
}

const stagger = {
  visible: { transition: { staggerChildren: 0.1 } }
}

const scaleIn = {
  hidden: { opacity: 0, scale: 0.8 },
  visible: { opacity: 1, scale: 1 }
}

function Header() {
  const [mobileMenu, setMobileMenu] = useState(false)

  return (
    <header className="header">
      <div className="container header-content">
        <Link to="/" className="logo">
          <Shield className="logo-icon" />
          <span>AutiCare</span>
        </Link>

        <nav className={`nav ${mobileMenu ? 'nav-open' : ''}`}>
          <a href="#features">Fitur</a>
          <a href="#showcase">Aplikasi</a>
          <a href="#about">Tentang</a>
          <a href="#contact">Hubungi</a>
          <a href="#download" className="btn btn-primary">Muat Turun</a>
        </nav>

        <button className="menu-toggle" onClick={() => setMobileMenu(!mobileMenu)}>
          {mobileMenu ? <X /> : <Menu />}
        </button>
      </div>
    </header>
  )
}

function Hero() {
  return (
    <section className="hero">
      <div className="container hero-content">
        <motion.div
          className="hero-text"
          initial="hidden"
          animate="visible"
          variants={stagger}
        >
          <motion.h1 variants={fadeInUp}>
            <span className="text-gradient">Pusat Autisme</span>
            <br />
            <span className="text-highlight">Tepat Untuk Anak Anda</span>
          </motion.h1>
          <p className="hero-subtitle">
            AutiCare membantu ibu bapa dan penjaga mencari pusat autisme yang sesuai
            berdasarkan kriteria, lokasi, dan keperluan anak anda.
          </p>
          <div className="hero-buttons">
            <a href="#download" className="btn btn-primary btn-lg">
              <Smartphone size={20} />
              Muat Turun App
            </a>
            <a href="#features" className="btn btn-outline btn-lg">
              <PlayCircle size={20} />
              Lihat Fitur
            </a>
          </div>
          <div className="hero-stats">
            <div className="hero-stat">
              <CheckCircle className="stat-icon" />
              <span>100+ Pusat Berdaftar</span>
            </div>
            <div className="hero-stat">
              <CheckCircle className="stat-icon" />
              <span>500+ Keluarga Dibantu</span>
            </div>
          </div>
        </motion.div>
        <motion.div
          className="hero-image"
          initial="hidden"
          animate="visible"
          variants={stagger}
        >
          <div className="hero-visual">
            <motion.div className="visual-card main-card" variants={scaleIn}>
              <MapPin className="visual-icon" />
              <div className="visual-content">
                <strong>Cari Pusat Terdekat</strong>
                <small>Geolocation & Geofencing</small>
              </div>
            </motion.div>
            <motion.div className="visual-card" variants={fadeInUp}>
              <Brain className="visual-icon" />
              <div className="visual-content">
                <strong>Disyorkan Untuk Anak</strong>
                <small>AI-powered recommendations</small>
              </div>
            </motion.div>
            <motion.div className="visual-card" variants={fadeInUp}>
              <Calendar className="visual-icon" />
              <div className="visual-content">
                <strong>Jejak Kehadiran</strong>
                <small>Automatik dengan geofencing</small>
              </div>
            </motion.div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

function Features() {
  const features = [
    {
      icon: <MapPin />,
      title: "Cari Pusat Autisme",
      desc: "Senaraikan dan cari pusat autisme terdekat dengan lokasi anda menggunakan teknologi geolokasi"
    },
    {
      icon: <Brain />,
      title: "Cadangan Pintar",
      desc: "Dapatkan cadangan pusat berdasarkan jenis autisme, umur, dan jarak dari rumah"
    },
    {
      icon: <Calendar />,
      title: "Jejak Kehadiran",
      desc: "Pengesahan kehadiran automatik dengan geofencing untuk ketenangan fikiran"
    },
    {
      icon: <MessageCircle />,
      title: "AI Autism",
      desc: "Dapatkan maklumat dan nasihat tentang autisme dari AI yang terlatih"
    },
    {
      icon: <Shield />,
      title: "Pengurusan Aktiviti",
      desc: "Rancang dan pantau aktiviti harian anak anda di pusat"
    },
    {
      icon: <Heart />,
      title: "Berita & Maklumat",
      desc: "Kemas kini terkini tentang autisme dan rawatan terkini"
    }
  ]

  return (
    <section id="features" className="section section-alt">
      <div className="container">
        <motion.div
          className="section-header"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          <motion.h2 variants={fadeInUp}>Fitur Utama</motion.h2>
          <motion.p variants={fadeInUp}>Semua yang anda perlukan untuk menguruskan penjagaan anak autisme</motion.p>
        </motion.div>
        <motion.div
          className="grid grid-3"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          {features.map((feature, idx) => (
            <motion.div
              key={idx}
              className="feature-card"
              variants={fadeInUp}
              whileHover={{ y: -8 }}
            >
              <div className="feature-icon">{feature.icon}</div>
              <h3>{feature.title}</h3>
              <p>{feature.desc}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}

function Showcase() {
  const screenshots = [
    {
      title: "Dashboard Utama",
      desc: "Akses pantas kepada semua fitur",
      color: "var(--primary-soft)"
    },
    {
      title: "Cari Pusat",
      desc: "Peta interaktif dengan geofencing",
      color: "var(--accent-soft)"
    },
    {
      title: "Dashboard Penjaga",
      desc: "Urus kehadiran dan aktiviti",
      color: "var(--warm-soft)"
    }
  ]

  return (
    <section id="showcase" className="section">
      <div className="container">
        <motion.div
          className="section-header"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          <motion.h2 variants={fadeInUp}>Lihat Aplikasi</motion.h2>
          <motion.p variants={fadeInUp}>Antaramuka yang mudah digunakan untuk ibu bapa dan penjaga</motion.p>
        </motion.div>
        <motion.div
          className="showcase-grid"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          {screenshots.map((shot, idx) => (
            <motion.div
              key={idx}
              className="showcase-card"
              variants={scaleIn}
              style={{ '--card-bg': shot.color }}
            >
              <div className="showcase-visual">
                <Smartphone size={80} className="phone-icon" />
              </div>
              <div className="showcase-info">
                <h3>{shot.title}</h3>
                <p>{shot.desc}</p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}

function About() {
  return (
    <section id="about" className="section section-alt">
      <div className="container">
        <motion.div
          className="grid grid-2 about-grid"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          <motion.div className="about-text" variants={fadeInUp}>
            <h2>Mengapa AutiCare?</h2>
            <p>
              AutiCare dibangunkan untuk membantu ibu bapa dan penjaga anak autisme
              mencari pusat yang sesuai dengan mudah. Kami faham cabaran mencari
              rawatan yang tepat untuk anak tersayang.
            </p>
            <p>
              Dengan teknologi geolokasi dan cadangan pintar, kami memudahkan proses
              mencari pusat autisme yang memenuhi keperluan khusus anak anda -
              sama ada dari segi jenis autisme, lokasi, atau umur.
            </p>
            <motion.div className="stats" variants={stagger}>
              <motion.div className="stat" variants={scaleIn}>
                <span className="stat-number">100+</span>
                <span className="stat-label">Pusat Terdaftar</span>
              </motion.div>
              <motion.div className="stat" variants={scaleIn}>
                <span className="stat-number">500+</span>
                <span className="stat-label">Keluarga Dibantu</span>
              </motion.div>
            </motion.div>
          </motion.div>
          <motion.div className="about-image" variants={fadeInUp}>
            <div className="about-visual">
              <div className="visual-box">
                <span>UiTM</span>
                <small>Final Year Project 2025</small>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

function Download() {
  return (
    <section id="download" className="section download-section">
      <div className="container">
        <motion.div
          className="download-card"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          <div className="download-content">
            <motion.h2 variants={fadeInUp}>
              <Smartphone className="download-icon" />
              Muat Turun Sekarang
            </motion.h2>
            <motion.p variants={fadeInUp}>
              Mula gunakan AutiCare hari ini untuk pengalaman penjagaan autisme yang lebih baik
            </motion.p>
            <motion.div className="download-buttons" variants={fadeInUp}>
              <a href="#" className="btn btn-store">
                <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
                  <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
                </svg>
                App Store
              </a>
              <a href="#" className="btn btn-store">
                <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
                  <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z"/>
                </svg>
                Google Play
              </a>
            </motion.div>
            <motion.div className="download-features" variants={stagger}>
              <motion.div className="download-feature" variants={fadeInUp}>
                <CheckCircle className="feature-check" />
                <span>Gratis untuk dimuat turun</span>
              </motion.div>
              <motion.div className="download-feature" variants={fadeInUp}>
                <CheckCircle className="feature-check" />
                <span>Tiada iklan</span>
              </motion.div>
              <motion.div className="download-feature" variants={fadeInUp}>
                <CheckCircle className="feature-check" />
                <span>Kemaskini percuma</span>
              </motion.div>
            </motion.div>
          </div>
          <motion.div className="download-visual" variants={scaleIn}>
            <div className="phone-mockup">
              <div className="phone-screen">
                <Shield className="mockup-icon" />
                <span>AutiCare</span>
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

function Contact() {
  return (
    <section id="contact" className="section section-alt">
      <div className="container">
        <motion.div
          className="section-header"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          <motion.h2 variants={fadeInUp}>Hubungi Kami</motion.h2>
          <motion.p variants={fadeInUp}>Ada soalan? Kami di sini untuk membantu</motion.p>
        </motion.div>
        <motion.div
          className="contact-content"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
        >
          <motion.form className="contact-form" variants={fadeInUp}>
            <input type="text" placeholder="Nama" />
            <input type="email" placeholder="Emel" />
            <textarea placeholder="Mesej" rows="4"></textarea>
            <button type="submit" className="btn btn-primary">
              Hantar Mesej
              <ArrowRight size={18} />
            </button>
          </motion.form>
          <motion.div className="contact-info" variants={stagger}>
            <motion.div className="info-item" variants={fadeInUp}>
              <h4>Emel</h4>
              <p>support@auticare.my</p>
            </motion.div>
            <motion.div className="info-item" variants={fadeInUp}>
              <h4>Lokasi</h4>
              <p>Universiti Teknologi MARA, Malaysia</p>
            </motion.div>
            <motion.div className="info-item" variants={fadeInUp}>
              <h4>Sosial</h4>
              <div className="social-links">
                <a href="#" className="social-link">Facebook</a>
                <a href="#" className="social-link">Twitter</a>
                <a href="#" className="social-link">Instagram</a>
              </div>
            </motion.div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-brand">
            <Shield className="logo-icon" />
            <span>AutiCare</span>
          </div>
          <div className="footer-links">
            <a href="#features">Fitur</a>
            <a href="#about">Tentang</a>
            <a href="#contact">Hubungi</a>
            <a href="#privacy">Privasi</a>
          </div>
          <p className="footer-text">
            &copy; 2025 AutiCare. Projek Tahun Akhir UiTM. Dibina dengan <Heart size={14} className="heart-icon" /> untuk komuniti autisme.
          </p>
        </div>
      </div>
    </footer>
  )
}

function App() {
  return (
    <Router>
      <div className="app">
        <div className="puzzle-bg"></div>
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
    </Router>
  )
}

export default App
