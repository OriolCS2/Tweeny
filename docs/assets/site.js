/* Tweeny documentation site.
   Three small jobs, all progressive: nothing here is required to read the page.
     1. syntax colouring for the AngelScript samples
     2. a copy button on every code block
     3. the sidebar tracking which section you are reading, and collapsing on narrow screens */
(function () {
  "use strict";

  // ---- syntax colouring ----------------------------------------------------------------------------
  // Deliberately a tokeniser rather than a set of regex passes over HTML: colouring by replacing text in
  // already-escaped markup is how highlighters end up painting the inside of strings and comments.

  var KEYWORDS = /^(?:void|bool|int|int8|int16|int64|uint|uint8|uint16|uint64|float|double|string|array|const|class|interface|enum|namespace|using|return|if|else|for|while|do|break|continue|switch|case|default|new|null|true|false|this|cast|funcdef|mixin|shared|abstract|final|override|private|protected|auto|in|out|inout|is|not|and|or|xor)$/;
  var TYPES = /^(?:Tweeny|Ease|EaseFactory|EaseManager|LoopType|UpdateType|RotateMode|ScrambleMode|PathType|PathMode|AxisConstraint|LinkBehaviour|TweenSequence|ITween|TweenFloat|TweenInt|TweenVector2|TweenVector3|TweenColor|TweenAngle|TweenRect|TweenString|TweenPath|TweenyAnimation|TweenCallback|TweenCallbackInt|TweenCallbackFloat|EaseFunc|FloatGetter|FloatSetter|IntGetter|IntSetter|Vector2Getter|Vector2Setter|Vector3Getter|Vector3Setter|ColorGetter|ColorSetter|RectGetter|RectSetter|StringGetter|StringSetter|Vector2|Vector3|Vector4|Color|Rectf|Transform|Entity|Behaviour|CometBehaviour|Camera|SpriteRenderer|TextureRectRenderer|AudioSource|Material|Time|Debug|Math)$/;

  function escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function span(cls, text) {
    return '<span class="tok-' + cls + '">' + escapeHtml(text) + "</span>";
  }

  function highlight(source) {
    var out = "";
    var i = 0;
    while (i < source.length) {
      var rest = source.slice(i);

      var comment = /^\/\/[^\n]*/.exec(rest);
      if (comment) { out += span("com", comment[0]); i += comment[0].length; continue; }

      var block = /^\/\*[\s\S]*?\*\//.exec(rest);
      if (block) { out += span("com", block[0]); i += block[0].length; continue; }

      var str = /^"(?:[^"\\]|\\.)*"/.exec(rest) || /^'(?:[^'\\]|\\.)*'/.exec(rest);
      if (str) { out += span("str", str[0]); i += str[0].length; continue; }

      var num = /^\b\d[\d._]*f?\b/.exec(rest);
      if (num) { out += span("num", num[0]); i += num[0].length; continue; }

      var word = /^[A-Za-z_][A-Za-z0-9_]*/.exec(rest);
      if (word) {
        var w = word[0];
        if (KEYWORDS.test(w)) { out += span("key", w); }
        else if (TYPES.test(w)) { out += span("type", w); }
        else { out += escapeHtml(w); }
        i += w.length;
        continue;
      }

      out += escapeHtml(source[i]);
      i += 1;
    }
    return out;
  }

  document.querySelectorAll("pre > code, td.api").forEach(function (node) {
    if (node.dataset.raw === "off") { return; }
    node.innerHTML = highlight(node.textContent);
  });

  // ---- copy buttons --------------------------------------------------------------------------------

  document.querySelectorAll(".code").forEach(function (block) {
    var button = block.querySelector(".copy");
    var code = block.querySelector("code");
    if (!button || !code) { return; }
    button.addEventListener("click", function () {
      var text = code.textContent;
      var done = function () {
        var was = button.textContent;
        button.textContent = "Copied";
        setTimeout(function () { button.textContent = was; }, 1400);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, function () {});
        return;
      }
      // Older browsers, and any context where the async clipboard is blocked.
      var scratch = document.createElement("textarea");
      scratch.value = text;
      scratch.setAttribute("readonly", "");
      scratch.style.position = "fixed";
      scratch.style.opacity = "0";
      document.body.appendChild(scratch);
      scratch.select();
      try { document.execCommand("copy"); done(); } catch (error) { /* nothing useful to do */ }
      document.body.removeChild(scratch);
    });
  });

  // ---- sidebar -------------------------------------------------------------------------------------

  var sidebar = document.querySelector(".sidebar");
  var toggle = document.querySelector(".navtoggle");
  var narrow = window.matchMedia("(max-width: 60rem)");

  function applyWidth() {
    if (!sidebar) { return; }
    sidebar.hidden = narrow.matches;
    if (toggle) { toggle.setAttribute("aria-expanded", String(!narrow.matches)); }
  }
  applyWidth();
  if (narrow.addEventListener) { narrow.addEventListener("change", applyWidth); }

  if (toggle && sidebar) {
    toggle.addEventListener("click", function () {
      sidebar.hidden = !sidebar.hidden;
      toggle.setAttribute("aria-expanded", String(!sidebar.hidden));
    });
    sidebar.addEventListener("click", function (event) {
      if (event.target.tagName === "A" && narrow.matches) { sidebar.hidden = true; }
    });
  }

  // Highlight whichever section is currently on screen. Bottom-of-page sections would otherwise never
  // become current, because they cannot reach the top of the viewport.
  var links = Array.prototype.slice.call(document.querySelectorAll(".sidebar a[href^='#']"));
  if (links.length && "IntersectionObserver" in window) {
    var byId = {};
    var targets = [];
    links.forEach(function (link) {
      var section = document.getElementById(decodeURIComponent(link.hash.slice(1)));
      if (section) { byId[section.id] = link; targets.push(section); }
    });

    var visible = {};
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        visible[entry.target.id] = entry.isIntersecting;
      });
      var current = null;
      for (var n = 0; n < targets.length; n++) {
        if (visible[targets[n].id]) { current = targets[n].id; break; }
      }
      if (!current) { return; }
      links.forEach(function (link) { link.classList.remove("active"); });
      if (byId[current]) { byId[current].classList.add("active"); }
    }, { rootMargin: "-4rem 0px -70% 0px", threshold: 0 });

    targets.forEach(function (section) { observer.observe(section); });
  }

  // ---- heading anchors -----------------------------------------------------------------------------

  document.querySelectorAll("main h2[id], main h3[id]").forEach(function (heading) {
    var link = document.createElement("a");
    link.className = "anchor";
    link.href = "#" + heading.id;
    link.textContent = "#";
    link.setAttribute("aria-label", "Link to this section");
    heading.appendChild(link);
  });
})();
