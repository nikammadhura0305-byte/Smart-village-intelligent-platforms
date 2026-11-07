
let currentLanguage = localStorage.getItem('officer_language') || 'en';

const state = {
  token: localStorage.getItem('officer_token') || '',
  selectedComplaintId: null,
  selectedComplaint: null,
  selectedMapComplaintId: null,
  returnToComplaintId: null,
  returnFromPage: 'complaints',
  selectedDistrict: localStorage.getItem('officer_district') || '',
  selectedTaluka: localStorage.getItem('officer_taluka') || '',
  selectedVillageId: localStorage.getItem('officer_village_id') || '',
  villages: [],
  villagesLoaded: false,
  complaints: [],
  complaintPage: 1,
  complaintPageSize: 10,
  complaintSort: 'created_desc',
  isSubmittingDecision: false,
  officers: [],
  lastDashboard: null,
  lastInsights: null,
  lastTwin: null,
  lastPredictions: null
};

const chartInstances = {
  category: null,
  status: null,
  trend: null,
  bubble: null,
  resolutionHistogram: null,
  deptWorkload: null,
  heatmap: null,
  heatLayer: null
};

const analyticsState = {
  startDate: '',
  endDate: '',
  category: '',
  status: '',
  department: '',
  area: '',
  interval: 'day',
  bubbleMode: 'category',
  data: null
};

const PAGE_CONFIG = {
  overview: { breadcrumb: 'navOverview', title: 'villageOverview' },
  complaints: { breadcrumb: 'navComplaints', title: 'complaintManagement' },
  analytics: { breadcrumb: 'navAnalytics', title: 'villageAnalyticsTitle' },
  map: { breadcrumb: 'navMap', title: 'digitalTwinTitle' },
  reports: { breadcrumb: 'navReports', title: 'reportsPageTitle' },
  settings: { breadcrumb: 'navSettings', title: 'accountTitle' }
};

let activePage = 'overview';
let dashboardLoadInProgress = false;
let dashboardLoadVersion = 0;
let lastDashboardRefreshAt = 0;

function navigateToPage(pageKey, updateHash = true) {
  if (!PAGE_CONFIG[pageKey]) pageKey = 'overview';
  activePage = pageKey;

  // 1. Show only the active page container
  document.querySelectorAll('.dashboard-page').forEach((el) => {
    el.classList.toggle('active', el.id === `page-${pageKey}`);
  });

  if (pageKey !== 'map') {
    const returnBar = $('map-return-bar');
    if (returnBar) returnBar.classList.add('hidden');
  }

  // 2. Highlight active sidebar link
  document.querySelectorAll('.sidebar nav .nav-link').forEach((link) => {
    link.classList.toggle('active', link.dataset.page === pageKey);
  });

  // 3. Update breadcrumb and page title
  const cfg = PAGE_CONFIG[pageKey];
  const breadcrumbEl = $('breadcrumb-current');
  if (breadcrumbEl) {
    breadcrumbEl.textContent = t(cfg.breadcrumb, pageKey);
  }
  const topbarTitleEl = $('topbar-page-title');
  if (topbarTitleEl) {
    topbarTitleEl.textContent = t(cfg.title, pageKey);
  }

  // 4. Update window hash if requested
  if (updateHash && window.location.hash !== `#${pageKey}`) {
    history.pushState(null, '', `#${pageKey}`);
  }

  // 5. Invalidate canvas & map geometries when pages become visible
  if (pageKey === 'analytics') {
    Object.values(chartInstances).forEach((inst) => {
      if (inst && typeof inst.resize === 'function') {
        try { inst.resize(); } catch (_) {}
      }
    });
    if (chartInstances.heatmap && typeof chartInstances.heatmap.invalidateSize === 'function') {
      setTimeout(() => chartInstances.heatmap.invalidateSize(), 150);
    }
  } else if (pageKey === 'map') {
    if (state.lastTwin) {
      renderTwin(state.lastTwin);
    } else if (window.complaintLeafletMap && typeof window.complaintLeafletMap.invalidateSize === 'function') {
      setTimeout(() => window.complaintLeafletMap.invalidateSize(), 150);
    }
  }

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

const $ = (id) => document.getElementById(id);

const escapeHtml = (value) =>
  String(value ?? '').replace(/[&<>'"]/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;'
  }[char]));

// Multilingual i18n lookup helper
function t(key, fallback = '') {
  return window.I18N?.[currentLanguage]?.[key] ??
    window.I18N?.['en']?.[key] ??
    fallback ??
    key;
}

const categoryKeys = {
  "Water": "catWater",
  "Water Supply": "catWater",
  "Roads": "catRoads",
  "Roads & Pathways": "catRoads",
  "Electricity": "catElectricity",
  "Medical": "catMedical",
  "Healthcare & Dispensary": "catMedical",
  "Sanitation": "catSanitation",
  "Sanitation & Waste": "catSanitation",
  "Agriculture": "catAgriculture",
  "Agriculture & Irrigation": "catAgriculture",
  "Education": "catEducation",
  "Education & Schools": "catEducation",
  "Drainage": "catDrainage",
  "Drainage & Gutters": "catDrainage",
  "Street Light": "catStreetLight",
  "Street Lights": "catStreetLight",
  "Internet": "catInternet",
  "Internet & Network": "catInternet",
  "Government Documents": "catGovDocs",
  "Documents": "catGovDocs"
};

function translateCategory(cat) {
  if (!cat) return t('unassigned', 'Pending AI');
  const key = categoryKeys[cat];
  return key ? t(key, cat) : cat;
}

function translateSeverity(sev) {
  if (!sev) return '—';
  const map = { 'Low': 'sevLow', 'Medium': 'sevMedium', 'High': 'sevHigh', 'Critical': 'sevCritical' };
  return map[sev] ? t(map[sev], sev) : sev;
}

function translateStatus(st) {
  if (!st) return '—';
  const map = {
    'Pending': 'statusPending',
    'Assigned': 'statusAssigned',
    'In Progress': 'statusInProgress',
    'Resolved': 'statusResolved',
    'Closed': 'statusClosed',
    'Reopened': 'statusReopened',
    'Escalated': 'statusEscalated',
    'Rejected': 'statusRejected'
  };
  return map[st] ? t(map[st], st) : st;
}

function applyTranslations(lang) {
  currentLanguage = lang;
  localStorage.setItem('officer_language', lang);

  // Sync all dropdowns
  ['login-lang-select', 'topbar-lang-select', 'settings-lang-select'].forEach((id) => {
    const el = $(id);
    if (el) el.value = lang;
  });

  // Update data-i18n elements
  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    if (key) {
      const translated = t(key);
      if (translated) el.textContent = translated;
    }
  });

  // Update data-i18n-placeholder elements
  document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
    const key = el.getAttribute('data-i18n-placeholder');
    if (key) {
      const translated = t(key);
      if (translated) el.setAttribute('placeholder', translated);
    }
  });
  renderVillageSelectors();

  // Re-render currently displayed dynamic data if present
  if (state.lastDashboard) renderDashboard(state.lastDashboard);
  if (state.complaints.length) renderComplaints(state.complaints);
  if (state.lastInsights) renderInsights(state.lastInsights);
  if (analyticsState.data) renderAdvancedAnalytics(analyticsState.data);
  if (state.lastTwin) renderTwin(state.lastTwin);
  if (state.lastPredictions) renderPredictions(state.lastPredictions);

  // Update multipage breadcrumb & page title in new language
  const cfg = PAGE_CONFIG[activePage] || PAGE_CONFIG.overview;
  if ($('breadcrumb-current')) $('breadcrumb-current').textContent = t(cfg.breadcrumb, activePage);
  if ($('topbar-page-title')) $('topbar-page-title').textContent = t(cfg.title, activePage);
}

function setLanguage(lang) {
  applyTranslations(lang);
}

function apiErrorMessage(detail, fallback) {
  if (typeof detail === 'string' && detail) return detail;

  if (Array.isArray(detail)) {
    return detail
      .map((item) => typeof item === 'string' ? item : item?.msg || item?.message)
      .filter(Boolean)
      .join('; ') || fallback;
  }

  if (detail && typeof detail === 'object') {
    return detail.message || detail.msg || fallback;
  }

  return fallback;
}

async function api(path, options = {}) {
  const token = state.token || localStorage.getItem('officer_token');
  const response = await fetch(path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
      Authorization: `Bearer ${token}`
    }
  });

  const body = await response.json().catch(() => ({}));

  if (response.status === 401) logout();

  if (!response.ok) {
    throw new Error(
      apiErrorMessage(body.detail, `Request failed (${response.status})`)
    );
  }

  return body;
}

async function loadRegistrationDistricts() {
  const districtSelect = $('register-officer-district');
  const response = await fetch('/auth/districts');
  const districts = await response.json();
  if (!response.ok) {
    throw new Error(apiErrorMessage(districts.detail, 'Could not load districts'));
  }
  districtSelect.innerHTML = '<option value="">Select district</option>' +
    districts.map((district) =>
      `<option value="${escapeHtml(district)}">${escapeHtml(district)}</option>`
    ).join('');
}

async function loadRegistrationTalukas(district) {
  const talukaSelect = $('register-officer-taluka');
  const villageSelect = $('register-officer-village');
  if (!talukaSelect) return;
  talukaSelect.disabled = true;
  talukaSelect.innerHTML = '<option value="">Loading talukas...</option>';
  if (villageSelect) {
    villageSelect.disabled = true;
    villageSelect.innerHTML = '<option value="">Select a taluka first</option>';
  }

  const response = await fetch(`/auth/talukas?${new URLSearchParams({ district })}`);
  const talukas = await response.json();
  if (!response.ok) {
    throw new Error(apiErrorMessage(talukas.detail, 'Could not load talukas'));
  }
  talukaSelect.innerHTML = '<option value="">Select taluka</option>' +
    talukas.map((taluka) =>
      `<option value="${escapeHtml(taluka)}">${escapeHtml(taluka)}</option>`
    ).join('');
  talukaSelect.disabled = false;
}

async function loadRegistrationVillages(district, taluka) {
  const villageSelect = $('register-officer-village');
  if (!villageSelect) return;
  villageSelect.disabled = true;
  villageSelect.innerHTML = '<option value="">Loading villages...</option>';
  const params = { district };
  if (taluka) params.taluka = taluka;
  const response = await fetch(`/auth/villages?${new URLSearchParams(params)}`);
  const villages = await response.json();
  if (!response.ok) {
    throw new Error(apiErrorMessage(villages.detail, 'Could not load villages'));
  }
  villageSelect.innerHTML = '<option value="">Select village</option>' +
    villages.map((village) =>
      `<option value="${village.id}">${escapeHtml(village.name)}</option>`
    ).join('');
  villageSelect.disabled = villages.length === 0;
  if (villages.length === 0) {
    villageSelect.innerHTML = '<option value="">No villages found in this taluka</option>';
  }
}

async function loadPendingOfficers() {
  const panel = $('pending-officers-panel');
  const list = $('pending-officers-list');
  const user = JSON.parse(localStorage.getItem('officer_user') || 'null');
  if (!panel || user?.role !== 'admin') return;

  panel.classList.remove('hidden');
  list.textContent = 'Loading registration requests...';
  try {
    const pending = await api('/auth/pending-officers');
    list.innerHTML = pending.length
      ? `<div class="table-wrap"><table><thead><tr><th>Name</th><th>Email</th><th>District</th><th>Village</th><th>Action</th></tr></thead><tbody>${pending.map((officer) => `
        <tr>
          <td>${escapeHtml(officer.full_name)}</td>
          <td>${escapeHtml(officer.email)}</td>
          <td>${escapeHtml(officer.district)}</td>
          <td>${escapeHtml(officer.village)}</td>
          <td><button class="primary-button approve-officer-button" data-officer-id="${officer.id}" type="button">Approve</button></td>
        </tr>`).join('')}</tbody></table></div>`
      : '<p class="muted">No officer registrations are waiting for approval.</p>';
  } catch (error) {
    list.innerHTML = `<p class="error">Could not load officer requests: ${escapeHtml(error.message)}</p>`;
  }
}

function addVillageScope(params) {
  if (state.selectedVillageId) {
    params.set('village_id', state.selectedVillageId);
    if (state.selectedDistrict) params.set('district', state.selectedDistrict);
    if (state.selectedTaluka) params.set('taluka', state.selectedTaluka);
  } else if (state.selectedTaluka) {
    if (state.selectedDistrict) params.set('district', state.selectedDistrict);
    params.set('taluka', state.selectedTaluka);
  } else if (state.selectedDistrict) {
    params.set('district', state.selectedDistrict);
  } else {
    params.set('all_villages', 'true');
  }
  return params;
}

function scopedPath(path) {
  const url = new URL(path, window.location.href);
  addVillageScope(url.searchParams);
  return `${url.pathname}${url.search}`;
}

