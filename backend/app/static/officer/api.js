const apiErrorMessage = (detail, fallback) => {
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
};

const api = async (path, options = {}) => {
  const token = window.OfficerAuth?.getToken?.();
  const response = await fetch(path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    }
  });

  const body = await response.json().catch(() => ({}));

  if (response.status === 401) {
    window.OfficerAuth?.logout?.();
  }

  if (!response.ok) {
    throw new Error(apiErrorMessage(body.detail, `Request failed (${response.status})`));
  }

  return body;
};

window.OfficerAPI = {
  api,
  apiErrorMessage
};
