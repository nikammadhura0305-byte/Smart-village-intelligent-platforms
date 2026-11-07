const STORAGE_KEYS = {
  dashboard: 'officer_dashboard_cache',
  complaints: 'officer_complaints_cache',
  insights: 'officer_insights_cache',
  twin: 'officer_twin_cache',
  lastSync: 'officer_last_sync'
};

const cacheData = (key, payload) => {
  try {
    localStorage.setItem(key, JSON.stringify({ payload, savedAt: Date.now() }));
  } catch (error) {
    console.warn('Unable to persist cache', error);
  }
};

const readCache = (key) => {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return parsed && parsed.payload ? parsed.payload : null;
  } catch (error) {
    console.warn('Unable to restore cache', error);
    return null;
  }
};

const clearCache = () => {
  Object.values(STORAGE_KEYS).forEach((key) => localStorage.removeItem(key));
};

const markSync = () => {
  localStorage.setItem(STORAGE_KEYS.lastSync, new Date().toISOString());
};

const getLastSync = () => {
  return localStorage.getItem(STORAGE_KEYS.lastSync) || 'Not synced yet';
};

window.OfficerStorage = {
  STORAGE_KEYS,
  cacheData,
  readCache,
  clearCache,
  markSync,
  getLastSync
};