function renderVillageSelectors() {
  const districtSelect = $('district-select');
  const talukaSelect = $('taluka-select');
  const villageSelect = $('village-select');
  if (!districtSelect || !talukaSelect || !villageSelect) return;

  const currentUser = JSON.parse(localStorage.getItem('officer_user') || 'null');
  const isRegularOfficer = currentUser && currentUser.role === 'village_officer' && currentUser.village_id;

  if (isRegularOfficer) {
    const assignedVillage = state.villages.find((v) => v.id === currentUser.village_id);
    if (assignedVillage) {
      state.selectedDistrict = assignedVillage.district;
      state.selectedTaluka = assignedVillage.taluka || '';
      state.selectedVillageId = String(assignedVillage.id);

      districtSelect.innerHTML = `<option value="${escapeHtml(assignedVillage.district)}">${escapeHtml(assignedVillage.district)}</option>`;
      districtSelect.disabled = true;

      talukaSelect.innerHTML = `<option value="${escapeHtml(assignedVillage.taluka || '')}">${escapeHtml(assignedVillage.taluka || t('scopeNotRecorded', 'Taluka not recorded'))}</option>`;
      talukaSelect.disabled = true;

      villageSelect.innerHTML = `<option value="${assignedVillage.id}">${escapeHtml(assignedVillage.name)} — ${escapeHtml(assignedVillage.taluka || '-')}, ${escapeHtml(assignedVillage.district)}</option>`;
      villageSelect.disabled = true;

      localStorage.setItem('officer_district', state.selectedDistrict);
      localStorage.setItem('officer_taluka', state.selectedTaluka);
      localStorage.setItem('officer_village_id', state.selectedVillageId);
      return;
    }
  }

  districtSelect.disabled = false;
  const districts = [...new Set(state.villages.map((village) => village.district))].sort();
  districtSelect.innerHTML = `<option value="">${escapeHtml(t('scopeAllDistricts', 'All districts'))}</option>` +
    districts.map((district) =>
      `<option value="${escapeHtml(district)}">${escapeHtml(district)}</option>`
    ).join('');

  if (!districts.includes(state.selectedDistrict)) {
    state.selectedDistrict = '';
  }
  districtSelect.value = state.selectedDistrict;

  const districtVillages = state.villages.filter(
    (village) => !state.selectedDistrict || village.district === state.selectedDistrict
  );
  const talukas = [...new Set(
    districtVillages.map((village) => village.taluka).filter(Boolean)
  )].sort();
  if (!talukas.includes(state.selectedTaluka)) state.selectedTaluka = '';
  talukaSelect.innerHTML = `<option value="">${escapeHtml(t('scopeAllTalukas', 'All talukas'))}</option>` +
    talukas.map((taluka) =>
      `<option value="${escapeHtml(taluka)}">${escapeHtml(taluka)}</option>`
    ).join('');
  talukaSelect.value = state.selectedTaluka;
  talukaSelect.disabled = talukas.length === 0;

  const matchingVillages = state.villages.filter(
    (village) =>
      (!state.selectedDistrict || village.district === state.selectedDistrict) &&
      (!state.selectedTaluka || village.taluka === state.selectedTaluka)
  );
  villageSelect.innerHTML = `<option value="">${escapeHtml(t('scopeAllVillages', 'All villages'))}</option>` +
    matchingVillages.map((village) =>
      `<option value="${village.id}">${escapeHtml(village.name)} — ${escapeHtml(village.taluka || t('scopeNotRecorded', 'Taluka not recorded'))}, ${escapeHtml(village.district)}</option>`
    ).join('');

  if (!matchingVillages.some((village) => String(village.id) === state.selectedVillageId)) {
    state.selectedVillageId = '';
  }
  villageSelect.value = state.selectedVillageId;
  villageSelect.disabled = false;
  localStorage.setItem('officer_district', state.selectedDistrict);
  localStorage.setItem('officer_taluka', state.selectedTaluka);
  localStorage.setItem('officer_village_id', state.selectedVillageId);
}

async function loadVillageOptions() {
  if (!state.villagesLoaded) {
    state.villages = await api('/officer/villages');
    state.villagesLoaded = true;
    const currentUser = JSON.parse(localStorage.getItem('officer_user') || 'null');
    const assignedVillage = state.villages.find(
      (village) => village.id === currentUser?.village_id
    );
    if (assignedVillage) {
      state.selectedVillageId = String(assignedVillage.id);
      state.selectedDistrict = assignedVillage.district;
      state.selectedTaluka = assignedVillage.taluka || '';
    }
  }
  renderVillageSelectors();
}

function loginView(showApp) {
  $('login-view').classList.toggle('hidden', showApp);
  $('app-view').classList.toggle('hidden', !showApp);
}

function logout() {
  state.token = null;
  localStorage.removeItem('officer_token');
  loginView(false);
}

function badge(value, type = 'status') {
  if (!value) return '<span class="badge">—</span>';
  let label = value;
  if (type === 'severity' || ['Low', 'Medium', 'High', 'Critical'].includes(value)) {
    label = translateSeverity(value);
  } else if (type === 'status' || ['Pending', 'Assigned', 'In Progress', 'Resolved', 'Closed', 'Reopened', 'Escalated'].includes(value)) {
    label = translateStatus(value);
  }
  return `<span class="badge ${escapeHtml(value)}">${escapeHtml(label)}</span>`;
}

function renderBars(target, values) {
  const el = $(target);
  if (!el) return;
  const entries = Object.entries(values || {});

  if (!entries.length) {
    el.innerHTML = `<p class="muted">${escapeHtml(t('noRecords', 'No records yet.'))}</p>`;
    return;
  }

  const max = Math.max(...entries.map(([, value]) => value), 1);

  el.innerHTML = entries.map(([label, value]) => `
    <div class="bar-row">
      <span>${escapeHtml(translateCategory(label))}</span>
      <div class="bar-track">
        <div class="bar-fill" style="width:${Math.max(3, value / max * 100)}%"></div>
      </div>
      <strong>${value}</strong>
    </div>
  `).join('');
}

function renderDashboard(data) {
  state.lastDashboard = data;
  const metrics = [
    [t('totalComplaints', 'Total complaints'), data.total_complaints ?? 0, ''],
    [t('pendingComplaints', 'Pending'), data.pending_complaints ?? 0, ''],
    [t('inProgressComplaints', 'In progress'), data.in_progress_complaints ?? 0, ''],
    [t('resolvedComplaints', 'Resolved'), data.resolved_complaints ?? 0, ''],
    [t('overdueComplaints', 'Overdue'), data.overdue_complaints ?? 0, 'high'],
    [t('criticalComplaints', 'Critical'), data.critical_complaints ?? 0, 'critical'],
    [t('highPriorityComplaints', 'High priority'), data.high_priority_complaints ?? 0, 'high']
  ];

  $('metric-grid').innerHTML = metrics.map(([label, value, tone]) => `
    <article class="metric ${tone}">
      <div class="metric-label">${label}</div>
      <div class="metric-value">${value}</div>
    </article>
  `).join('');

  renderBars('overview-category-chart', data.complaints_by_category);
}

function showAlert(type, msg) {
  const el = $('complaint-alert');
  if (!el) return;
  el.className = `alert-banner ${type}`;
  el.innerHTML = `<span>${escapeHtml(msg)}</span><button type="button" class="icon-button" style="font-size:16px; margin-left:12px; background:none; border:none; cursor:pointer;" aria-label="Dismiss alert">×</button>`;
  el.classList.remove('hidden');
  const closeBtn = el.querySelector('button');
  if (closeBtn) closeBtn.addEventListener('click', () => el.classList.add('hidden'));
  setTimeout(() => { if (el) el.classList.add('hidden'); }, 6000);
}

function setBtnLoading(btn, loading, text) {
  if (!btn) return;
  btn.disabled = loading;
  btn.dataset.loading = loading ? 'true' : 'false';
  if (loading && text) {
    btn.dataset.origText = btn.textContent;
    btn.textContent = text;
  } else if (!loading && btn.dataset.origText) {
    btn.textContent = btn.dataset.origText;
  }
}

function renderComplaints(items) {
  state.complaints = Array.isArray(items) ? items : [];

  // Populate dynamic category dropdown
  const catSelect = $('category-filter');
  if (catSelect) {
    const cats = [...new Set(state.complaints.map((c) => c.category).filter(Boolean))].sort();
    const curVal = catSelect.value;
    catSelect.innerHTML = `<option value="">${escapeHtml(t('allCategories', 'All categories'))}</option>` +
      cats.map((c) => `<option value="${escapeHtml(c)}" ${c === curVal ? 'selected' : ''}>${escapeHtml(translateCategory(c))}</option>`).join('');
  }

  // Populate dynamic department dropdown
  const deptSelect = $('department-filter');
  if (deptSelect) {
    const depts = [...new Set(state.complaints.map((c) => c.assigned_department).filter(Boolean))].sort();
    const curVal = deptSelect.value;
    deptSelect.innerHTML = `<option value="">${escapeHtml(t('allDepartments', 'All departments'))}</option>` +
      depts.map((d) => `<option value="${escapeHtml(d)}" ${d === curVal ? 'selected' : ''}>${escapeHtml(d)}</option>`).join('');
  }

  updateComplaintTable();
}

function updateComplaintTable() {
  const items = [...state.complaints];
  const sortKey = state.complaintSort || 'created_desc';

  items.sort((a, b) => {
    if (sortKey === 'created_desc') return new Date(b.created_at || 0) - new Date(a.created_at || 0);
    if (sortKey === 'created_asc') return new Date(a.created_at || 0) - new Date(b.created_at || 0);
    if (sortKey === 'priority_desc') return (b.priority_score ?? 0) - (a.priority_score ?? 0);
    if (sortKey === 'priority_asc') return (a.priority_score ?? 0) - (b.priority_score ?? 0);
    if (sortKey === 'id_desc') return b.id - a.id;
    if (sortKey === 'id_asc') return a.id - b.id;
    return 0;
  });

  const total = items.length;
  const pageSize = Number(state.complaintPageSize) || 10;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  if (state.complaintPage > totalPages) state.complaintPage = totalPages;
  if (state.complaintPage < 1) state.complaintPage = 1;

  const start = (state.complaintPage - 1) * pageSize;
  const pageItems = items.slice(start, start + pageSize);

  $('empty-state')?.classList.toggle('hidden', total > 0);

  const tbody = $('complaint-table');
  if (tbody) {
    tbody.innerHTML = pageItems.map((item) => {
      const createdStr = item.created_at ? new Date(item.created_at).toISOString().replace('T', ' ').slice(0, 16) : '—';
      return `
        <tr>
          <td>
            <div class="complaint-title-row">
              <strong>#${item.id} ${escapeHtml(item.title || item.text || 'Complaint')}</strong>
              ${item.is_overdue ? `<span class="badge High">${escapeHtml(t('overdueComplaints', 'Overdue'))}</span>` : ''}
            </div>
            <small class="muted">${escapeHtml(item.location || item.text || t('notProvided', 'Location not provided'))}</small>
          </td>
          <td>
            <strong>${escapeHtml(item.village || '—')}</strong>
            ${item.taluka || item.district ? `<br><small class="muted">${escapeHtml([item.taluka, item.district].filter(Boolean).join(', '))}</small>` : ''}
          </td>
          <td>${escapeHtml(translateCategory(item.category))}</td>
          <td>${item.severity ? badge(item.severity, 'severity') : '—'}</td>
          <td>${item.priority_level ? badge(item.priority_level, 'priority') : '—'} ${item.priority_score ?? ''}</td>
          <td>${badge(item.status, 'status')}</td>
          <td>${escapeHtml(item.assigned_department || t('unassigned', 'Unassigned'))}</td>
          <td><small class="muted">${escapeHtml(createdStr)}</small></td>
          <td>
            <div class="complaint-actions">
              <button class="open-button" data-open-complaint-id="${item.id}">${escapeHtml(t('openCase', 'Open'))}</button>
              <button class="open-button" data-map-complaint-id="${item.id}">${escapeHtml(t('showOnMap', 'Map'))}</button>
            </div>
          </td>
        </tr>
      `;
    }).join('');

    tbody.querySelectorAll('[data-open-complaint-id]').forEach((button) => {
      button.addEventListener('click', () => openDetail(button.dataset.openComplaintId));
    });
    tbody.querySelectorAll('[data-map-complaint-id]').forEach((button) => {
      button.addEventListener('click', () => showComplaintOnMap(button.dataset.mapComplaintId));
    });
  }

  // Update pagination bar
  const infoEl = $('pagination-info');
  if (infoEl) {
    if (total === 0) {
      infoEl.textContent = 'Showing 0 complaints';
    } else {
      infoEl.textContent = `Showing ${start + 1}–${Math.min(start + pageSize, total)} of ${total} complaints`;
    }
  }

  const pageInd = $('page-indicator');
  if (pageInd) {
    pageInd.textContent = `Page ${state.complaintPage} of ${totalPages}`;
  }

  const prevBtn = $('prev-page-btn');
  if (prevBtn) prevBtn.disabled = state.complaintPage <= 1;

  const nextBtn = $('next-page-btn');
  if (nextBtn) nextBtn.disabled = state.complaintPage >= totalPages;
}

function renderTimeline(target, entries) {
  const node = $(target);
  if (!node) return;

  const timeline = Array.isArray(entries) ? entries : [];
  if (!timeline.length) {
    node.innerHTML = `<p class="muted">${escapeHtml(t('noRecords', 'No complaint history yet.'))}</p>`;
    return;
  }

  const max = Math.max(...timeline.map((entry) => Number(entry.count) || 0), 1);
  node.innerHTML = timeline.map((entry) => `
    <div class="bar-row">
      <span>${escapeHtml(entry.date || 'Unknown')}</span>
      <div class="bar-track">
        <div class="bar-fill" style="width:${Math.max(3, ((Number(entry.count) || 0) / max) * 100)}%"></div>
      </div>
      <strong>${Number(entry.count) || 0}</strong>
    </div>
  `).join('');
}

function renderAssignments(items) {
  const assignmentSummary = $('assignment-summary');
  const assignmentDepartments = $('assignment-departments');

  if (!assignmentSummary || !assignmentDepartments) return;

  const assigned = items.filter((item) => item.assigned_department);
  const byDepartment = assigned.reduce((acc, item) => {
    const key = item.assigned_department || t('unassigned', 'Unassigned');
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});

  assignmentSummary.innerHTML = assigned.length
    ? Object.entries(byDepartment).map(([department, count]) => `
        <div class="focus-item">
          <span>${escapeHtml(department)}</span>
          <strong>${count}</strong>
        </div>
      `).join('')
    : `<p class="muted">${escapeHtml(t('noActiveAssignments', 'No active department assignments yet.'))}</p>`;

  assignmentDepartments.innerHTML = Object.entries(byDepartment).length
    ? Object.entries(byDepartment).map(([department, count]) => `
        <div class="resource">
          <strong>${escapeHtml(department)}</strong>
          <small>${count} active cases</small>
        </div>
      `).join('')
    : `<p class="muted">${escapeHtml(t('assignmentHint', 'Department assignment data will appear here.'))}</p>`;
}

