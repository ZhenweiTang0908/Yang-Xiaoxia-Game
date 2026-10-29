(() => {
  const characters = window.BOSS_CATALOG;
  const list = document.getElementById("roster-list");
  const detail = document.getElementById("detail");
  const root = "../../";
  const spriteCache = new Map();
  const keyedFrames = new Map();
  const escape = (value) => String(value).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  let selected = characters[0].id;
  let activeAudio = null;

  function artType(id) {
    if (["lantern", "duelist", "priest"].includes(id)) return "boss-atlas";
    if (id === "knight") return "knight";
    if (id === "lion_elder") return "lion";
    return "bull";
  }

  function frameInfo(character, moveId) {
    const type = artType(character.id);
    if (type === "boss-atlas") return { type, src: `${root}assets/art/v2/bosses.png`, frames: [0, 1, 2, 3, 2, 1], still: 3, cols: 6, rows: 3, row: { lantern: 0, duelist: 1, priest: 2 }[character.id] };
    if (type === "knight") {
      const mounted = ["charge", "double_charge", "halt_thrust", "trample", "rein", "rear", "kick", "butt"].includes(moveId);
      const bank = mounted ? "mounted" : "foot", count = mounted ? 12 : 10;
      return { type, srcs: Array.from({ length: count }, (_, i) => `${root}assets/art/knight_frames/${bank}/${String(i).padStart(2, "0")}.png`), frames: Array.from({ length: count }, (_, i) => i), still: 3 };
    }
    if (type === "lion") {
      const bank = /sweep|kick|palm|handstand|twist|roll|finale/.test(moveId) ? "sweep" : /sleep|back|sit|ground/.test(moveId) ? "backfall" : "lion";
      const count = 16;
      return { type, srcs: Array.from({ length: count }, (_, i) => `${root}assets/art/lion_elder_frames/${bank}/${String(i).padStart(2, "0")}.png`), frames: Array.from({ length: count }, (_, i) => i), still: 8 };
    }
    return { type, src: `${root}assets/art/v3/bull.png`, frames: [0, 1, 2, 3, 4, 5, 6, 7], still: moveId === "idle" ? 0 : 3, cols: 4, rows: 2 };
  }

  function spriteFor(source) {
    let image = spriteCache.get(source);
    if (!image) { image = new Image(); image.src = source; spriteCache.set(source, image); }
    return image;
  }

  function loadSprite(source) {
    const image = spriteFor(source);
    if (image.complete) return image.naturalWidth ? Promise.resolve(image) : Promise.reject(new Error(`无法加载动作素材：${source}`));
    return new Promise((resolve, reject) => {
      image.addEventListener("load", () => resolve(image), { once: true });
      image.addEventListener("error", () => reject(new Error(`无法加载动作素材：${source}`)), { once: true });
    });
  }

  function drawPreview(canvas, character, moveId = "idle", step = null) {
    const ctx = canvas.getContext("2d");
    const w = canvas.width, h = canvas.height;
    const info = frameInfo(character, moveId);
    const frame = step === null ? info.still : info.frames[step % info.frames.length];
    const source = info.srcs ? info.srcs[frame] : info.src;
    ctx.clearRect(0, 0, w, h);
    const img = spriteFor(source);
    if (!img.complete || !img.naturalWidth) {
      if (canvas._pendingSource !== source) {
        canvas._pendingSource = source;
        img.addEventListener("load", () => { if (canvas.isConnected && canvas._pendingSource === source) drawPreview(canvas, character, moveId, step); }, { once: true });
      }
      return;
    }
    const cols = info.cols || 1, rows = info.rows || 1;
    const cell = info.type === "boss-atlas" ? info.row * cols + frame : frame;
    const sw = img.naturalWidth / cols, sh = img.naturalHeight / rows;
    const sx = (cell % cols) * sw, sy = Math.floor(cell / cols) * sh;
    const scale = Math.min((w * .76) / sw, (h * .9) / sh);
    const dw = sw * scale, dh = sh * scale;
    const dx = (w - dw) / 2, dy = (h - dh) / 2;
    if (info.type !== "bull") { ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh); return; }
    {
      const key = `${source}:${cell}`;
      let off = keyedFrames.get(key);
      if (!off) {
        off = document.createElement("canvas"); off.width = sw; off.height = sh;
        const offCtx = off.getContext("2d", { willReadFrequently: true });
        offCtx.drawImage(img, sx, sy, sw, sh, 0, 0, sw, sh);
        const pixels = offCtx.getImageData(0, 0, sw, sh);
        for (let i = 0; i < pixels.data.length; i += 4) {
          const r = pixels.data[i], g = pixels.data[i + 1], b = pixels.data[i + 2];
          if (r > 170 && b > 150 && g < 95) pixels.data[i + 3] = 0;
        }
        offCtx.putImageData(pixels, 0, 0);
        keyedFrames.set(key, off);
      }
      ctx.drawImage(off, dx, dy, dw, dh);
    }
  }

  function activatePreviews() {
    detail.querySelectorAll("canvas[data-character]").forEach((canvas) => drawPreview(canvas, characters.find((item) => item.id === canvas.dataset.character), canvas.dataset.move || "idle"));
    detail.querySelectorAll("[data-preview]").forEach((button) => button.addEventListener("click", () => {
      const canvas = button.parentElement.querySelector("canvas");
      const character = characters.find((item) => item.id === canvas.dataset.character);
      const frames = frameInfo(character, canvas.dataset.move || "idle").frames;
      let index = 0;
      const info = frameInfo(character, canvas.dataset.move || "idle");
      button.disabled = true;
      button.textContent = "准备动作";
      const sources = info.srcs || [info.src];
      Promise.all(sources.map(loadSprite)).then(() => {
        if (!canvas.isConnected) return;
        button.textContent = "动作播放中";
        const playNext = () => {
          drawPreview(canvas, character, canvas.dataset.move || "idle", index++);
          if (index < frames.length) button._timer = setTimeout(playNext, 220);
          else button._timer = setTimeout(() => { drawPreview(canvas, character, canvas.dataset.move || "idle"); button.disabled = false; button.textContent = "▶ 看动作"; }, 220);
        };
        playNext();
      }).catch(() => { button.disabled = false; button.textContent = "动作素材缺失"; });
    }));
  }

  function rosterArt(character) {
    if (["lantern", "duelist", "priest"].includes(character.id)) {
      const row = { lantern: 0, duelist: 1, priest: 2 }[character.id];
      return `background-image:url('${root}assets/art/v2/bosses.png');background-size:600% 300%;background-position:0 ${row * 50}%`;
    }
    if (character.id === "bull") return `background-image:url('${root}assets/art/v3/bull.png');background-size:400% 200%;background-position:0 0`;
    return `background-image:url('${root}${character.image}')`;
  }

  function renderRoster() {
    list.innerHTML = characters.map((character) => `<button class="roster-item" type="button" data-id="${character.id}" aria-current="${character.id === selected}"><span class="roster-art" style="${rosterArt(character)}"></span><span><strong>${escape(character.name)}</strong><small>${escape(character.kind)}</small></span></button>`).join("");
    list.querySelectorAll("[data-id]").forEach((button) => button.addEventListener("click", () => { selected = button.dataset.id; render(); }));
  }

  function quotePanel(character, moveId, dialogue, voiceKeys) {
    const event = moveId;
    if (character.id === "bull") return `<div class="voice-line"><span class="voice-label">台词</span><p>无台词（牛大侠没有 AI 配音）</p></div>`;
    const speaker = character.id === "lion_elder" ? "lion" : character.id;
    const candidates = [event, `${event}_b`, `${event}_c`].map((variant) => `${speaker}_${variant}`).filter((key) => voiceKeys.has(key));
    const lines = candidates.map((key) => {
      const eventId = key.slice(speaker.length + 1);
      const text = dialogue.bosses?.[speaker]?.lines?.[eventId] || "";
      return text ? `<div class="quote-row"><p>“${escape(text)}”</p><button class="play-voice" type="button" data-audio="${escape(`${root}assets/voice/ai/${key}.wav`)}" aria-label="播放 AI 配音">▶</button></div>` : "";
    }).join("");
    return `<div class="voice-line"><span class="voice-label">AI 台词</span>${lines || '<p class="no-voice">此招未配置专属台词 / AI 录音</p>'}</div>`;
  }

  function eventVoicePanel(character, dialogue, voiceKeys) {
    const speaker = character.id === "lion_elder" ? "lion" : character.id;
    const labels = {
      intro: "出场", phase_2: "第二阶段", phase_3: "第三阶段", low: "濒危",
      death: "战败", defeat: "战败", ally_enter: "伙伴登场", foot: "步战",
      dismount: "下马", stagger: "受击", seal: "封锁葫芦",
      soul_legion: "亡灵军团", soul_eagle_burst: "紫鹰出击", ancient_spear: "镇魂枪",
      spear_chain: "刺进连挑", dragon_sweep: "蛟龙扫阵", dragon_rise: "伏龙旋挑",
      dragon_break: "龙王破阵", spin_rush: "旋枪破阵", spear_return: "回锋掷矛",
      triple_dash: "三折追刺", bow_double: "退步双矢", bow_volley: "追猎三矢",
      spear_slam: "踏进重挑", kick_thrust: "蹬踢接刺"
    };
    const skillIds = new Set(character.moves.map(([id]) => id));
    const events = (character.voices || []).filter((event) => !skillIds.has(event));
    if (character.id === "bull") {
      return `<div class="section-heading"><h2>战斗语音</h2></div><p class="no-event-voice">牛大侠目前只有牛鸣游戏音效，没有 AI 台词配音。</p>`;
    }
    const rows = events.map((event) => {
      const keys = [event, `${event}_b`, `${event}_c`].map((variant) => `${speaker}_${variant}`).filter((key) => voiceKeys.has(key));
      const lines = keys.map((key) => {
        const variant = key.slice(speaker.length + 1);
        const text = dialogue.bosses?.[speaker]?.lines?.[variant];
        if (!text) return "";
        const suffix = variant.endsWith("_b") ? "B" : variant.endsWith("_c") ? "C" : "A";
        return `<div class="event-quote"><span class="voice-variant">${suffix}</span><p>“${escape(text)}”</p><button class="play-voice" type="button" data-audio="${escape(`${root}assets/voice/ai/${key}.wav`)}" aria-label="播放 AI 配音">▶</button></div>`;
      }).join("");
      if (!lines) return "";
      const skill = character.moves.find(([id]) => id === event);
      return `<article class="event-voice"><strong>${escape(labels[event] || skill?.[1] || event.replaceAll("_", " "))}</strong><div class="event-quotes">${lines}</div></article>`;
    }).join("");
    return `<div class="section-heading voice-heading"><h2>出场与战斗语音</h2><span>AI 配音 · 台词原文</span></div><div class="event-voice-list">${rows || '<p class="no-event-voice">暂无其他 AI 语音。</p>'}</div>`;
  }

  function moveCard(character, move, dialogue, voiceKeys) {
    const [id, name, damage, windup, recovery, description] = move;
    const metrics = [damage !== "—" ? `伤害 ${damage}` : "", windup !== "—" ? `预备 ${windup}s` : "", recovery !== "—" ? `收招 ${recovery}s` : ""].filter(Boolean).join("　·　");
    return `<section class="skill-card"><div class="skill-art"><canvas class="skill-preview" width="160" height="112" data-character="${character.id}" data-move="${id}" aria-label="${escape(name)}动作预览"></canvas><button class="preview-play" type="button" data-preview>▶ 看动作</button></div><div class="skill-copy"><div class="skill-title"><h3>${escape(name)}</h3><span>${escape(metrics || "辅助招式")}</span></div><p class="skill-description">${escape(description)}</p>${quotePanel(character, id, dialogue, voiceKeys)}</div></section>`;
  }

  function statCards(character) {
    return (character.stats || []).map(([name, value]) => `<div class="stat"><span>${escape(name)}</span><strong>${escape(value)}</strong></div>`).join("");
  }

  function modelImages(character) {
    if (!character.imageOptions || !["knight"].includes(character.id)) return "";
    return `<div class="model-images" aria-label="其他建模图像">${character.imageOptions.map((src) => `<figure><img src="${escape(`${root}${src}`)}" alt="${escape(src.split("/").at(-2))}" loading="lazy"><figcaption>${escape(src.split("/").at(-2))}</figcaption></figure>`).join("")}</div>`;
  }

  function render() {
    renderRoster();
    const character = characters.find((item) => item.id === selected);
    if (!character) return;
    const dialogue = window.BOSS_DIALOGUE;
    const voiceKeys = window.BOSS_AI_VOICE_KEYS;
    const portraitMove = character.id === "knight" ? "charge" : "idle";
    const sprite = `<canvas class="profile-preview" width="160" height="120" data-character="${character.id}" data-move="${portraitMove}" aria-label="${escape(character.name)}透明底造型"></canvas>`;
    const hp = character.stats?.find(([label]) => /生命/.test(label))?.[1] || character.hp.toLocaleString("zh-CN");
    detail.innerHTML = `<header class="profile">${sprite}<div class="profile-copy"><div class="eyebrow">${escape(character.kind)}</div><h1>${escape(character.name)}</h1><p>${escape(character.role)} <span>·</span> 生命 ${escape(hp)}</p><p class="phase">阶段：${escape(character.phases)}</p></div></header><p class="description">${escape(character.description)}</p><div class="stats">${statCards(character)}</div>${modelImages(character)}<div class="summon"><strong>召唤 / 特殊单位</strong><span>${escape(character.summon)}</span></div>${eventVoicePanel(character, dialogue, voiceKeys)}<div class="section-heading"><h2>攻击技能</h2><span>${character.moves.length} 招</span></div><div class="skill-list">${character.moves.map((move) => moveCard(character, move, dialogue, voiceKeys)).join("")}</div>`;
    detail.querySelectorAll("[data-audio]").forEach((button) => button.addEventListener("click", () => {
      if (activeAudio) { activeAudio.pause(); activeAudio = null; }
      const audio = new Audio(button.dataset.audio); activeAudio = audio; button.textContent = "Ⅱ";
      const reset = () => { button.textContent = "▶"; if (activeAudio === audio) activeAudio = null; };
      audio.addEventListener("ended", reset, { once: true });
      audio.addEventListener("error", reset, { once: true });
      audio.play().catch(reset);
    }));
    activatePreviews();
  }
  render();
})();
