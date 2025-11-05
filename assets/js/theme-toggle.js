(function(){
  // Implement a canonical setTheme on window that matches the homepage behavior.
  // This ensures pages (and their inline handlers) can call setTheme reliably.
  window.setTheme = function(t){
    try{
      // remove previous classes
      document.documentElement.classList.remove('light','dark');
      if(document.body && document.body.classList) document.body.classList.remove('light','dark');
      // apply the requested theme on both root and body to cover pages that target either selector
      if(t === 'light'){
        document.documentElement.classList.add('light');
        if(document.body && document.body.classList) document.body.classList.add('light');
      } else if(t === 'dark'){
        document.documentElement.classList.add('dark');
        if(document.body && document.body.classList) document.body.classList.add('dark');
      }
      // debug
      try{ console.debug && console.debug('setTheme ->', t); }catch(e){}
      try{ localStorage.setItem('theme', t); }catch(e){}
    }catch(e){}
  };

  function applyInitialTheme(){
    try{
      var saved = null;
      try{ saved = localStorage.getItem('theme'); }catch(e){}
      var defaultTheme = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
      window.setTheme(saved || defaultTheme);
    }catch(e){}
  }

  function attachHandler(){
    var btn = document.getElementById('theme');
    if(!btn) return;
    // Avoid duplicate bindings: remove any existing click handler we previously set using a namespaced property
    if(btn.__themeToggleInstalled) return; btn.__themeToggleInstalled = true;

    // Use capture so this handler runs before any page-level handlers and can stop them
    btn.addEventListener('click', function(e){
      try{ e && e.preventDefault && e.preventDefault(); }catch(e){}
      try{ e && e.stopImmediatePropagation && e.stopImmediatePropagation(); }catch(e){}
      // Determine current theme using localStorage if present (canonical),
      // otherwise fall back to class presence on <html>, then system preference.
      var stored = null;
      try{ stored = localStorage.getItem('theme'); }catch(err){}
      var cur;
      if(stored === 'light' || stored === 'dark'){
        cur = stored;
      } else if(document.documentElement.classList.contains('light')){
        cur = 'light';
      } else if(document.documentElement.classList.contains('dark')){
        cur = 'dark';
      } else {
        cur = (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) ? 'light' : 'dark';
      }
      var next = (cur === 'light') ? 'dark' : 'light';
      try{ console.debug && console.debug('theme-toggle: stored=', stored, 'cur=', cur, 'next=', next); }catch(e){}
      try{ window.setTheme(next); }catch(e){}
    }, true);
  }

  // Initialize immediately if DOM is ready, otherwise on DOMContentLoaded
  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', function(){ attachHandler(); applyInitialTheme(); initHeaderOffset(); });
  } else {
    attachHandler(); applyInitialTheme(); initHeaderOffset();
  }

  // Measure the header height and set a CSS variable so scroll-padding-top can
  // be dynamic and match the actual header size (works across mobile/desktop).
  function initHeaderOffset(){
    try{
      var header = document.querySelector('header');
      if(!header) return;
      var setVar = function(){
        try{
          var h = Math.ceil(header.getBoundingClientRect().height || header.offsetHeight || 0);
          // add a small extra gap so the section's start isn't flush against header
          var offset = h + 6;
          // set the CSS variable on both root and body to cover browsers that
          // treat the scrolling element differently.
          try{ document.documentElement.style.setProperty('--scroll-padding-top', offset + 'px'); }catch(e){}
          try{ document.body && document.body.style.setProperty('--scroll-padding-top', offset + 'px'); }catch(e){}
        }catch(e){}
      };
      // run once immediately
      setVar();
  // If there's a hash in the URL (direct link or back/forward), adjust scroll
  // so the target appears correctly under the header. Run after a short
  // timeout to allow the browser's native anchor jump first, then nudge.
  setTimeout(function(){ adjustScrollToHash(); }, 50);
      // update on resizes and orientation changes
      var resizeDebounce;
      window.addEventListener('resize', function(){ clearTimeout(resizeDebounce); resizeDebounce = setTimeout(setVar, 120); });
      window.addEventListener('orientationchange', function(){ setTimeout(setVar, 120); });
      // use a ResizeObserver to catch header content changes (safer than polling)
      if(window.ResizeObserver){
        try{
          var ro = new ResizeObserver(function(){ setVar(); });
          ro.observe(header);
        }catch(e){}
      }
    }catch(e){}
  }

  // Scroll adjustment fallback: if the browser doesn't honor scroll-padding-top
  // for anchor jumps, compute and perform a scroll to the element minus header.
  function adjustScrollToHash(){
    try{
      var hash = location.hash && location.hash.replace(/^#/, '');
      if(!hash) return;
      var el = document.getElementById(hash);
      if(!el) return;
      var header = document.querySelector('header');
      var h = header ? Math.ceil(header.getBoundingClientRect().height || header.offsetHeight || 0) : 0;
      var extra = 6;
      var top = el.getBoundingClientRect().top + window.scrollY - h - extra;
      window.scrollTo({ top: Math.max(0, Math.floor(top)), left: 0 });
    }catch(e){}
  }

  // Intercept nav anchor clicks (internal hashes) to perform the adjusted scroll
  // immediately instead of relying on the browser's native fragment jump.
  function interceptNavAnchors(){
    try{
      document.querySelectorAll('a[href^="#"]').forEach(function(a){
        a.addEventListener('click', function(ev){
          var href = a.getAttribute('href') || '';
          if(!href.startsWith('#')) return;
          var id = href.replace(/^#/, '');
          var target = document.getElementById(id);
          if(!target) return;
          ev.preventDefault();
          // update URL without jumping
          history.pushState(null, '', '#' + id);
          // perform adjusted scroll
          setTimeout(adjustScrollToHash, 0);
        });
      });
    }catch(e){}
  }

  // run interceptors once DOM ready
  try{ if(document.readyState === 'complete' || document.readyState === 'interactive') interceptNavAnchors(); else document.addEventListener('DOMContentLoaded', interceptNavAnchors); }catch(e){}

})();