function renderInsights(data) {
  state.lastInsights = data;
  renderBars('status-chart', data.status_counts);
  renderBars('category-chart', data.category_counts);
  renderBars('priority-chart', data.priority_counts);
  renderBars('severity-chart', data.severity_counts);
  renderBars('department-chart', data.department_workload);
  renderTimeline('timeline-chart', data.complaints_over_time);

  const rateData = data.resolution_rate || {};
  const rate = Number(rateData.rate ?? 0);
  const resolutionNode = $('resolution-rate');
  if (resolutionNode) {
    resolutionNode.innerHTML = `
      <div class="summary-box-item">
        <span class="muted">${escapeHtml(t('resolutionRate', 'Resolution rate'))}</span>
        <strong>${rate.toFixed(1)}%</strong>
      </div>
      <div class="summary-box-item">
        <span class="muted">Formula</span>
        <strong>resolved / total complaints * 100</strong>
      </div>
      <div class="summary-box-item">
        <span class="muted">${escapeHtml(t('resolvedComplaints', 'Resolved'))}</span>
        <strong>${Number(rateData.resolved ?? 0)} / ${Number(rateData.total ?? 0)}</strong>
      </div>
    `;
  }

  const overdue = Array.isArray(data.overdue_complaints) ? data.overdue_complaints : [];
  const overdueNode = $('overdue-list');
  if (overdueNode) {
    overdueNode.innerHTML = overdue.length
      ? overdue.map((item) => `
          <div class="focus-item">
            <span>#${item.complaint_id} ${escapeHtml(String(item.title || 'Complaint'))}</span>
            <span class="badge High">${Number(item.days_overdue || 0)}d</span>
            <strong>${escapeHtml(String(item.status || 'Overdue'))}</strong>
          </div>
        `).join('')
      : `<p class="muted">${escapeHtml(t('noOverdue', 'No overdue complaints currently.'))}</p>`;
  }

  const aiInsights = Array.isArray(data.ai_insights) ? data.ai_insights : [];
  const aiNode = $('ai-insights');
  if (aiNode) {
    aiNode.innerHTML = aiInsights.length
      ? aiInsights.map((item) => `
          <div class="focus-item">
            <span>Complaint #${item.complaint_id}</span>
            <span>${escapeHtml(translateCategory(String(item.category || 'Unclassified')))}</span>
            <strong>${escapeHtml(translateSeverity(String(item.priority_level || 'Unassigned')))}</strong>
            <small class="muted">${item.confidence != null ? `${Number(item.confidence).toFixed(1)}% confidence` : 'Confidence unavailable'}</small>
          </div>
        `).join('')
      : '<p class="muted">AI classification data is not available yet.</p>';
  }

  const focus = Object.entries(data.priority_counts || {})
    .filter(([key]) => key === 'Critical' || key === 'High');

  const focusList = $('focus-list');
  if (focusList) {
    focusList.innerHTML = focus.length
      ? focus.map(([label, value]) => `
          <div class="focus-item">
            <span>${escapeHtml(translateSeverity(label))} cases</span>
            ${badge(label, 'severity')}
            <strong>${value}</strong>
          </div>
        `).join('')
      : `<p class="muted">${escapeHtml(t('noFocusCases', 'No urgent priority cases.'))}</p>`;
  }
}

function renderCategoryBarChart(dist) {
  const canvas = $('chart-category');
  if (!canvas || typeof Chart === 'undefined') return;

  if (chartInstances.category) {
    chartInstances.category.destroy();
    chartInstances.category = null;
  }

  const entries = Object.entries(dist || {});
  const labels = entries.map(([cat]) => translateCategory(cat));
  const counts = entries.map(([, count]) => count);

  const colors = [
    '#0d9488', '#0284c7', '#f59e0b', '#8b5cf6',
    '#10b981', '#ec4899', '#6366f1', '#14b8a6', '#f97316'
  ];

  chartInstances.category = new Chart(canvas, {
    type: 'bar',
    data: {
      labels: labels.length ? labels : [t('noData', 'No data')],
      datasets: [{
        label: t('complaints', 'Complaints'),
        data: counts.length ? counts : [0],
        backgroundColor: labels.length ? labels.map((_, i) => colors[i % colors.length]) : ['#cbd5e1'],
        borderRadius: 4,
        maxBarThickness: 42
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => ` ${ctx.raw} ${t('complaints', 'Complaints')}`
          }
        }
      },
      scales: {
        y: {
          title: {
            display: true,
            text: t('axisComplaintCount', 'Number of complaints'),
            font: { size: 11, weight: '600' }
          },
          beginAtZero: true,
          ticks: { precision: 0, font: { size: 11 } },
          grid: { color: 'rgba(0, 0, 0, 0.05)' }
        },
        x: {
          title: {
            display: true,
            text: t('axisComplaintCategory', 'Complaint category'),
            font: { size: 11, weight: '600' }
          },
          ticks: { font: { size: 11 }, maxRotation: 35, minRotation: 0 },
          grid: { display: false }
        }
      }
    }
  });
}

