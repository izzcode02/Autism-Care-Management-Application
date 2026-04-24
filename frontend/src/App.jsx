import { useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom'
import { Menu, X, MapPin, Brain, Calendar, MessageCircle, Shield, Heart } from 'lucide-react'
import './App.css'

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
        <div className="hero-text">
          <h1>
            <span className="text-gradient">Pusat Autisme</span>
            <br />
            Tepat Untuk Anak Anda
          </h1>
          <p className="hero-subtitle">
            AutiCare membantu ibu bapa dan penjaga mencari pusat autisme yang sesuai
            berdasarkan kriteria, lokasi, dan keperluan anak anda.
          </p>
          <div className="hero-buttons">
            <a href="#download" className="btn btn-primary">
              Muat Turun App
            </a>
            <a href="#features" className="btn btn-outline">
              Lihat Fitur
            </a>
          </div>
        </div>
        <div className="hero-image">
          <div className="hero-visual">
            <div className="visual-card">
              <MapPin className="visual-icon" />
              <span>Cari Pusat Terdekat</span>
            </div>
            <div className="visual-card">
              <Brain className="visual-icon" />
              <span>Disyorkan Untuk Anak</span>
            </div>
            <div className="visual-card">
              <Calendar className="visual-icon" />
              <span>Jejak Kehadiran</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

function Features() {
  const features = [
    {
      icon: <MapPin />,
      title: "Cari Pusat Autisme",
      desc: "Senaraikan dan cari pusat autisme terdekat dengan lokasi anda"
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
        <div className="section-header">
          <h2>Fitur Utama</h2>
          <p>Semua yang anda perlukan untuk menguruskan penjagaan anak autisme</p>
        </div>
        <div className="grid grid-3">
          {features.map((feature, idx) => (
            <div key={idx} className="feature-card">
              <div className="feature-icon">{feature.icon}</div>
              <h3>{feature.title}</h3>
              <p>{feature.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function About() {
  return (
    <section id="about" className="section">
      <div className="container">
        <div className="grid grid-2 about-grid">
          <div className="about-text">
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
            <div className="stats">
              <div className="stat">
                <span className="stat-number">100+</span>
                <span className="stat-label">Pusat Terdaftar</span>
              </div>
              <div className="stat">
                <span className="stat-number">500+</span>
                <span className="stat-label">Keluarga Dibantu</span>
              </div>
            </div>
          </div>
          <div className="about-image">
            <div className="about-visual">
              <div className="visual-box">
                <span>UiTM</span>
                <small>Final Year Project 2025</small>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

function Contact() {
  return (
    <section id="contact" className="section section-alt">
      <div className="container">
        <div className="section-header">
          <h2>Hubungi Kami</h2>
          <p>Ada soalan? Kami di sini untuk membantu</p>
        </div>
        <div className="contact-content">
          <form className="contact-form">
            <input type="text" placeholder="Nama" />
            <input type="email" placeholder="Emel" />
            <textarea placeholder="Mesej" rows="4"></textarea>
            <button type="submit" className="btn btn-primary">Hantar</button>
          </form>
          <div className="contact-info">
            <div className="info-item">
              <h4>Emel</h4>
              <p>support@auticare.my</p>
            </div>
            <div className="info-item">
              <h4>Lokasi</h4>
              <p>Universiti Teknologi MARA, Malaysia</p>
            </div>
          </div>
        </div>
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
          <p className="footer-text">
            &copy; 2025 AutiCare. Projek Tahun Akhir UiTM.
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
        <Header />
        <main>
          <Hero />
          <Features />
          <About />
          <Contact />
        </main>
        <Footer />
      </div>
    </Router>
  )
}

export default App
