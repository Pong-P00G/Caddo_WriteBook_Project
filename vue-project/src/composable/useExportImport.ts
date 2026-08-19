import { ref } from "vue";
import type { Note } from "../store/types/interface";

export function useExportImport() {
  const isExporting = ref(false);
  const isImporting = ref(false);

  // ── Helper: Parse Tiptap JSON to Plain Text / Markdown ────────────────────
  function tiptapToMarkdown(content: string, title: string): string {
    if (!content) return `# ${title}\n\n`;
    try {
      const doc = JSON.parse(content);
      let md = `# ${title}\n\n`;

      function processNode(node: any): string {
        if (!node) return "";
        if (node.type === "text") {
          let text = node.text || "";
          if (node.marks) {
            for (const mark of node.marks) {
              if (mark.type === "bold") text = `**${text}**`;
              if (mark.type === "italic") text = `*${text}*`;
              if (mark.type === "strike") text = `~~${text}~~`;
              if (mark.type === "code") text = `\`${text}\``;
              if (mark.type === "link") text = `[${text}](${mark.attrs?.href || "#"})`;
            }
          }
          return text;
        }

        const inner = (node.content || []).map(processNode).join("");

        switch (node.type) {
          case "paragraph":
            return `${inner}\n\n`;
          case "heading": {
            const level = node.attrs?.level || 1;
            const hashes = "#".repeat(level);
            return `${hashes} ${inner}\n\n`;
          }
          case "bulletList":
            return `${inner}\n`;
          case "orderedList":
            return `${inner}\n`;
          case "listItem":
            return `* ${inner.trim()}\n`;
          case "taskList":
            return `${inner}\n`;
          case "taskItem": {
            const checked = node.attrs?.checked ? "[x]" : "[ ]";
            return `${checked} ${inner.trim()}\n`;
          }
          case "blockquote":
            return `> ${inner.trim()}\n\n`;
          case "codeBlock": {
            const lang = node.attrs?.language || "";
            return `\`\`\`${lang}\n${inner.trim()}\n\`\`\`\n\n`;
          }
          case "horizontalRule":
            return `---\n\n`;
          default:
            return inner;
        }
      }

      for (const child of doc.content || []) {
        md += processNode(child);
      }
      return md.trim();
    } catch {
      return `# ${title}\n\n${content}`;
    }
  }

  // ── Helper: Download Blob ────────────────────────────────────────────────
  function downloadBlob(blob: Blob, filename: string) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  // ── Export as Markdown (.md) ─────────────────────────────────────────────
  function exportMarkdown(title: string, content: string) {
    const md = tiptapToMarkdown(content, title || "Untitled");
    const blob = new Blob([md], { type: "text/markdown;charset=utf-8" });
    const safeTitle = (title || "untitled").replace(/[^a-z0-9_\-]/gi, "_").toLowerCase();
    downloadBlob(blob, `${safeTitle}.md`);
  }

  // ── Export as Plain Text (.txt) ──────────────────────────────────────────
  function exportPlainText(title: string, content: string) {
    const md = tiptapToMarkdown(content, title || "Untitled");
    const plain = md.replace(/[#*`_~]/g, "");
    const blob = new Blob([plain], { type: "text/plain;charset=utf-8" });
    const safeTitle = (title || "untitled").replace(/[^a-z0-9_\-]/gi, "_").toLowerCase();
    downloadBlob(blob, `${safeTitle}.txt`);
  }

  // ── Export as Styled HTML (.html) ─────────────────────────────────────────
  function exportHTML(title: string, htmlContent: string) {
    const fullHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title || "Untitled"}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      max-width: 760px;
      margin: 40px auto;
      padding: 0 20px;
      color: #1e293b;
      line-height: 1.7;
    }
    h1 { font-size: 2.2rem; font-weight: 700; margin-bottom: 1.5rem; color: #0f172a; }
    h2 { font-size: 1.5rem; font-weight: 600; margin-top: 2rem; margin-bottom: 1rem; color: #1e293b; }
    h3 { font-size: 1.2rem; font-weight: 600; margin-top: 1.5rem; }
    p { margin-bottom: 1.25rem; }
    blockquote { border-left: 4px solid #f59e0b; padding-left: 1rem; color: #64748b; font-style: italic; margin: 1.5rem 0; }
    code { background: #f1f5f9; padding: 0.2em 0.4em; border-radius: 4px; font-size: 85%; }
    pre { background: #0f172a; color: #f8fafc; padding: 1rem; border-radius: 8px; overflow-x: auto; }
    ul, ol { padding-left: 1.5rem; margin-bottom: 1.25rem; }
    li { margin-bottom: 0.25rem; }
    hr { border: none; border-top: 1px solid #e2e8f0; margin: 2rem 0; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 1.5rem; }
    th, td { border: 1px solid #cbd5e1; padding: 0.5rem 0.75rem; text-align: left; }
    th { background: #f8fafc; font-weight: 600; }
  </style>
</head>
<body>
  <h1>${title || "Untitled"}</h1>
  <div class="content">
    ${htmlContent}
  </div>
</body>
</html>`;
    const blob = new Blob([fullHtml], { type: "text/html;charset=utf-8" });
    const safeTitle = (title || "untitled").replace(/[^a-z0-9_\-]/gi, "_").toLowerCase();
    downloadBlob(blob, `${safeTitle}.html`);
  }

  // ── Import Markdown / Text file ──────────────────────────────────────────
  async function parseImportFile(file: File): Promise<{ title: string; content: string }> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const text = (e.target?.result as string) || "";
        let title = file.name.replace(/\.(md|txt|markdown)$/i, "");
        let body = text;

        // Check if first line is a markdown header: "# Title"
        const match = text.match(/^#\s+(.+)$/m);
        if (match) {
          title = match[1].trim();
          body = text.replace(/^#\s+.+$/m, "").trim();
        }

        // Generate a clean Tiptap document
        const paragraphs = body.split(/\n\n+/);
        const docContent = paragraphs.map((p) => {
          const trimmed = p.trim();
          if (trimmed.startsWith("## ")) {
            return {
              type: "heading",
              attrs: { level: 2 },
              content: [{ type: "text", text: trimmed.replace(/^##\s+/, "") }],
            };
          }
          if (trimmed.startsWith("### ")) {
            return {
              type: "heading",
              attrs: { level: 3 },
              content: [{ type: "text", text: trimmed.replace(/^###\s+/, "") }],
            };
          }
          return {
            type: "paragraph",
            content: [{ type: "text", text: trimmed }],
          };
        });

        resolve({
          title,
          content: JSON.stringify({ type: "doc", content: docContent }),
        });
      };
      reader.onerror = reject;
      reader.readAsText(file);
    });
  }

  return {
    isExporting,
    isImporting,
    exportMarkdown,
    exportPlainText,
    exportHTML,
    parseImportFile,
    tiptapToMarkdown,
  };
}