function renderStatusDonutChart(dist) {
  const canvas = $('chart-status');
  if (!canvas || typeof Chart === 'undefined') return;

  if (chartInstances.status) {
    chartInstances.status.destroy();
    chartInstances.status = null;
  }

  const entries = Object.entries(dist || {});
  const statusColorMap = {
    'Pending': '#f59e0b',
    'Assigned': '#0284c7',
    'In Progress': '#6366f1',
    'Resolved': '#10b981',
    'Closed': '#64748b',
    'Reopened': '#ec4899',
    'Escalated': '#ef4444',
    'Rejected': '#b7443f'
  };

  const labels = entries.map(([st]) => translateStatus(st));
  const counts = entries.map(([, count]) => count);
  const bgColors = entries.map(([st]) => statusColorMap[st] || '#94a3b8');

  chartInstances.status = new Chart(canvas, {
    type: 'doughnut',
    data: {
      labels: labels.length ? labels : [t('noData', 'No data')],
      datasets: [{
        data: counts.length ? counts : [0],
        backgroundColor: counts.length ? bgColors : ['#e2e8f0'],
        borderWidth: 2,
        borderColor: '#ffffff'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '62%',
      plugins: {
        legend: {
          position: 'right',
          labels: { boxWidth: 12, font: { size: 11 } }
        },
        tooltip: {
          callbacks: {
            label: (ctx) => {
              const total = ctx.dataset.data.reduce((a, b) => a + b, 0);
              const val = ctx.raw;
              const pct = total > 0 ? ((val / total) * 100).toFixed(1) : 0;
              return ` ${ctx.label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    }
  });
}

function renderTrendLineChart(timeline) {
  const canvas = $('chart-trend');
  if (!canvas || typeof Chart === 'undefined') return;

  if (chartInstances.trend) {
    chartInstances.trend.destroy();
    chartInstances.trend = null;
  }

  const points = Array.isArray(timeline) ? timeline : [];
  const labels = points.map(p => p.date || p.bucket);
  const counts = points.map(p => p.count);

  chartInstances.trend = new Chart(canvas, {
    type: 'line',
    data: {
      labels: labels.length ? labels : [t('noData', 'No data')],
      datasets: [{
        label: t('complaints', 'Complaints'),
        data: counts.length ? counts : [0],
        borderColor: '#0d9488',
        backgroundColor: 'rgba(13, 148, 136, 0.12)',
        fill: true,
        tension: 0.35,
        pointBackgroundColor: '#0d9488',
        pointBorderColor: '#ffffff',
        pointBorderWidth: 1.5,
        pointRadius: 4,
        pointHoverRadius: 6
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            title: (items) => `${items[0].label} (${analyticsState.interval})`,
            label: (ctx) => ` ${ctx.raw} ${t('complaints', 'Complaints')}`
          }
        }
      },
      scales: {
        y: {
          title: {
            display: true,
            text: t('axisComplaintCount', 'Number of complaints'),
            font: { size: 11, weight: '600' }
          },
          beginAtZero: true,
          ticks: { precision: 0, font: { size: 11 } },
          grid: { color: 'rgba(0, 0, 0, 0.05)' }
        },
        x: {
          title: {
            display: true,
            text: t('axisSubmissionPeriod', 'Submission period'),
            font: { size: 11, weight: '600' }
          },
          ticks: { font: { size: 11 }, maxRotation: 45, minRotation: 0 },
          grid: { display: false }
        }
      }
    }
  });
}

function renderBubbleChart(data) {
  const canvas = $('chart-bubble');
  if (!canvas || typeof Chart === 'undefined') return;

  if (chartInstances.bubble) {
    chartInstances.bubble.destroy();
    chartInstances.bubble = null;
  }

  const isCatMode = (analyticsState.bubbleMode !== 'area');
  const heading = $('bubble-chart-heading');
  const note = $('bubble-legend-note');

  if (heading) {
    heading.textContent = isCatMode
      ? t('bubbleCategories', 'Category Comparison (Bubble Chart)')
      : t('bubbleAreas', 'Village Area Comparison (Bubble Chart)');
  }
  if (note) {
    note.textContent = isCatMode
      ? t('bubbleCategoryExplanation', 'X: Total Complaints · Y: Unresolved · Size: Avg Severity')
      : t('bubbleExplanation', 'X: Volume · Y: Priority · Size: Impact');
  }

  let bubbleData = [];
  const palette = [
    'rgba(13, 148, 136, 0.75)',
    'rgba(2, 132, 199, 0.75)',
    'rgba(245, 158, 11, 0.75)',
    'rgba(139, 92, 246, 0.75)',
    'rgba(236, 72, 153, 0.75)',
    'rgba(16, 185, 129, 0.75)',
    'rgba(239, 68, 68, 0.75)',
    'rgba(100, 116, 139, 0.75)'
  ];

  if (isCatMode) {
    const items = Array.isArray(data?.category_bubble_metrics) ? data.category_bubble_metrics : [];
    bubbleData = items.map((m) => {
      const radius = Math.max(8, Math.min(28, Math.round((m.avg_severity_score || 1.5) * 6.5)));
      return {
        x: m.total_count,
        y: m.unresolved_count,
        r: radius,
        label: m.category,
        avg_sev: m.avg_severity_score,
        avg_pri: m.avg_priority_score,
        isCat: true
      };
    });
  } else {
    const items = Array.isArray(data?.area_bubble_metrics) ? data.area_bubble_metrics : [];
    bubbleData = items.map((m) => {
      const radius = Math.max(7, Math.min(26, ((m.total_affected_or_repeated || 1) * 3) + 4));
      return {
        x: m.complaint_count,
        y: Number(m.avg_priority_score.toFixed(1)),
        r: radius,
        label: m.area_name,
        impact: m.total_affected_or_repeated,
        dominant: m.dominant_category,
        isCat: false
      };
    });
  }

  chartInstances.bubble = new Chart(canvas, {
    type: 'bubble',
    data: {
      datasets: [{
        label: isCatMode ? 'Category Comparison' : 'Area Comparison',
        data: bubbleData,
        backgroundColor: bubbleData.map((_, i) => palette[i % palette.length]),
        borderColor: '#ffffff',
        borderWidth: 1.5,
        hoverBorderWidth: 2
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => {
              const d = ctx.raw;
              if (d.isCat) {
                return [
                  ` Category: ${translateCategory(d.label)}`,
                  ` Total Complaints (X): ${d.x}`,
                  ` Unresolved Complaints (Y): ${d.y}`,
                  ` Avg Severity (Bubble Size): ${d.avg_sev} / 4.0`,
                  ` Avg Priority Score: ${d.avg_pri} / 100`
                ];
              } else {
                return [
                  ` Ward / Area: ${d.label}`,
                  ` Complaint Volume (Count): ${d.x}`,
                  ` Avg Priority Score: ${d.y} / 100`,
                  ` Impact / Repeat Count: ${d.impact}`,
                  ` Dominant Problem: ${translateCategory(d.dominant)}`
                ];
              }
            }
          }
        }
      },
      scales: {
        x: {
          title: {
            display: true,
            text: isCatMode
              ? t('axisTotalComplaints', 'Total complaints')
              : t('axisComplaintVolume', 'Complaint volume'),
            font: { size: 11, weight: '600' }
          },
          beginAtZero: true,
          ticks: { precision: 0, font: { size: 10 } },
          grid: { color: 'rgba(0, 0, 0, 0.05)' }
        },
        y: {
          title: {
            display: true,
            text: isCatMode
              ? t('axisUnresolvedComplaints', 'Unresolved complaints')
              : t('axisAveragePriority', 'Average priority score (0-100)'),
            font: { size: 11, weight: '600' }
          },
          beginAtZero: true,
          ticks: { precision: 0, font: { size: 10 } },
          grid: { color: 'rgba(0, 0, 0, 0.05)' }
        }
      }
    }
  });
}

function renderResolutionHistogram(histogramBins, resolvedCount) {
  const canvas = $('chart-resolution-histogram');
  const emptyEl = $('resolution-histogram-empty');
  if (!canvas || typeof Chart === 'undefined') return;

  if (chartInstances.resolutionHistogram) {
    chartInstances.resolutionHistogram.destroy();
    chartInstances.resolutionHistogram = null;
  }

  const bins = histogramBins && typeof histogramBins === 'object' ? histogramBins : {};
  const labels = Object.keys(bins);
  const values = Object.values(bins);
  const totalInBins = values.reduce((a, b) => a + b, 0);

  if (emptyEl) {
    emptyEl.classList.toggle('hidden', totalInBins > 0);
  }

  if (totalInBins === 0) {
    return;
  }

  chartInstances.resolutionHistogram = new Chart(canvas, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: t('resolutionHistogramTitle', 'Resolved Complaints Distribution'),
        data: values,
        backgroundColor: 'rgba(16, 185, 129, 0.75)',
        borderColor: '#059669',
        borderWidth: 1.5,
        borderRadius: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => ` Resolved Cases: ${ctx.parsed.y}`
          }
        }
      },
      scales: {
        x: {
          title: {
            display: true,
            text: t('axisResolutionDuration', 'Time to resolution'),
            font: { size: 11, weight: '600' }
          },
          grid: { display: false }
        },
        y: {
          title: {
            display: true,
            text: t('axisComplaintCount', 'Number of complaints'),
            font: { size: 11, weight: '600' }
          },
          beginAtZero: true,
          ticks: { precision: 0 }
        }
      }
    }
  });
}

function renderDeptWorkloadChart(workload) {
  const canvas = $('chart-dept-workload');
  if (!canvas || typeof Chart === 'undefined') return;

  if (chartInstances.deptWorkload) {
    chartInstances.deptWorkload.destroy();
    chartInstances.deptWorkload = null;
  }

  const dist = workload && typeof workload === 'object' ? workload : {};
  const actualLabels = Object.keys(dist);
  const labels = actualLabels.length ? actualLabels : [t('noData', 'No data')];
  const values = actualLabels.length ? Object.values(dist) : [0];

  chartInstances.deptWorkload = new Chart(canvas, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: t('deptWorkloadTitle', 'Department Workload'),
        data: values,
        backgroundColor: 'rgba(59, 130, 246, 0.75)',
        borderColor: '#2563eb',
        borderWidth: 1.5,
        borderRadius: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      indexAxis: 'y',
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          beginAtZero: true,
          title: {
            display: true,
            text: t('axisComplaintCount', 'Number of complaints'),
            font: { size: 11, weight: '600' }
          },
          ticks: { precision: 0 }
        },
        y: {
          title: {
            display: true,
            text: t('axisDepartment', 'Department'),
            font: { size: 11, weight: '600' }
          }
        }
      }
    }
  });
}

function renderProblemHeatmap(heatmapPoints) {
  const container = $('analytics-heatmap');
  if (!container || typeof L === 'undefined') return;

  const valid = (heatmapPoints || []).filter(
    (p) => p.latitude != null && p.longitude != null && !isNaN(p.latitude) && !isNaN(p.longitude)
  );

  if (!chartInstances.heatmap) {
    if (container._leaflet_id) {
      container._leaflet_id = null;
      container.innerHTML = '';
    }
    chartInstances.heatmap = L.map(container, {
      zoomControl: true,
      scrollWheelZoom: false
    }).setView([19.7515, 75.7139], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap'
    }).addTo(chartInstances.heatmap);
  }

  if (chartInstances.heatLayer) {
    chartInstances.heatmap.removeLayer(chartInstances.heatLayer);
    chartInstances.heatLayer = null;
  }

  if (valid.length === 0) {
    setTimeout(() => chartInstances.heatmap?.invalidateSize(), 150);
    return;
  }

  if (typeof L.heatLayer === 'function') {
    const latLngs = valid.map((p) => [
      Number(p.latitude),
      Number(p.longitude),
      Math.max(0.2, Math.min(1.0, Number(p.weight || 0.5)))
    ]);
    chartInstances.heatLayer = L.heatLayer(latLngs, {
      radius: 25,
      blur: 15,
      maxZoom: 17,
      max: 1.0,
      gradient: {
        0.2: '#0284c7',
        0.4: '#10b981',
        0.7: '#f59e0b',
        1.0: '#ef4444'
      }
    }).addTo(chartInstances.heatmap);
  } else {
    const group = L.layerGroup();
    valid.forEach((p) => {
      const color = (p.severity === 'Critical') ? '#ef4444' : (p.severity === 'High') ? '#f59e0b' : '#0d9488';
      L.circleMarker([p.latitude, p.longitude], {
        radius: Math.max(6, Math.min(18, (p.weight || 0.5) * 16)),
        fillColor: color,
        color: '#ffffff',
        weight: 1.5,
        opacity: 0.9,
        fillOpacity: 0.65
      }).bindPopup(`<strong>Complaint #${p.complaint_id}</strong><br>${escapeHtml(translateCategory(p.category))}<br>Severity: ${escapeHtml(p.severity || 'Medium')}`).addTo(group);
    });
    chartInstances.heatLayer = group.addTo(chartInstances.heatmap);
  }

  const bounds = valid.map((p) => [Number(p.latitude), Number(p.longitude)]);
  if (bounds.length === 1) {
    chartInstances.heatmap.setView(bounds[0], 14);
  } else {
    chartInstances.heatmap.fitBounds(bounds, { padding: [30, 30], maxZoom: 16 });
  }

  setTimeout(() => chartInstances.heatmap?.invalidateSize(), 200);
}

function renderResolutionAndFrequentIssues(resolution, frequent) {
  const box = $('resolution-summary-box');
  if (box) {
    const avgHrs = resolution?.average_hours != null ? Number(resolution.average_hours).toFixed(1) : '—';
    const minHrs = resolution?.min_hours != null ? Number(resolution.min_hours).toFixed(1) : '—';
    const maxHrs = resolution?.max_hours != null ? Number(resolution.max_hours).toFixed(1) : '—';
    const count = resolution?.resolved_count ?? 0;

    box.innerHTML = `
      <div class="summary-box-item">
        <span class="muted">${escapeHtml(t('avgResolutionLabel', 'Average Resolution Time'))}</span>
        <strong>${avgHrs} ${avgHrs !== '—' ? 'hrs' : ''}</strong>
      </div>
      <div class="summary-box-item">
        <span class="muted">${escapeHtml(t('minResolutionLabel', 'Fastest Resolution'))}</span>
        <strong>${minHrs} ${minHrs !== '—' ? 'hrs' : ''}</strong>
      </div>
      <div class="summary-box-item">
        <span class="muted">${escapeHtml(t('maxResolutionLabel', 'Longest Turnaround'))}</span>
        <strong>${maxHrs} ${maxHrs !== '—' ? 'hrs' : ''}</strong>
      </div>
      <div class="summary-box-item">
        <span class="muted">${escapeHtml(t('resolvedCasesLabel', 'Resolved Cases'))}</span>
        <strong>${count}</strong>
      </div>
    `;
  }

  const tableContainer = $('frequent-issues-table-container');
  if (tableContainer) {
    const list = Array.isArray(frequent) ? frequent : [];
    if (!list.length) {
      tableContainer.innerHTML = `<p class="muted" style="padding: 12px; font-size: 13px;">${escapeHtml(t('noFrequentProblems', 'No recurring problem hotspots detected in selected range.'))}</p>`;
    } else {
      tableContainer.innerHTML = `
        <table class="frequent-table">
          <thead>
            <tr>
              <th>${escapeHtml(t('locationCol', 'Location / Landmark'))}</th>
              <th>${escapeHtml(t('thCategory', 'Category'))}</th>
              <th>${escapeHtml(t('occurrencesCol', 'Occurrences'))}</th>
              <th>${escapeHtml(t('unresolvedCol', 'Unresolved'))}</th>
              <th>${escapeHtml(t('patternRiskCol', 'Pattern Risk'))}</th>
            </tr>
          </thead>
          <tbody>
            ${list.map((item) => `
              <tr>
                <td><strong>${escapeHtml(item.location || 'General Area')}</strong></td>
                <td>${escapeHtml(translateCategory(item.category))}</td>
                <td><span class="badge Low">${item.count}</span></td>
                <td>${item.unresolved_count > 0 ? `<span class="badge High">${item.unresolved_count}</span>` : `<span class="badge Low">0</span>`}</td>
                <td>${item.unresolved_count > 0 ? `<span class="badge Critical">${escapeHtml(t('hotspotLabel', 'Hotspot'))}</span>` : `<span class="badge Low">${escapeHtml(t('resolvedLabel', 'Resolved'))}</span>`}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      `;
    }
  }
}

function renderAdvancedAnalytics(data) {
  if (!data) return;
  analyticsState.data = data;

  try {
    const kpi = data.kpi_summary || {};
    if ($('analytics-kpi-total')) $('analytics-kpi-total').textContent = kpi.total ?? 0;
    if ($('analytics-kpi-pending')) $('analytics-kpi-pending').textContent = kpi.pending ?? 0;
    if ($('analytics-kpi-inprogress')) $('analytics-kpi-inprogress').textContent = kpi.in_progress ?? 0;
    if ($('analytics-kpi-resolved')) $('analytics-kpi-resolved').textContent = kpi.resolved ?? 0;
    if ($('analytics-kpi-critical')) $('analytics-kpi-critical').textContent = kpi.critical ?? 0;
    if ($('analytics-kpi-rate')) $('analytics-kpi-rate').textContent = `${Number(kpi.resolution_rate ?? 0).toFixed(1)}%`;
  } catch (err) {
    console.error('Failed to render KPI summary:', err);
  }

  try {
    const catSelect = $('analytics-cat-filter');
    if (catSelect && Array.isArray(data.available_categories)) {
      const currentVal = analyticsState.category || catSelect.value;
      catSelect.innerHTML = `<option value="">${escapeHtml(t('allCategories', 'All categories'))}</option>` +
        data.available_categories.map((c) => `<option value="${escapeHtml(c)}" ${c === currentVal ? 'selected' : ''}>${escapeHtml(translateCategory(c))}</option>`).join('');
    }

    const deptSelect = $('analytics-dept-filter');
    if (deptSelect && Array.isArray(data.available_departments)) {
      const currentVal = analyticsState.department || deptSelect.value;
      deptSelect.innerHTML = `<option value="">${escapeHtml(t('allDepartments', 'All departments'))}</option>` +
        data.available_departments.map((d) => `<option value="${escapeHtml(d)}" ${d === currentVal ? 'selected' : ''}>${escapeHtml(d)}</option>`).join('');
    }

    const areaSelect = $('analytics-area-filter');
    if (areaSelect && Array.isArray(data.available_areas)) {
      const currentVal = analyticsState.area || areaSelect.value;
      areaSelect.innerHTML = `<option value="">${escapeHtml(t('allAreas', 'All Areas / Wards'))}</option>` +
        data.available_areas.map((a) => `<option value="${escapeHtml(a)}" ${a === currentVal ? 'selected' : ''}>${escapeHtml(a)}</option>`).join('');
    }
  } catch (err) {
    console.error('Failed to render analytics filter options:', err);
  }

  try { renderCategoryBarChart(data.category_distribution); } catch (e) { console.error('Bar chart error:', e); }
  try { renderStatusDonutChart(data.status_distribution); } catch (e) { console.error('Donut chart error:', e); }
  try { renderTrendLineChart(data.trend_timeline); } catch (e) { console.error('Trend line chart error:', e); }
  try { renderBubbleChart(data); } catch (e) { console.error('Bubble chart error:', e); }
  try { renderResolutionHistogram(data.resolution_analytics?.histogram_bins, data.resolution_analytics?.resolved_count); } catch (e) { console.error('Histogram error:', e); }
  try { renderDeptWorkloadChart(data.department_workload); } catch (e) { console.error('Dept workload error:', e); }
  try { renderProblemHeatmap(data.heatmap_points); } catch (e) { console.error('Heatmap error:', e); }
  try { renderResolutionAndFrequentIssues(data.resolution_analytics, data.frequent_problems); } catch (e) { console.error('Resolution/frequent error:', e); }
}

async function loadAdvancedAnalytics() {
  const loadVersion = dashboardLoadVersion;
  const params = new URLSearchParams();
  addVillageScope(params);
  if (analyticsState.startDate) params.append('start_date', analyticsState.startDate);
  if (analyticsState.endDate) params.append('end_date', analyticsState.endDate);
  if (analyticsState.category) params.append('category', analyticsState.category);
  if (analyticsState.status) params.append('status', analyticsState.status);
  if (analyticsState.department) params.append('department', analyticsState.department);
  if (analyticsState.area) params.append('area', analyticsState.area);
  if (analyticsState.interval) params.append('interval', analyticsState.interval);

  try {
    const data = await api(`/officer/analytics/advanced?${params.toString()}`);
    if (loadVersion === dashboardLoadVersion) renderAdvancedAnalytics(data);
  } catch (err) {
    console.error('Failed to load advanced analytics:', err);
  }
}

function renderPredictions(data) {
  state.lastPredictions = data;
  const container = $('predictions-content');
  const pill = $('prediction-status-pill');
  if (!container) return;

  if (!data) {
    container.innerHTML = '<p class="muted">Prediction data unavailable.</p>';
    return;
  }

  if (pill) {
    pill.textContent = data.status === 'baseline_available'
      ? `Active (${data.sample_count} samples)`
      : `${t('safeguardActive', 'Safeguard active')} (${data.sample_count}/${data.required_samples})`;
  }

  const predictions = Array.isArray(data.predictions) ? data.predictions : [];
  if (!predictions.length) {
    container.innerHTML = `
      <div class="focus-item">
        <span>${escapeHtml(data.message || 'No chronic repeat issue hotspots detected.')}</span>
        <span class="badge Low">Safe</span>
      </div>`;
    return;
  }

  container.innerHTML = predictions.map((pred) => `
    <div class="focus-item">
      <div>
        <strong>${escapeHtml(pred.location || pred.lane || 'Area Hotspot')}</strong>
        <small class="muted">${escapeHtml(translateCategory(pred.category || 'General'))} · ${pred.repeat_count || pred.count || 0} occurrences</small>
      </div>
      <span class="badge High">Chronic Risk</span>
      <strong>${pred.predicted_next_window ? escapeHtml(pred.predicted_next_window) : 'Watchlist'}</strong>
    </div>
  `).join('');
}

async function triggerEscalationCheck() {
  const alert = $('escalation-alert');
  const btn = $('run-escalation-button');
  if (btn) btn.disabled = true;
  try {
    const res = await api(scopedPath('/officer/escalations/check'), { method: 'POST' });
    if (alert) {
      alert.classList.remove('hidden');
      alert.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <div>
            <strong>SLA Escalation Check Complete</strong><br>
            <span>Threshold: ${res.threshold_hours} hours. Overdue complaints escalated: <strong>${res.escalated_count}</strong></span>
          </div>
          <button class="ghost-button" onclick="$('escalation-alert').classList.add('hidden')" style="padding:2px 8px;">✕</button>
        </div>`;
    }
    await loadAll();
  } catch (error) {
    if (alert) {
      alert.classList.remove('hidden');
      alert.innerHTML = `<span class="error">Escalation check error: ${escapeHtml(error.message)}</span>`;
    }
  } finally {
    if (btn) btn.disabled = false;
  }
}

async function viewGovernanceReport() {
  const panel = $('report-view');
  const content = $('report-content');
  const btn = $('view-report-button');
  if (btn) btn.disabled = true;
  try {
    const res = await api(scopedPath('/officer/reports/summary'));
    if (panel && content) {
      panel.classList.remove('hidden');
      const sum = res.summary || {};
      content.innerHTML = `
        <div class="detail-item"><span>${escapeHtml(t('totalComplaints', 'Total complaints'))}</span><strong>${sum.total_complaints ?? 0}</strong></div>
        <div class="detail-item"><span>${escapeHtml(t('resolvedComplaints', 'Resolved'))}</span><strong>${sum.resolved_complaints ?? 0}</strong></div>
        <div class="detail-item"><span>${escapeHtml(t('resolutionRate', 'Resolution rate'))}</span><strong>${sum.resolution_rate != null ? `${Number(sum.resolution_rate).toFixed(1)}%` : '—'}</strong></div>
        <div class="detail-item"><span>${escapeHtml(t('overdueComplaints', 'Overdue'))}</span><strong>${sum.overdue_complaints ?? 0}</strong></div>
        <div class="detail-item"><span>${escapeHtml(t('criticalComplaints', 'Critical severity'))}</span><strong>${sum.critical_severity_complaints ?? 0}</strong></div>
        <div class="detail-item"><span>Average resolution turnaround</span><strong>${sum.avg_resolution_hours != null ? `${Number(sum.avg_resolution_hours).toFixed(1)} hours` : '—'}</strong></div>
        <div class="detail-item detail-wide"><span>Generated at</span><strong>${new Date(res.generated_at).toLocaleString()}</strong></div>
      `;
    }
  } catch (error) {
    if (content) {
      content.innerHTML = `<p class="error">Failed to generate report: ${escapeHtml(error.message)}</p>`;
    }
  } finally {
    if (btn) btn.disabled = false;
  }
}

async function downloadFile(url, defaultFilename) {
  try {
    const token = state.token || localStorage.getItem('officer_token');
    const response = await fetch(scopedPath(url), {
      headers: { Authorization: `Bearer ${token}` }
    });
    if (!response.ok) throw new Error('Download failed');
    const blob = await response.blob();
    const blobUrl = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = defaultFilename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(blobUrl);
  } catch (err) {
    alert('Export error: ' + err.message);
  }
}

function locationSummary(point) {
  const parts = [
    point.lane,
    point.lane_number,
    point.exact_location,
    point.area
  ].filter(Boolean);

  return parts.length ? parts.join(' · ') : t('notProvided', 'Location not provided');
}

function hasValidCoordinates(point) {
  if (point.latitude == null || point.longitude == null) return false;
  const latitude = Number(point.latitude);
  const longitude = Number(point.longitude);

  return Number.isFinite(latitude) &&
    Number.isFinite(longitude) &&
    Math.abs(latitude) <= 90 &&
    Math.abs(longitude) <= 180;
}

async function showComplaintOnMap(id) {
  const complaintId = Number(id);
  if (!Number.isInteger(complaintId) || complaintId <= 0) return;

  try {
    state.returnToComplaintId = complaintId;
    state.returnFromPage = activePage || 'complaints';

    let item = state.selectedComplaint && state.selectedComplaint.id === complaintId
      ? state.selectedComplaint
      : null;
    if (!item) {
      item = await api(scopedPath(`/officer/complaints/${complaintId}`));
    }

    state.selectedMapComplaintId = complaintId;
    const detailDrawer = $('detail-drawer');
    if (detailDrawer) detailDrawer.classList.add('hidden');
    navigateToPage('map');

    // Display map return bar
    const returnBar = $('map-return-bar');
    const returnBtnText = $('return-complaint-btn-text');
    const returnInfo = $('map-return-info');
    if (returnBar) {
      if (returnBtnText) {
        returnBtnText.textContent = `${t('backToComplaint', 'Back to Complaint Details')} (#${complaintId})`;
      }
      if (returnInfo) {
        const villageText = item.village ? `${item.village}${item.district ? `, ${item.district}` : ''}` : '';
        returnInfo.textContent = villageText ? `• ${villageText}` : '';
      }
      returnBar.classList.remove('hidden');
    }

    // Validate coordinates range (-90 to 90, -180 to 180)
    const lat = Number(item.latitude);
    const lon = Number(item.longitude);
    const hasValidCoords = Boolean(
      item.latitude != null && item.longitude != null &&
      Number.isFinite(lat) && Number.isFinite(lon) &&
      lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
    );

    const message = $('map-selection-message');

    if (!hasValidCoords) {
      if (message) {
        message.innerHTML = `<span style="color:var(--amber); font-weight:700;">⚠ ${escapeHtml(t('locationUnavailable', 'Location unavailable'))}:</span> ${escapeHtml(t('noComplaintCoordinates', 'No GPS coordinates are recorded for complaint'))} #${complaintId}.`;
      }
      return;
    }

    if (!state.lastTwin) {
      state.lastTwin = await api(scopedPath('/officer/digital-twin'));
      renderTwin(state.lastTwin);
    }

    if (window.complaintLeafletMap) {
      window.complaintLeafletMap.invalidateSize();
      window.complaintLeafletMap.setView([lat, lon], 17);

      let marker = window.complaintMarkerById?.get(complaintId);
      if (!marker && window.complaintMarkerLayer) {
        marker = L.marker([lat, lon]).addTo(window.complaintMarkerLayer);
        window.complaintMarkerById.set(complaintId, marker);
      }
      if (marker) {
        const summarySnippet = item.text ? (item.text.length > 90 ? item.text.slice(0, 90) + '...' : item.text) : '';
        marker.bindPopup(`
          <div style="min-width: 190px; line-height: 1.4;">
            <div style="font-size: 13px; font-weight: 700; margin-bottom: 3px;">Complaint #${complaintId}</div>
            <div style="font-size: 12px; color: #374151; margin-bottom: 5px;"><strong>${escapeHtml(translateCategory(item.category || 'General'))}</strong></div>
            <div style="font-size: 11px; color: #4b5563; margin-bottom: 6px;">${escapeHtml(summarySnippet)}</div>
            <div style="margin-bottom: 5px;">
              <span class="badge ${escapeHtml(item.severity || 'Medium')}">${escapeHtml(translateSeverity(item.severity || 'Medium'))}</span>
              <span class="badge status">${escapeHtml(translateStatus(item.status || 'Pending'))}</span>
            </div>
            <div style="font-size: 10px; color: #6b7280;">📍 ${lat.toFixed(5)}, ${lon.toFixed(5)}</div>
            <div style="margin-top: 6px; padding-top: 5px; border-top: 1px solid #e5e7eb;">
              <button type="button" class="ghost-button" style="padding: 2px 6px; font-size: 11px; cursor: pointer;" onclick="openDetail(${complaintId})">${escapeHtml(t('openCase', 'Open details'))} →</button>
            </div>
          </div>
        `);
        marker.openPopup();
      }
    }

    if (message) {
      message.textContent = `${t('showingComplaint', 'Showing complaint')} #${complaintId} (${lat.toFixed(5)}, ${lon.toFixed(5)}).`;
    }
  } catch (error) {
    if ($('connection-status')) $('connection-status').textContent = error.message;
  }
}

function renderTwin(data) {
  state.lastTwin = data;
  const village = data.village || {};
  const points = data.map_points || [];
  const boundaryAlerts = data.boundary_alerts || [];
  const assets = data.assets || [];

  $('village-summary').innerHTML = `
    <div class="village-summary">
      <div>
        <span class="muted">${escapeHtml(t('villageLabel', 'Village'))}</span>
        <strong>${escapeHtml(village.name || 'No village data')}</strong>
      </div>
      <div>
        <span class="muted">District</span>
        <strong>${escapeHtml(village.district || '—')}</strong>
      </div>
      <div>
        <span class="muted">${escapeHtml(t('talukaLabel', 'Taluka'))}</span>
        <strong>${escapeHtml(village.taluka || t('scopeNotRecorded', 'Taluka not recorded'))}</strong>
      </div>
      <div>
        <span class="muted">${escapeHtml(t('totalComplaints', 'Complaints'))}</span>
        <strong>${village.complaint_count ?? 0}</strong>
      </div>
      <div>
        <span class="muted">Boundary radius</span>
        <strong>${village.boundary_radius_km != null ? `${village.boundary_radius_km} km` : 'Not configured'}</strong>
      </div>
    </div>`;

  $('resource-grid').innerHTML = (data.resources || [])
    .map((resource) => `
      <div class="resource">
        <strong>${escapeHtml(translateCategory(resource.resource))}</strong>
        <small>${resource.active_issues} active issues · ${escapeHtml(resource.status)}</small>
      </div>
    `).join('');

  // 9-Domain Village Infrastructure Digital Twin Asset Registry (SRS Module 6)
  const registryContainer = $('asset-registry-container');
  if (registryContainer) {
    if (!assets.length) {
      registryContainer.innerHTML = '<p class="muted">Asset registry is initializing...</p>';
    } else {
      registryContainer.innerHTML = `
        <table class="asset-table">
          <thead>
            <tr>
              <th>${escapeHtml(t('assetIdCol', 'ID'))}</th>
              <th>${escapeHtml(t('domainCol', 'Domain'))}</th>
              <th>${escapeHtml(t('assetNameCol', 'Infrastructure Asset'))}</th>
              <th>Location</th>
              <th>${escapeHtml(t('healthCol', 'Health Index'))}</th>
              <th>${escapeHtml(t('statusCol', 'Status'))}</th>
              <th>${escapeHtml(t('activeIssuesCol', 'Linked Complaints'))}</th>
              <th>${escapeHtml(t('notesCol', 'Maintenance Notes'))}</th>
            </tr>
          </thead>
          <tbody>
            ${assets.map((asset) => {
              const cond = Number(asset.condition_index) || 0;
              const fillClass = cond >= 80 ? 'health-good' : cond >= 60 ? 'health-medium' : 'health-poor';
              return `
                <tr>
                  <td><strong>${escapeHtml(asset.asset_id)}</strong></td>
                  <td>${escapeHtml(translateCategory(asset.domain))}</td>
                  <td><strong>${escapeHtml(asset.name)}</strong></td>
                  <td>${escapeHtml(asset.location)}</td>
                  <td>
                    <div class="health-bar-container">
                      <div class="health-track">
                        <div class="health-fill ${fillClass}" style="width: ${cond}%;"></div>
                      </div>
                      <span>${cond}%</span>
                    </div>
                  </td>
                  <td>${badge(asset.status, 'status')}</td>
                  <td>${asset.active_complaints_count > 0 ? `<span class="badge High">${asset.active_complaints_count}</span>` : '0'}</td>
                  <td><small class="muted">${escapeHtml(asset.maintenance_notes)}</small></td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      `;
    }
  }

  const boundaryNode = $('boundary-alerts');
  if (boundaryNode) {
    boundaryNode.innerHTML = boundaryAlerts.length
      ? boundaryAlerts.map((alert) => `
          <div class="map-item">
            <span>
              Complaint #${escapeHtml(String(alert.complaint_id))}
              <small class="muted">${escapeHtml(alert.village || 'Village unavailable')}</small>
              <small class="muted">${escapeHtml(String(alert.message || 'Outside assigned village boundary'))}</small>
            </span>
            <span class="badge High">${escapeHtml(t('outsideBoundary', 'Outside boundary'))}</span>
          </div>
        `).join('')
      : '<p class="muted">No complaint locations fall outside the village boundary.</p>';
  }

  const locatedPoints = points.filter((point) => {
    return point.is_valid_coordinate === true && hasValidCoordinates(point);
  });

  const map = $('complaint-map');
  const mapMessage = $('map-selection-message');

  if (map) {
    if (typeof L === 'undefined') {
      map.innerHTML = '<p class="muted">Map library unavailable. Check your internet connection.</p>';
      if (mapMessage) mapMessage.textContent = '';
    } else if (!window.complaintLeafletMap && (!map.offsetWidth || !map.offsetHeight)) {
      map.innerHTML = `<p class="muted">${escapeHtml(t('openMapToLoad', 'Open the map page to load complaint locations.'))}</p>`;
      if (mapMessage) mapMessage.textContent = '';
    } else {
      if (!window.complaintLeafletMap) {
        map.innerHTML = '';
        const initialCenter = locatedPoints.length
          ? [Number(locatedPoints[0].latitude), Number(locatedPoints[0].longitude)]
          : hasValidCoordinates(village)
            ? [Number(village.latitude), Number(village.longitude)]
            : [20.5937, 78.9629];
        const initialZoom = locatedPoints.length ? 14 : hasValidCoordinates(village) ? 12 : 5;
        window.complaintLeafletMap = L.map(map).setView(
          initialCenter,
          initialZoom
        );

        const satelliteLayer = L.tileLayer(
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          {
            maxZoom: 19,
            attribution: 'Tiles &copy; Esri — Source: Esri, Maxar, Earthstar Geographics, and the GIS User Community'
          }
        );
        const streetLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          maxZoom: 19,
          attribution: '&copy; OpenStreetMap contributors'
        });
        window.complaintSatelliteLayer = satelliteLayer;
        window.complaintStreetLayer = streetLayer;
        satelliteLayer.addTo(window.complaintLeafletMap);

        window.complaintMarkerLayer = L.layerGroup().addTo(window.complaintLeafletMap);
        window.complaintMarkerById = new Map();
      }

      if (window.complaintLayerControl) window.complaintLayerControl.remove();
      window.complaintLayerControl = L.control.layers({
        [t('satelliteLayer', 'Satellite')]: window.complaintSatelliteLayer,
        [t('streetLayer', 'Street map')]: window.complaintStreetLayer
      }).addTo(window.complaintLeafletMap);

      window.complaintLeafletMap.closePopup();
      window.complaintMarkerLayer.clearLayers();
      window.complaintMarkerById.clear();
      const bounds = [];

      locatedPoints.forEach((point) => {
        const lat = Number(point.latitude);
        const lon = Number(point.longitude);
        const position = [lat, lon];
        const isOutsideBoundary = point.is_outside_boundary === true;

        bounds.push(position);

        const marker = isOutsideBoundary
          ? L.marker(position, {
              icon: L.divIcon({ className: 'boundary-warning-marker', html: '⚠', iconSize: [20, 20] })
            }).addTo(window.complaintMarkerLayer)
          : L.marker(position).addTo(window.complaintMarkerLayer);

        marker.bindPopup(`
          <strong>Complaint #${escapeHtml(String(point.complaint_id))}</strong><br>
          ${escapeHtml(point.village || 'Village unavailable')}<br>
          ${escapeHtml(locationSummary(point))}<br>
          ${escapeHtml(translateStatus(point.status))}<br>
          ${escapeHtml(translateSeverity(point.priority_level))}<br>
          ${Number(point.repeated_complaints) || 0} ${escapeHtml(t('repeatReports', 'repeat reports'))}<br>
          ${lat.toFixed(4)}, ${lon.toFixed(4)}
          ${isOutsideBoundary ? `<br><strong>${escapeHtml(t('outsideBoundary', 'Outside village boundary'))}</strong>` : ''}
        `);
        marker.on('click', () => openDetail(point.complaint_id));
        window.complaintMarkerById.set(Number(point.complaint_id), marker);
      });

      const selectedPoint = locatedPoints.find(
        (point) => Number(point.complaint_id) === Number(state.selectedMapComplaintId)
      );
      if (selectedPoint) {
        const selectedPosition = [Number(selectedPoint.latitude), Number(selectedPoint.longitude)];
        window.complaintLeafletMap.setView(selectedPosition, 18);
        window.complaintMarkerById.get(Number(selectedPoint.complaint_id))?.openPopup();
      } else if (bounds.length === 1) {
        window.complaintLeafletMap.setView(bounds[0], 16);
      } else if (bounds.length > 1) {
        window.complaintLeafletMap.fitBounds(bounds, { padding: [25, 25], maxZoom: 16 });
      } else if (hasValidCoordinates(village)) {
        window.complaintLeafletMap.setView(
          [Number(village.latitude), Number(village.longitude)],
          12
        );
      } else if (!window.complaintLeafletMap.getZoom()) {
        window.complaintLeafletMap.setView([20.5937, 78.9629], 5);
      }

      if (mapMessage) {
        if (state.selectedMapComplaintId && !selectedPoint) {
          mapMessage.textContent =
            `${t('noComplaintCoordinates', 'No GPS coordinates are recorded for complaint')} #${state.selectedMapComplaintId}.`;
        } else if (!locatedPoints.length) {
          mapMessage.textContent = t('noCoordinates', 'No valid complaint coordinates available yet.');
        } else if (!state.selectedMapComplaintId) {
          mapMessage.textContent = t('selectComplaintOnMap', 'Select a complaint below to zoom to its map location.');
        } else {
          mapMessage.textContent = `${t('showingComplaint', 'Showing complaint')} #${state.selectedMapComplaintId}.`;
        }
      }

      setTimeout(() => {
        if (window.complaintLeafletMap) window.complaintLeafletMap.invalidateSize();
      }, 100);
    }
  }

  const mapPoints = $('map-points');
  if (mapPoints) {
    mapPoints.innerHTML = points.length
      ? points.map((point) => `
        <article class="map-item map-point-card">
          <span>
            Complaint #${escapeHtml(String(point.complaint_id))}
            <small class="muted">${escapeHtml(point.village || 'Village unavailable')}</small>
            <small class="muted">
              ${escapeHtml(locationSummary(point))}
              ${point.latitude != null && point.longitude != null
                ? ` · ${escapeHtml(String(point.latitude))}, ${escapeHtml(String(point.longitude))}`
                : ` · ${escapeHtml(t('coordinatesUnavailable', 'Coordinates unavailable'))}`}
              ${point.is_outside_boundary ? ` · ${escapeHtml(t('outsideBoundary', 'Outside boundary'))}` : ''}
            </small>
            <small class="muted">${Number(point.repeated_complaints) || 0} ${escapeHtml(t('repeatReports', 'repeat reports'))}</small>
            <small>${escapeHtml(translateCategory(point.category))} · ${escapeHtml(translateStatus(point.status))}</small>
          </span>
          <span class="map-point-actions">
            ${point.is_outside_boundary ? `<span class="badge High">${escapeHtml(t('outsideBoundary', 'Outside boundary'))}</span>` : badge(point.status, 'status')}
            <button type="button" class="secondary-button" data-open-complaint-id="${escapeHtml(String(point.complaint_id))}">
              ${escapeHtml(t('openCase', 'Open details'))}
            </button>
            ${hasValidCoordinates(point) ? `
              <button type="button" class="secondary-button" data-map-complaint-id="${escapeHtml(String(point.complaint_id))}">
                ${escapeHtml(t('showOnMap', 'Show on map'))}
              </button>
            ` : ''}
          </span>
        </article>
      `).join('')
      : `<p class="muted">${escapeHtml(t('noRecords', 'No complaint locations are available yet.'))}</p>`;
  }
}

async function loadAll() {
  const loadVersion = ++dashboardLoadVersion;
  if (dashboardLoadInProgress) return;
  dashboardLoadInProgress = true;
  $('connection-status').textContent = t('refreshing', 'Refreshing');

  try {
    await loadVillageOptions();
    if (loadVersion !== dashboardLoadVersion) return;
    const scope = (path) => scopedPath(path);
    const [dashboard, complaints, insights, twin, officers, predictions] = await Promise.all([
      api(scope('/officer/dashboard')),
      api(scope('/officer/complaints')),
      api(scope('/officer/insights')),
      api(scope('/officer/digital-twin')),
      api(scope('/officer/officers')),
      api(scope('/officer/predictions/repeated-issues')).catch(() => null)
    ]);

    if (loadVersion !== dashboardLoadVersion) return;
    state.officers = officers;
    await loadPendingOfficers();
    if (loadVersion !== dashboardLoadVersion) return;
    try { renderDashboard(dashboard); } catch (e) { console.error('renderDashboard error:', e); }
    try { renderComplaints(complaints); } catch (e) { console.error('renderComplaints error:', e); }
    try { renderAssignments(complaints); } catch (e) { console.error('renderAssignments error:', e); }
    try { renderInsights(insights); } catch (e) { console.error('renderInsights error:', e); }
    try { renderTwin(twin); } catch (e) { console.error('renderTwin error:', e); }
    try { renderPredictions(predictions); } catch (e) { console.error('renderPredictions error:', e); }
    try { await loadAdvancedAnalytics(); } catch (e) { console.error('loadAdvancedAnalytics error:', e); }

    lastDashboardRefreshAt = Date.now();
    const updatedAt = $('dashboard-updated-at');
    if (updatedAt) {
      updatedAt.textContent =
        `${t('lastUpdated', 'Updated')} ${new Date(lastDashboardRefreshAt).toLocaleTimeString()}`;
    }
    $('connection-status').textContent = t('connected', 'Connected');
  } catch (error) {
    if (loadVersion === dashboardLoadVersion) {
      $('connection-status').textContent = t('connError', 'Connection error');
      console.error(error);
    }
  } finally {
    dashboardLoadInProgress = false;
    if (loadVersion !== dashboardLoadVersion) loadAll();
  }
}

async function applyFilters() {
  const params = new URLSearchParams();
  addVillageScope(params);

  [
    ['search-filter', 'search'],
    ['category-filter', 'category'],
    ['severity-filter', 'severity'],
    ['priority-filter', 'priority'],
    ['status-filter', 'status'],
    ['department-filter', 'department'],
    ['complaint-start-date', 'start_date'],
    ['complaint-end-date', 'end_date']
  ].forEach(([id, key]) => {
    const el = $(id);
    if (el && el.value) params.set(key, el.value.trim());
  });

  try {
    state.complaintPage = 1;
    renderComplaints(await api(`/officer/complaints?${params}`));
  } catch (error) {
    showAlert('error', `Filter error: ${error.message}`);
    $('connection-status').textContent = error.message;
  }
}

async function handleAcceptComplaint() {
  if (!state.selectedComplaintId || state.isSubmittingDecision) return;
  const btn = $('btn-accept-complaint');
  const msgEl = $('decision-message');
  state.isSubmittingDecision = true;
  setBtnLoading(btn, true, 'Accepting...');
  if (msgEl) msgEl.textContent = '';

  try {
    await api(`/officer/complaints/${state.selectedComplaintId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({
        status: 'In Progress',
        action_notes: 'Complaint accepted by officer and marked In Progress.'
      })
    });
    showAlert('success', `Complaint #${state.selectedComplaintId} accepted successfully!`);
    if (msgEl) msgEl.textContent = 'Complaint accepted.';
    await loadAll();
    await openDetail(state.selectedComplaintId);
  } catch (err) {
    showAlert('error', `Accept error: ${err.message}`);
    if (msgEl) msgEl.textContent = `Error: ${err.message}`;
  } finally {
    state.isSubmittingDecision = false;
    setBtnLoading(btn, false);
  }
}

async function handleRejectComplaint() {
  if (!state.selectedComplaintId || state.isSubmittingDecision) return;
  const reasonInput = $('quick-reject-reason');
  const reason = reasonInput ? reasonInput.value.trim() : '';
  const msgEl = $('decision-message');

  if (!reason) {
    if (msgEl) {
      msgEl.textContent = t('rejectionReasonLabel', 'Rejection reason is required.');
      msgEl.style.color = '#dc2626';
    }
    if (reasonInput) reasonInput.focus();
    return;
  }

  const btn = $('btn-confirm-reject');
  state.isSubmittingDecision = true;
  setBtnLoading(btn, true, 'Rejecting...');

  try {
    await api(`/officer/complaints/${state.selectedComplaintId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({
        status: 'Rejected',
        action_notes: reason
      })
    });
    showAlert('success', `Complaint #${state.selectedComplaintId} rejected.`);
    if (msgEl) msgEl.textContent = 'Complaint rejected.';
    $('reject-reason-box')?.classList.add('hidden');
    if (reasonInput) reasonInput.value = '';
    await loadAll();
    await openDetail(state.selectedComplaintId);
  } catch (err) {
    showAlert('error', `Rejection error: ${err.message}`);
    if (msgEl) msgEl.textContent = `Error: ${err.message}`;
  } finally {
    state.isSubmittingDecision = false;
    setBtnLoading(btn, false);
  }
}

async function openDetail(id) {
  try {
    const item = await api(scopedPath(`/officer/complaints/${id}`));

    state.selectedComplaintId = id;
    state.selectedComplaint = item;
    $('detail-title').textContent = `${escapeHtml(t('thComplaint', 'Complaint'))} #${item.id}`;

    // Validate coordinates
    const lat = Number(item.latitude);
    const lon = Number(item.longitude);
    const hasValidCoords = Boolean(
      item.latitude != null && item.longitude != null &&
      Number.isFinite(lat) && Number.isFinite(lon) &&
      lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
    );

    const mapButtonHtml = hasValidCoords
      ? `<button type="button" class="primary-button detail-map-button" data-map-complaint-id="${escapeHtml(String(item.id))}" style="width:100%; display:inline-flex; align-items:center; justify-content:center; gap:8px;">
          📍 ${escapeHtml(t('viewLocationOnMap', 'View Location on Map'))}
        </button>`
      : `<button type="button" class="secondary-button detail-map-button" disabled style="width:100%; opacity:0.6; cursor:not-allowed;" title="${escapeHtml(t('locationUnavailable', 'Location unavailable'))}">
          📍 ${escapeHtml(t('locationUnavailable', 'Location unavailable'))}
        </button>`;

    const coordsDisplayHtml = hasValidCoords
      ? `<span class="coord-badge valid">📍 ${lat.toFixed(5)}, ${lon.toFixed(5)} · ${escapeHtml(t('validGps', 'Verified GPS'))}</span>`
      : `<span class="coord-badge invalid">⚠ ${escapeHtml(t('locationUnavailable', 'Location unavailable'))}</span><br><small class="muted" style="margin-top:4px; display:inline-block;">${escapeHtml(t('noCoordinatesRecorded', 'No GPS coordinates recorded'))}</small>`;

    let evidenceCardHtml = '';
    const rawUrl = (item.evidence_url || '').trim();
    if (rawUrl) {
      const lowerUrl = rawUrl.toLowerCase();
      const isVideo = lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.ogg');
      const isImage = lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg') || lowerUrl.endsWith('.png') || lowerUrl.endsWith('.webp') || lowerUrl.endsWith('.gif');
      const filename = rawUrl.split('/').pop().split('?')[0] || 'evidence_file';
      const cleanType = isVideo
        ? (lowerUrl.endsWith('.mov') ? 'video/quicktime' : 'video/mp4')
        : (lowerUrl.endsWith('.png') ? 'image/png' : 'image/jpeg');
      const typeLabel = isVideo ? t('videoEvidence', 'Video Evidence (Player)') : t('photoEvidence', 'Photo Evidence (Image)');
      const resolvedUrl = rawUrl.startsWith('http') || rawUrl.startsWith('/') ? rawUrl : `/${rawUrl}`;

      let mediaPreview = '';
      if (isVideo) {
        mediaPreview = `
          <div class="evidence-preview-wrap">
            <video class="evidence-video-player" controls preload="metadata" playsinline title="${escapeHtml(filename)}">
              <source data-evidence-url="${escapeHtml(resolvedUrl)}" type="${escapeHtml(cleanType)}">
              ${escapeHtml(t('unsupportedVideoNote', 'Your browser does not support the video tag.'))}
            </video>
          </div>
        `;
      } else {
        mediaPreview = `
          <button type="button" class="evidence-preview-wrap evidence-preview-button" data-evidence-open="${escapeHtml(resolvedUrl)}" data-evidence-caption="Complaint #${escapeHtml(String(item.id))} — ${escapeHtml(filename)}" data-evidence-filename="${escapeHtml(filename)}">
            <img data-evidence-url="${escapeHtml(resolvedUrl)}" alt="Complaint evidence photo" class="evidence-thumb-img" loading="lazy">
            <span class="evidence-img-overlay">🔍 ${escapeHtml(t('viewFullImage', 'View Full Resolution'))}</span>
          </button>
        `;
      }

      evidenceCardHtml = `
        <div class="evidence-section-card">
          <div class="evidence-header">
            <h4>📎 ${escapeHtml(t('evidenceInspectionTitle', 'Photo & Video Evidence'))}</h4>
            <span class="evidence-pill available">✓ ${escapeHtml(typeLabel)}</span>
          </div>
          ${mediaPreview}
          <div class="evidence-meta-row">
            <div>
              <span class="muted">${escapeHtml(t('fileNameLabel', 'File name'))}:</span>
              <strong>${escapeHtml(filename)}</strong>
            </div>
            <div>
              <span class="muted">${escapeHtml(t('mediaTypeLabel', 'Media type'))}:</span>
              <code>${escapeHtml(cleanType)}</code>
            </div>
            <div>
              <span class="muted">${escapeHtml(t('uploadStatusLabel', 'Upload status'))}:</span>
              <strong>${escapeHtml(t('evidenceAvailable', 'Available'))}</strong>
            </div>
          </div>
          <div class="evidence-actions">
            ${isImage ? `<button type="button" class="secondary-button evidence-action-btn" data-evidence-open="${escapeHtml(resolvedUrl)}" data-evidence-caption="Complaint #${escapeHtml(String(item.id))} — ${escapeHtml(filename)}" data-evidence-filename="${escapeHtml(filename)}">🔍 ${escapeHtml(t('viewFullImage', 'View Full Resolution'))}</button>` : ''}
            <button type="button" class="primary-button evidence-action-btn" data-evidence-download="${escapeHtml(resolvedUrl)}" data-evidence-filename="${escapeHtml(filename)}">⬇ ${escapeHtml(t('downloadEvidence', 'Download Evidence'))}</button>
          </div>
        </div>
      `;
    } else {
      evidenceCardHtml = `
        <div class="evidence-section-card">
          <div class="evidence-header">
            <h4>📎 ${escapeHtml(t('evidenceInspectionTitle', 'Photo & Video Evidence'))}</h4>
            <span class="evidence-pill none">✕ ${escapeHtml(t('notProvided', 'Not provided'))}</span>
          </div>
          <div class="no-evidence-box">
            <p>📷 ${escapeHtml(t('noEvidenceAttached', 'No photo or video evidence was submitted with this report.'))}</p>
            <small class="muted">${escapeHtml(t('noEvidenceHint', 'Villager did not attach visual proof.'))}</small>
          </div>
        </div>
      `;
    }

    const detailBody = $('detail-body');
    detailBody.querySelectorAll('[data-object-url]').forEach((element) => {
      URL.revokeObjectURL(element.dataset.objectUrl);
    });
    detailBody.innerHTML = `
      ${mapButtonHtml}
      <div class="detail-grid">
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('descLabel', 'Description'))}</span><strong>${escapeHtml(item.text)}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('districtLabel', 'District'))}</span><strong>${escapeHtml(item.district || '—')}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('talukaLabel', 'Taluka'))}</span><strong>${escapeHtml(item.taluka || '—')}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('villageLabel', 'Village'))}</span><strong>${escapeHtml(item.village || '—')}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('createdLabel', 'Created'))}</span>
          <strong>${item.created_at ? new Date(item.created_at).toLocaleString() : '—'}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('aiCategoryLabel', 'AI category'))}</span><strong>${escapeHtml(translateCategory(item.category))}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('aiConfidenceLabel', 'AI confidence'))}</span>
          <strong>${item.ai_confidence == null ? '—' : `${(item.ai_confidence * 100).toFixed(1)}%`}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('severityLabel', 'Severity'))}</span><strong>${item.severity ? badge(item.severity, 'severity') : '—'}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('priorityLabel', 'Priority'))}</span>
          <strong>${item.priority_score ?? '—'} · ${escapeHtml(translateSeverity(item.priority_level))}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('thStatus', 'Status'))}</span><strong>${badge(item.status, 'status')}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('thDepartment', 'Assigned department'))}</span><strong>${escapeHtml(item.assigned_department || '—')}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('gpsCoordinates', 'GPS Coordinates'))}</span>
          ${coordsDisplayHtml}
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('laneLabel', 'Lane / Road'))}</span><strong>${escapeHtml(item.lane || t('notProvided', 'Not provided'))}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('laneNumberLabel', 'Lane number'))}</span><strong>${escapeHtml(item.lane_number || t('notProvided', 'Not provided'))}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('exactLocationLabel', 'Exact location'))}</span><strong>${escapeHtml(item.exact_location || t('notProvided', 'Not provided'))}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('areaLabel', 'Area / Locality'))}</span><strong>${escapeHtml(item.area || t('notProvided', 'Not provided'))}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('evidenceLabel', 'Evidence attached'))}</span>
          ${evidenceCardHtml}
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('assignedOfficerLabel', 'Assigned officer'))}</span>
          <strong>${escapeHtml(item.assigned_officer_name || t('unassigned', 'Unassigned'))}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('expectedResolutionLabel', 'Expected resolution date'))}</span>
          <strong>${item.expected_resolution_date ? new Date(item.expected_resolution_date).toLocaleString() : t('notSet', 'Not set')}</strong>
        </div>
        <div class="detail-item">
          <span>${escapeHtml(t('completionDateLabel', 'Completion date'))}</span>
          <strong>${item.completion_date ? new Date(item.completion_date).toLocaleString() : t('notCompleted', 'Not completed')}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('actionNotesLabel', 'Latest action notes'))}</span>
          <strong style="white-space: pre-wrap;">${escapeHtml(item.action_notes || 'No action notes recorded')}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('repairEvidenceLabel', 'Repair completion evidence'))}</span>
          <strong>${escapeHtml(item.repair_evidence_url || 'No repair evidence provided')}</strong>
        </div>
        <div class="detail-item detail-wide">
          <span>${escapeHtml(t('aiExplanationLabel', 'AI reasoning & explanation'))}</span>
          <strong>
            ${escapeHtml(item.severity_explanation || '')}
            <br>${escapeHtml(item.priority_explanation || '')}
          </strong>
        </div>
      </div>`;

    detailBody.querySelectorAll('[data-evidence-url]').forEach((element) => {
      void loadEvidencePreview(element);
    });
    detailBody.querySelectorAll('[data-evidence-open]').forEach((button) => {
      button.addEventListener('click', () => {
        window.openEvidenceLightbox(
          button.dataset.evidenceOpen,
          button.dataset.evidenceCaption,
          button.dataset.evidenceFilename
        );
      });
    });
    detailBody.querySelectorAll('[data-evidence-download]').forEach((button) => {
      button.addEventListener('click', () => {
        void downloadEvidenceFile(button.dataset.evidenceDownload, button.dataset.evidenceFilename);
      });
    });

    $('assigned-department').value =
      item.assigned_department || item.recommended_department || '';
    $('assigned-officer-id').innerHTML = `<option value="">${escapeHtml(t('unassigned', 'Unassigned'))}</option>` +
      state.officers.map((officer) => `
        <option value="${officer.id}">${escapeHtml(officer.full_name)}${officer.village ? ` · ${escapeHtml(officer.village)}` : ''}</option>
      `).join('');
    $('assigned-officer-id').value = item.assigned_officer_id || '';
    $('expected-date').value = item.expected_resolution_date
      ? item.expected_resolution_date.slice(0, 10)
      : '';
    $('detail-status').value = item.status;
    $('action-notes').value = item.action_notes || '';
    $('repair-evidence').value = item.repair_evidence_url || '';
    $('completion-date').value = item.completion_date
      ? new Date(item.completion_date).toISOString().slice(0, 16)
      : '';

    // Clear Work Order and Override inputs
    if ($('wo-reason')) $('wo-reason').value = '';
    if ($('wo-message')) $('wo-message').textContent = '';
    if ($('override-reason')) $('override-reason').value = '';
    if ($('override-message')) $('override-message').textContent = '';
    if ($('override-category')) $('override-category').value = '';
    if ($('override-severity')) $('override-severity').value = '';

    $('drawer-message').textContent = '';
    $('detail-drawer').classList.remove('hidden');
  } catch (error) {
    $('connection-status').textContent = error.message;
  }
}

// Work Order Action Handler (Accept, Reject, Reassign)
async function handleWorkOrder(action) {
  if (!state.selectedComplaintId) return;
  const reason = $('wo-reason')?.value || (action === 'accept' ? 'Work order accepted by ground crew' : 'Action taken by officer');
  const msgEl = $('wo-message');
  try {
    const payload = { action, reason };
    if (action === 'reassign') {
      payload.reassigned_department = $('assigned-department')?.value || null;
      payload.reassigned_officer_id = $('assigned-officer-id')?.value ? Number($('assigned-officer-id').value) : null;
    }
    await api(`/officer/complaints/${state.selectedComplaintId}/work-order`, {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    if (msgEl) msgEl.textContent = t('workOrderSuccess', 'Work order updated successfully.');
    await loadAll();
    await openDetail(state.selectedComplaintId);
  } catch (err) {
    if (msgEl) msgEl.textContent = 'Error: ' + err.message;
  }
}

// Officer AI Override Handler
async function handleAiOverride(event) {
  event.preventDefault();
  if (!state.selectedComplaintId) return;
  const msgEl = $('override-message');
  try {
    await api(`/officer/complaints/${state.selectedComplaintId}/ai-override`, {
      method: 'POST',
      body: JSON.stringify({
        corrected_category: $('override-category')?.value || null,
        corrected_severity: $('override-severity')?.value || null,
        override_reason: $('override-reason')?.value || 'Officer override'
      })
    });
    if (msgEl) msgEl.textContent = t('overrideSuccess', 'AI prediction corrected and recorded.');
    await loadAll();
    await openDetail(state.selectedComplaintId);
  } catch (err) {
    if (msgEl) msgEl.textContent = 'Override error: ' + err.message;
  }
}

// Wire Event Listeners
const registrationForm = $('officer-registration-form');
const showRegistrationButton = $('show-officer-registration');
if (showRegistrationButton && registrationForm) {
  showRegistrationButton.addEventListener('click', async () => {
    $('login-form').classList.add('hidden');
    showRegistrationButton.classList.add('hidden');
    registrationForm.classList.remove('hidden');
    const message = $('officer-registration-message');
    message.textContent = '';
    try {
      await loadRegistrationDistricts();
    } catch (error) {
      message.textContent = error.message;
    }
  });
}

const showLoginButton = $('show-officer-login');
if (showLoginButton && registrationForm) {
  showLoginButton.addEventListener('click', () => {
    registrationForm.classList.add('hidden');
    $('login-form').classList.remove('hidden');
    showRegistrationButton.classList.remove('hidden');
  });
}

const regOfficerDist = $('register-officer-district');
if (regOfficerDist) {
  regOfficerDist.addEventListener('change', async (event) => {
    const message = $('officer-registration-message');
    if (message) message.textContent = '';
    const dist = event.target.value;
    if (!dist) {
      const talukaEl = $('register-officer-taluka');
      if (talukaEl) {
        talukaEl.disabled = true;
        talukaEl.innerHTML = '<option value="">Select a district first</option>';
      }
      const villageEl = $('register-officer-village');
      if (villageEl) {
        villageEl.disabled = true;
        villageEl.innerHTML = '<option value="">Select a taluka first</option>';
      }
      return;
    }
    try {
      await loadRegistrationTalukas(dist);
    } catch (error) {
      if (message) message.textContent = error.message;
    }
  });
}

const regOfficerTaluka = $('register-officer-taluka');
if (regOfficerTaluka) {
  regOfficerTaluka.addEventListener('change', async (event) => {
    const message = $('officer-registration-message');
    if (message) message.textContent = '';
    const dist = $('register-officer-district')?.value || '';
    const taluka = event.target.value;
    if (!taluka) {
      const villageEl = $('register-officer-village');
      if (villageEl) {
        villageEl.disabled = true;
        villageEl.innerHTML = '<option value="">Select a taluka first</option>';
      }
      return;
    }
    try {
      await loadRegistrationVillages(dist, taluka);
    } catch (error) {
      if (message) message.textContent = error.message;
    }
  });
}

registrationForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const message = $('officer-registration-message');
  const submitButton = $('submit-officer-registration');
  message.textContent = '';
  submitButton.disabled = true;
  try {
    const response = await fetch('/auth/register-officer', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        full_name: $('register-officer-name').value.trim(),
        email: $('register-officer-email').value.trim(),
        password: $('register-officer-password').value,
        village_id: Number($('register-officer-village').value)
      })
    });
    const body = await response.json();
    if (!response.ok) {
      throw new Error(apiErrorMessage(body.detail, 'Officer registration failed'));
    }
    registrationForm.reset();
    $('register-officer-village').disabled = true;
    $('register-officer-village').innerHTML = '<option value="">Select a district first</option>';
    message.textContent = body.message;
  } catch (error) {
    message.textContent = error.message;
  } finally {
    submitButton.disabled = false;
  }
});

$('login-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  $('login-error').textContent = '';

  try {
    const result = await fetch('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: $('email').value,
        password: $('password').value
      })
    });

    const body = await result.json();

    if (!result.ok) {
      throw new Error(apiErrorMessage(body.detail, 'Login failed'));
    }

    if (!['village_officer', 'admin'].includes(body.user.role)) {
      throw new Error('Officer access required');
    }

    state.token = body.access_token;
    localStorage.setItem('officer_token', state.token);
    if (body.user) {
      localStorage.setItem('officer_user', JSON.stringify(body.user));
      if ($('officer-display-name')) $('officer-display-name').textContent = body.user.full_name || 'Village Officer';
      if ($('officer-display-email')) $('officer-display-email').textContent = body.user.email || 'officer@example.com';
    }
    loginView(true);
    await loadAll();
  } catch (error) {
    $('login-error').textContent = error.message;
  }
});

