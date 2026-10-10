// iOS 27 audio unlock + clean TTS playback bootstrap (Open WebUI build 0.11.4, chunk DUmjoMyK.js)
// Appendato alla fine del chunk. Richiede anche 4 micro-edit nel codice del chunk (vedi README.md).
(() => {
  try {
    const mk = () => { // silent WAV ~100ms @44100Hz
      const n = 4410, b = new Uint8Array(44 + n * 2), v = new DataView(b.buffer);
      b.set([82,73,70,70],0); v.setUint32(4,36+n*2,true); b.set([87,65,86,69],8); b.set([102,109,116,32],12);
      v.setUint32(16,16,true); v.setUint16(20,1,true); v.setUint16(22,1,true); v.setUint32(24,44100,true);
      v.setUint32(28,88200,true); v.setUint16(32,2,true); v.setUint16(34,16,true); b.set([100,97,116,97],40);
      v.setUint32(44,n*2,true); return new Blob([b],{type:"audio/wav"});
    };
    const U = el => {
      try {
        const c = window.__owCtx = window.__owCtx || new (window.AudioContext || window.webkitAudioContext)();
        c.resume().catch(()=>{});
        if (el) { el.muted = true; el.src = URL.createObjectURL(mk()); el.play().catch(()=>{}); }
        setTimeout(()=>{ try { c.resume().catch(()=>{}); } catch(e){} }, 120);
      } catch(e){}
    };
    window.__owUnlock = U;
    window.addEventListener("touchend", () => U(document.getElementById("audioElement")), { once: true });
    window.addEventListener("click", () => U(document.getElementById("audioElement")), { once: true });
  } catch(e){}
})();
