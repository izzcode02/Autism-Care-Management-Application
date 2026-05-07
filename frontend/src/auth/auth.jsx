import { useState } from 'react';
import './auth.css';

const Auth = () => {
  const [showRegisterModal, setShowRegisterModal] = useState(false);

  return (
    <div className="auth-container">
      <div className="auth-left">
        <div className="auth-image-wrapper">
          <div className="auth-image-overlay"></div>
          <img
            src="https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?q=80&w=2000&auto=format&fit=crop"
            alt="Mother and child"
            className="auth-image"
          />
          <div className="auth-quote">
            <p className="quote-text">"Every child deserves understanding, patience, and love."</p>
            <p className="quote-author">— Together, we make a difference</p>
          </div>
        </div>
      </div>

      <div className="auth-right">
        <div className="auth-content">
          <div className="auth-header">
            <div className="logo">
              <img src='./public/logo.png' width={62} height={62}></img>
              <h1>Autism Care</h1>
            </div>
            <p className="auth-subtitle">Management Portal</p>
          </div>

          <div className="auth-form">
            <div className="form-group">
              <label htmlFor="email">Email</label>
              <input
                type="email"
                id="email"
                placeholder="Enter your email"
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password</label>
              <input
                type="password"
                id="password"
                placeholder="Enter your password"
                className="form-input"
              />
            </div>

            <div className="form-actions">
              <button className="btn btn-primary">Login</button>
              <button
                className="btn btn-secondary"
                onClick={() => setShowRegisterModal(true)}
              >
                Register
              </button>
            </div>

            <div className="divider">
              <span>or continue with</span>
            </div>

            <button className="btn btn-sso">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Sign in with Google
            </button>
          </div>
        </div>
      </div>

      {showRegisterModal && (
        <div className="modal-overlay" onClick={() => setShowRegisterModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Create Account</h2>
              <button
                className="modal-close"
                onClick={() => setShowRegisterModal(false)}
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <line x1="18" y1="6" x2="6" y2="18"/>
                  <line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
              </button>
            </div>

            <div className="modal-body">
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="firstName">First Name</label>
                  <input
                    type="text"
                    id="firstName"
                    placeholder="Enter first name"
                    className="form-input"
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="lastName">Last Name</label>
                  <input
                    type="text"
                    id="lastName"
                    placeholder="Enter last name"
                    className="form-input"
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="regEmail">Email</label>
                <input
                  type="email"
                  id="regEmail"
                  placeholder="Enter your email"
                  className="form-input"
                />
              </div>

              <div className="form-group">
                <label htmlFor="regPassword">Password</label>
                <input
                  type="password"
                  id="regPassword"
                  placeholder="Create a password"
                  className="form-input"
                />
              </div>

              <button className="btn btn-primary btn-full">Register</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Auth;