$('logout-button').addEventListener('click', logout);
const logoutProfileBtn = $('logout-button-profile');
if (logoutProfileBtn) logoutProfileBtn.addEventListener('click', logout);

document.addEventListener('click', (event) => {
  const approveButton = event.target instanceof Element
    ? event.target.closest('.approve-officer-button')
    : null;
  if (approveButton) {
    const officerId = approveButton.dataset.officerId;
    approveButton.disabled = true;
    api(`/auth/officers/${officerId}/approve`, { method: 'POST' })
      .then(() => loadPendingOfficers())
      .catch((error) => {
        const list = $('pending-officers-list');
        list.insertAdjacentHTML('afterbegin', `<p class="error">Approval failed: ${escapeHtml(error.message)}</p>`);
        approveButton.disabled = false;
      });
    return;
  }

  const button = event.target instanceof Element
    ? event.target.closest('[data-map-complaint-id]')
    : null;
  if (button) showComplaintOnMap(button.dataset.mapComplaintId);

  const complaintButton = event.target instanceof Element
    ? event.target.closest('[data-open-complaint-id]')
    : null;
  if (complaintButton) openDetail(Number(complaintButton.dataset.openComplaintId));
});

$('refresh-button').addEventListener('click', loadAll);
$('filter-button').addEventListener('click', applyFilters);

