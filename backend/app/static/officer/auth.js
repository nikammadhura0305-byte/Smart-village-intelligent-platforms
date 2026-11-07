const OfficerAuth = {
  getToken() {
    return localStorage.getItem('officer_token');
  },
  setToken(token) {
    if (!token) {
      localStorage.removeItem('officer_token');
      return;
    }
    localStorage.setItem('officer_token', token);
  },
  logout() {
    this.setToken(null);
    if (window.location.pathname.includes('/dashboard')) {
      const loginView = document.getElementById('login-view');
      const appView = document.getElementById('app-view');
      if (loginView && appView) {
        loginView.classList.remove('hidden');
        appView.classList.add('hidden');
      }
    }
  }
};

window.OfficerAuth = OfficerAuth;
