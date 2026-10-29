// ==========================================================================
// RARFlow Interactive Simulator & Website Logic
// ==========================================================================

document.addEventListener("DOMContentLoaded", () => {
  // 1. Copy CLI command button
  const copyBtn = document.getElementById("copy-cmd-btn");
  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      const textToCopy = "git clone https://github.com/Saleharoud/RARFlow.git";
      navigator.clipboard.writeText(textToCopy).then(() => {
        const copyTextSpan = copyBtn.querySelector(".copy-text");
        if (copyTextSpan) {
          copyTextSpan.textContent = "Copied!";
          setTimeout(() => {
            copyTextSpan.textContent = "Copy";
          }, 2000);
        }
      });
    });
  }

  // 2. Interactive Simulator Tab Switching
  const tabs = document.querySelectorAll(".sim-tab");
  const views = document.querySelectorAll(".sim-view");

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((t) => t.classList.remove("active"));
      views.forEach((v) => v.classList.remove("active"));

      tab.classList.add("active");
      const mode = tab.dataset.mode;
      const targetView = document.getElementById(`view-${mode}`);
      if (targetView) {
        targetView.classList.add("active");
      }
    });
  });

  // 3. Simulated Extraction Animation
  const extractBtn = document.getElementById("sim-btn-extract");
  const progressOverlay = document.getElementById("sim-extract-progress");
  const progressFill = document.getElementById("sim-fill");
  const pctText = document.getElementById("sim-pct-text");
  const fileText = document.getElementById("sim-file-text");

  const simulatedFiles = [
    "Decompressing project_manifest.json...",
    "Extracting high_res_master.psd (1.4 GB)...",
    "Verifying CRC32 checksums (D84A92F1)...",
    "Extracting trailer_audio_master.flac...",
    "Revealing extracted folder in Finder..."
  ];

  if (extractBtn && progressOverlay && progressFill) {
    extractBtn.addEventListener("click", () => {
      progressOverlay.classList.remove("hidden");
      let currentPct = 0;
      let fileIndex = 0;

      const interval = setInterval(() => {
        currentPct += 2;
        progressFill.style.width = `${currentPct}%`;
        pctText.textContent = `${currentPct}%`;

        if (currentPct % 20 === 0 && fileIndex < simulatedFiles.length) {
          fileText.textContent = simulatedFiles[fileIndex];
          fileIndex++;
        }

        if (currentPct >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            progressOverlay.classList.add("hidden");
            progressFill.style.width = "0%";
            pctText.textContent = "0%";
            fileText.textContent = simulatedFiles[0];
          }, 800);
        }
      }, 35);
    });
  }

  // 4. Smooth Anchor Scrolling Offset
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      const targetId = this.getAttribute("href");
      if (targetId === "#") return;
      const target = document.querySelector(targetId);
      if (target) {
        e.preventDefault();
        const headerOffset = 70;
        const elementPosition = target.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

        window.scrollTo({
          top: offsetPosition,
          behavior: "smooth"
        });
      }
    });
  });
});