const resetComplaintFiltersBtn = $('reset-complaint-filters');
if (resetComplaintFiltersBtn) {
  resetComplaintFiltersBtn.addEventListener('click', () => {
    ['search-filter', 'category-filter', 'severity-filter', 'priority-filter', 'status-filter', 'department-filter', 'complaint-start-date', 'complaint-end-date'].forEach((id) => {
      const el = $(id);
      if (el) el.value = '';
    });
    const sortEl = $('complaint-sort');
    if (sortEl) sortEl.value = 'created_desc';
    state.complaintSort = 'created_desc';
    state.complaintPage = 1;
    applyFilters();
  });
}

const complaintSortEl = $('complaint-sort');
if (complaintSortEl) {
  complaintSortEl.addEventListener('change', (e) => {
    state.complaintSort = e.target.value;
    updateComplaintTable();
  });
}

const prevPageBtn = $('prev-page-btn');
if (prevPageBtn) {
  prevPageBtn.addEventListener('click', () => {
    if (state.complaintPage > 1) {
      state.complaintPage--;
      updateComplaintTable();
    }
  });
}

const nextPageBtn = $('next-page-btn');
if (nextPageBtn) {
  nextPageBtn.addEventListener('click', () => {
    state.complaintPage++;
    updateComplaintTable();
  });
}

