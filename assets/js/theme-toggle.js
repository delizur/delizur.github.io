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
    document.addEventListener('DOMContentLoaded', function(){ attachHandler(); applyInitialTheme(); });
  } else {
    attachHandler(); applyInitialTheme();
  }

})();
