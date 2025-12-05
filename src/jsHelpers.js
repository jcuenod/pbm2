// Get the base URL from Vite's environment
const BASE_URL = import.meta.env.BASE_URL || '/'

export function getPath() {
  if (typeof window === 'undefined') return '/r/'
  const pathname = window.location.pathname
  // Strip the base URL from the pathname
  if (pathname.startsWith(BASE_URL)) {
    return pathname.slice(BASE_URL.length - 1) // Keep the leading slash
  }
  return pathname
}

export function getLocalStorage(key) {
  if (typeof window === 'undefined' || !window.localStorage) return null
  return window.localStorage.getItem(key)
}

export function setLocalStorage(key, value) {
  if (typeof window === 'undefined' || !window.localStorage) return
  window.localStorage.setItem(key, value)
}

export function replaceHistory(path) {
  if (typeof history !== 'undefined' && history.replaceState) {
    // Prepend the base URL to the path
    const fullPath = BASE_URL === '/' ? path : BASE_URL.slice(0, -1) + path
    history.replaceState(null, '', fullPath)
  }
}

export function getScrollTop(e) {
  try {
    return e.currentTarget ? e.currentTarget.scrollTop : 0
  } catch (err) {
    return 0
  }
}

export function setTransform(el, value) {
  if (!el) return
  try {
    el.style.transform = value
  } catch (err) {}
}

export function setHtmlDark(dark) {
  if (typeof document === 'undefined') return
  document.querySelector("html").classList.toggle("dark", dark)
}

export function setTransformBySelector(selector, value) {
  if (typeof document === 'undefined') return
  const el = document.querySelector(selector)
  if (!el) return
  try { el.style.transform = value } catch (e) {}
}
export function setTransitionBySelector(selector, value) {
  if (typeof document === 'undefined') return
  const el = document.querySelector(selector)
  if (!el) return
  try { el.style.transition = value } catch (e) {}
}
export function addBodyClass(c) { document.body.classList.add(c); }
export function removeBodyClass(c) { document.body.classList.remove(c); }
export function replaceState(path) { history.replaceState(null, '', path); }
export function localStorageGet(k) { return window.localStorage.getItem(k); }
export function localStorageSet(k, v) { window.localStorage.setItem(k, v); }

// Attach simple swipe handling to the element selected by `selector`.
// `cb` is a JS function that will be called with objects:
// { type: 'move', dx } during pointer move, and { type: 'end', dir } on end where dir is -1|0|1.
// Returns a cleanup function.
export function attachSwipe(selector, cb) {
  if (typeof document === 'undefined') return () => {}
  const el = document.querySelector(selector)
  if (!el) return () => {}

  let startX = null

  function onPointerDown(e) {
    startX = e.clientX || (e.touches && e.touches[0] && e.touches[0].clientX) || 0
    el.setPointerCapture && el.setPointerCapture(e.pointerId)
  }

  function onPointerMove(e) {
    if (startX == null) return
    const x = e.clientX || (e.touches && e.touches[0] && e.touches[0].clientX) || 0
    const dx = x - startX
    try { cb({type: 'move', dx}) } catch (err) {}
  }

  function onPointerUp(e) {
    if (startX == null) return
    const x = e.clientX || (e.changedTouches && e.changedTouches[0] && e.changedTouches[0].clientX) || 0
    const dx = x - startX
    const threshold = (window.innerWidth || 1) * 0.15
    const dir = dx > threshold ? -1 : dx < -threshold ? 1 : 0
    startX = null
    try { cb({type: 'end', dir}) } catch (err) {}
  }

  el.addEventListener('pointerdown', onPointerDown)
  el.addEventListener('pointermove', onPointerMove)
  window.addEventListener('pointerup', onPointerUp)
  // fallback for touch
  el.addEventListener('touchstart', onPointerDown)
  el.addEventListener('touchmove', onPointerMove)
  window.addEventListener('touchend', onPointerUp)

  return function cleanup() {
    try {
      el.removeEventListener('pointerdown', onPointerDown)
      el.removeEventListener('pointermove', onPointerMove)
      window.removeEventListener('pointerup', onPointerUp)
      el.removeEventListener('touchstart', onPointerDown)
      el.removeEventListener('touchmove', onPointerMove)
      window.removeEventListener('touchend', onPointerUp)
    } catch (e) {}
  }
}

export function setOpacityBySelector(selector, value) {
  if (typeof document === 'undefined') return
  const el = document.querySelector(selector)
  if (!el) return
  try { el.style.opacity = value } catch (e) {}
}