const rowsPerPageEl = $('rows-per-page');
if (rowsPerPageEl) {
  rowsPerPageEl.addEventListener('change', (e) => {
    state.complaintPageSize = Number(e.target.value) || 10;
    state.complaintPage = 1;
    updateComplaintTable();
  });
}

// Decision buttons
const btnAccept = $('btn-accept-complaint');
if (btnAccept) btnAccept.addEventListener('click', handleAcceptComplaint);

const btnShowReject = $('btn-show-reject');
if (btnShowReject) {
  btnShowReject.addEventListener('click', () => {
    const box = $('reject-reason-box');
    if (box) box.classList.toggle('hidden');
    $('quick-reject-reason')?.focus();
  });
}

const btnConfirmReject = $('btn-confirm-reject');
if (btnConfirmReject) btnConfirmReject.addEventListener('click', handleRejectComplaint);

const btnCancelReject = $('btn-cancel-reject');
if (btnCancelReject) {
  btnCancelReject.addEventListener('click', () => {
    $('reject-reason-box')?.classList.add('hidden');
  });
}

// Bubble Chart Toggles
const btnBubbleCat = $('btn-bubble-cat');
const btnBubbleArea = $('btn-bubble-area');
if (btnBubbleCat && btnBubbleArea) {
  btnBubbleCat.addEventListener('click', () => {
    btnBubbleCat.classList.add('active');
    btnBubbleArea.classList.remove('active');
    analyticsState.bubbleMode = 'category';
    renderBubbleChart(analyticsState.data);
  });
  btnBubbleArea.addEventListener('click', () => {
    btnBubbleArea.classList.add('active');
    btnBubbleCat.classList.remove('active');
    analyticsState.bubbleMode = 'area';
    renderBubbleChart(analyticsState.data);
  });
}

// Analytics Department Filter
const aDeptFilter = $('analytics-dept-filter');
if (aDeptFilter) {
  aDeptFilter.addEventListener('change', (e) => {
    analyticsState.department = e.target.value;
    loadAdvancedAnalytics();
  });
}

const districtSelect = $('district-select');
if (districtSelect) {
  districtSelect.addEventListener('change', () => {
    state.selectedDistrict = districtSelect.value;
    state.selectedTaluka = '';
    state.selectedVillageId = '';
    renderVillageSelectors();
    loadAll();
  });
}

const talukaSelect = $('taluka-select');
if (talukaSelect) {
  talukaSelect.addEventListener('change', () => {
    state.selectedTaluka = talukaSelect.value;
    state.selectedVillageId = '';
    renderVillageSelectors();
    loadAll();
  });
}

const villageSelect = $('village-select');
if (villageSelect) {
  villageSelect.addEventListener('change', () => {
    state.selectedVillageId = villageSelect.value;
    const village = state.villages.find(
      (item) => String(item.id) === state.selectedVillageId
    );
    if (village) {
      state.selectedDistrict = village.district;
      state.selectedTaluka = village.taluka || '';
    }
    renderVillageSelectors();
    loadAll();
  });
}

const runEscalationBtn = $('run-escalation-button');
if (runEscalationBtn) runEscalationBtn.addEventListener('click', triggerEscalationCheck);

const viewReportBtn = $('view-report-button');
if (viewReportBtn) viewReportBtn.addEventListener('click', viewGovernanceReport);

const closeReportBtn = $('close-report-button');
if (closeReportBtn) closeReportBtn.addEventListener('click', () => $('report-view').classList.add('hidden'));

// CSV Exports & Print
const exportComplaintsBtn = $('export-complaints-csv-btn');
if (exportComplaintsBtn) {
  exportComplaintsBtn.addEventListener('click', () => downloadFile('/officer/reports/export-complaints-csv', 'village_complaints.csv'));
}

const exportGovBtn = $('export-gov-csv-btn');
if (exportGovBtn) {
  exportGovBtn.addEventListener('click', () => downloadFile('/officer/reports/export-governance-csv', 'governance_summary.csv'));
}

const printReportBtn = $('print-report-btn');
if (printReportBtn) {
  printReportBtn.addEventListener('click', () => window.print());
}

// Analytics Toolbar & Filter Listeners
const aStartDate = $('analytics-start-date');
if (aStartDate) {
  aStartDate.addEventListener('change', (e) => {
    analyticsState.startDate = e.target.value;
    loadAdvancedAnalytics();
  });
}

const aEndDate = $('analytics-end-date');
if (aEndDate) {
  aEndDate.addEventListener('change', (e) => {
    analyticsState.endDate = e.target.value;
    loadAdvancedAnalytics();
  });
}

const aCatFilter = $('analytics-cat-filter');
if (aCatFilter) {
  aCatFilter.addEventListener('change', (e) => {
    analyticsState.category = e.target.value;
    loadAdvancedAnalytics();
  });
}

const aStatusFilter = $('analytics-status-filter');
if (aStatusFilter) {
  aStatusFilter.addEventListener('change', (e) => {
    analyticsState.status = e.target.value;
    loadAdvancedAnalytics();
  });
}

const aAreaFilter = $('analytics-area-filter');
if (aAreaFilter) {
  aAreaFilter.addEventListener('change', (e) => {
    analyticsState.area = e.target.value;
    loadAdvancedAnalytics();
  });
}

const aResetBtn = $('reset-analytics-filters');
if (aResetBtn) {
  aResetBtn.addEventListener('click', () => {
    analyticsState.startDate = '';
    analyticsState.endDate = '';
    analyticsState.category = '';
    analyticsState.status = '';
    analyticsState.area = '';
    analyticsState.interval = 'day';

    if ($('analytics-start-date')) $('analytics-start-date').value = '';
    if ($('analytics-end-date')) $('analytics-end-date').value = '';
    if ($('analytics-cat-filter')) $('analytics-cat-filter').value = '';
    if ($('analytics-status-filter')) $('analytics-status-filter').value = '';
    if ($('analytics-area-filter')) $('analytics-area-filter').value = '';

    document.querySelectorAll('.interval-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.interval === 'day');
    });

    loadAdvancedAnalytics();
  });
}

// Analytics Trend Interval Buttons
document.querySelectorAll('.interval-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.interval-btn').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
    analyticsState.interval = btn.dataset.interval || 'day';
    loadAdvancedAnalytics();
  });
});

// Work Order Buttons
const btnWoAccept = $('btn-wo-accept');
if (btnWoAccept) btnWoAccept.addEventListener('click', () => handleWorkOrder('accept'));

const btnWoReject = $('btn-wo-reject');
if (btnWoReject) btnWoReject.addEventListener('click', () => handleWorkOrder('reject'));

const btnWoReassign = $('btn-wo-reassign');
if (btnWoReassign) btnWoReassign.addEventListener('click', () => handleWorkOrder('reassign'));

// AI Override Form
const aiOverrideForm = $('ai-override-form');
if (aiOverrideForm) aiOverrideForm.addEventListener('submit', handleAiOverride);

$('close-drawer').addEventListener('click', () =>
  $('detail-drawer').classList.add('hidden')
);

document.querySelectorAll('.sidebar nav .nav-link').forEach((link) => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    const page = link.dataset.page;
    if (page) navigateToPage(page);
  });
});

window.addEventListener('hashchange', () => {
  const hash = window.location.hash.replace('#', '').trim();
  if (hash && PAGE_CONFIG[hash]) {
    navigateToPage(hash, false);
  }
});

$('assignment-form').addEventListener('submit', async (event) => {
  event.preventDefault();

  try {
    await api(`/officer/complaints/${state.selectedComplaintId}/assignment`, {
      method: 'PATCH',
      body: JSON.stringify({
        assigned_department: $('assigned-department').value,
        assigned_officer_id: $('assigned-officer-id').value || null,
        expected_resolution_date: $('expected-date').value
          ? new Date($('expected-date').value).toISOString()
          : null
      })
    });

    $('drawer-message').textContent = 'Assignment saved.';
    await loadAll();
    await openDetail(state.selectedComplaintId);
  } catch (error) {
    $('drawer-message').textContent = error.message;
  }
});

$('status-form').addEventListener('submit', async (event) => {
  event.preventDefault();

  try {
    await api(`/officer/complaints/${state.selectedComplaintId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({
        status: $('detail-status').value,
        action_notes: $('action-notes').value || null,
        repair_evidence_url: $('repair-evidence').value || null,
        completion_date: $('completion-date').value
          ? new Date($('completion-date').value).toISOString()
          : null
      })
    });

    $('drawer-message').textContent = 'Case updated.';
    await loadAll();
    await openDetail(state.selectedComplaintId);
  } catch (error) {
    $('drawer-message').textContent = error.message;
  }
});

// Language selector listeners
['login-lang-select', 'topbar-lang-select', 'settings-lang-select'].forEach((id) => {
  const el = $(id);
  if (el) {
    el.addEventListener('change', (e) => setLanguage(e.target.value));
  }
});

const saveLangBtn = $('save-language-btn');
if (saveLangBtn) {
  saveLangBtn.addEventListener('click', () => {
    const selected = $('settings-lang-select')?.value || 'en';
    setLanguage(selected);
    const msg = $('language-saved-msg');
    if (msg) {
      msg.textContent = t('languageUpdated', 'Language preference saved.');
      setTimeout(() => { msg.textContent = ''; }, 3000);
    }
  });
}

const refreshPendingButton = $('refresh-pending-officers');
if (refreshPendingButton) {
  refreshPendingButton.addEventListener('click', loadPendingOfficers);
}

async function initApp() {
  applyTranslations(currentLanguage);

  const cachedUser = localStorage.getItem('officer_user');
  if (cachedUser) {
    try {
      const u = JSON.parse(cachedUser);
      if ($('officer-display-name')) $('officer-display-name').textContent = u.full_name || 'Village Officer';
      if ($('officer-display-email')) $('officer-display-email').textContent = u.email || 'officer@example.com';
      if ($('chip-officer-name')) $('chip-officer-name').textContent = u.full_name || 'Village Officer';
    } catch (_) {}
  }

  if (state.token) {
    loginView(true);
    const initialHash = window.location.hash.replace('#', '').trim();
    navigateToPage(PAGE_CONFIG[initialHash] ? initialHash : 'overview', false);
    await loadAll();
    return;
  }

  try {
    const email = $('email')?.value || 'officer@example.com';
    const password = $('password')?.value || 'change-this-password';
    const result = await fetch('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    if (result.ok) {
      const body = await result.json();
      if (['village_officer', 'admin'].includes(body.user?.role)) {
        state.token = body.access_token;
        localStorage.setItem('officer_token', state.token);
        if (body.user) {
          localStorage.setItem('officer_user', JSON.stringify(body.user));
          if ($('officer-display-name')) $('officer-display-name').textContent = body.user.full_name || 'Village Officer';
          if ($('officer-display-email')) $('officer-display-email').textContent = body.user.email || 'officer@example.com';
          if ($('chip-officer-name')) $('chip-officer-name').textContent = body.user.full_name || 'Village Officer';
        }
        loginView(true);
        const initialHash = window.location.hash.replace('#', '').trim();
        navigateToPage(PAGE_CONFIG[initialHash] ? initialHash : 'overview', false);
        await loadAll();
        return;
      }
    }
  } catch (e) {
    console.warn('Auto-login attempt:', e);
  }

  loginView(false);
}

initApp();
window.setInterval(() => {
  if (state.token && !document.hidden) loadAll();
}, 30000);
document.addEventListener('visibilitychange', () => {
  if (
    state.token &&
    !document.hidden &&
    Date.now() - lastDashboardRefreshAt >= 30000
  ) {
    loadAll();
  }
});

// Map return navigation listener
const returnComplaintBtn = $('return-to-complaint-btn');
if (returnComplaintBtn) {
  returnComplaintBtn.addEventListener('click', () => {
    const returnBar = $('map-return-bar');
    if (returnBar) returnBar.classList.add('hidden');
    const targetPage = state.returnFromPage || 'complaints';
    navigateToPage(targetPage);
    if (state.returnToComplaintId) {
      openDetail(state.returnToComplaintId);
    }
  });
}

window.openDetail = openDetail;
window.showComplaintOnMap = showComplaintOnMap;


async function fetchEvidenceBlob(url) {
  const evidenceUrl = new URL(url, window.location.origin);
  if (evidenceUrl.origin !== window.location.origin) {
    throw new Error(t('evidenceLoadFailed', 'Could not load evidence.'));
  }
  const response = await fetch(evidenceUrl, {
    headers: { Authorization: `Bearer ${state.token || localStorage.getItem('officer_token') || ''}` }
  });
  if (response.status === 401) logout();
  if (!response.ok) {
    throw new Error(t('evidenceLoadFailed', 'Could not load evidence.'));
  }
  return response.blob();
}

async function loadEvidencePreview(element) {
  try {
    const blob = await fetchEvidenceBlob(element.dataset.evidenceUrl);
    const objectUrl = URL.createObjectURL(blob);
    if (!element.isConnected) {
      URL.revokeObjectURL(objectUrl);
      return;
    }
    element.dataset.objectUrl = objectUrl;
    if (element instanceof HTMLSourceElement) {
      element.src = objectUrl;
      element.parentElement.load();
    } else {
      element.src = objectUrl;
    }
  } catch (error) {
    const preview = element.closest('.evidence-preview-wrap');
    if (preview) {
      preview.textContent = `${t('evidenceLoadFailed', 'Could not load evidence.')} ${error.message}`;
    }
  }
}

async function downloadEvidenceFile(url, filename) {
  try {
    const blob = await fetchEvidenceBlob(url);
    const objectUrl = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = objectUrl;
    anchor.download = filename || 'evidence';
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
  } catch (error) {
    showAlert('error', `${t('evidenceLoadFailed', 'Could not load evidence.')}: ${error.message}`);
  }
}

let lightboxObjectUrl = null;
let lightboxRequestId = 0;

// Evidence Lightbox Functions (SRS Feature 2)
window.openEvidenceLightbox = async function(imgUrl, caption, filename) {
  const modal = $('evidence-lightbox-modal');
  const img = $('lightbox-img');
  const title = $('lightbox-title');
  const details = $('lightbox-details');
  const downloadLink = $('lightbox-download-link');
  const externalLink = $('lightbox-external-link');
  if (!modal || !img) return;

  const requestId = ++lightboxRequestId;
  if (lightboxObjectUrl) URL.revokeObjectURL(lightboxObjectUrl);
  lightboxObjectUrl = null;
  img.removeAttribute('src');
  if (title) title.textContent = caption || 'Evidence Photo';
  if (details) details.textContent = filename || '';
  if (downloadLink) downloadLink.removeAttribute('href');
  if (externalLink) externalLink.removeAttribute('href');

  modal.classList.remove('hidden');
  modal.setAttribute('aria-hidden', 'false');
  document.body.style.overflow = 'hidden';
  try {
    const blob = await fetchEvidenceBlob(imgUrl);
    if (requestId !== lightboxRequestId) return;
    lightboxObjectUrl = URL.createObjectURL(blob);
    img.src = lightboxObjectUrl;
    if (downloadLink) {
      downloadLink.href = lightboxObjectUrl;
      downloadLink.download = filename || 'evidence_photo.jpg';
    }
    if (externalLink) externalLink.href = lightboxObjectUrl;
  } catch (error) {
    if (requestId === lightboxRequestId && details) {
      details.textContent = `${filename || ''} · ${error.message}`;
    }
  }
};

window.closeEvidenceLightbox = function() {
  lightboxRequestId++;
  const modal = $('evidence-lightbox-modal');
  if (!modal) return;
  modal.classList.add('hidden');
  modal.setAttribute('aria-hidden', 'true');
  document.body.style.overflow = '';
  if (lightboxObjectUrl) URL.revokeObjectURL(lightboxObjectUrl);
  lightboxObjectUrl = null;
  const img = $('lightbox-img');
  if (img) img.removeAttribute('src');
  $('lightbox-download-link')?.removeAttribute('href');
  $('lightbox-external-link')?.removeAttribute('href');
};

// Lightbox event bindings
const lbCloseBtn = $('lightbox-close-btn');
if (lbCloseBtn) lbCloseBtn.addEventListener('click', window.closeEvidenceLightbox);
const lbBackdrop = $('lightbox-backdrop');
if (lbBackdrop) lbBackdrop.addEventListener('click', window.closeEvidenceLightbox);
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    const modal = $('evidence-lightbox-modal');
    if (modal && !modal.classList.contains('hidden')) {
      window.closeEvidenceLightbox();
    }
  }
});
