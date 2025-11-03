# How to View the ERD Diagram

The `erd-diagram.mermaid` file contains a visual Entity-Relationship Diagram of the Store.NET database.

## 🌐 Online Viewers (Easiest)

### Option 1: GitHub (Recommended)
1. Navigate to the file on GitHub:
   ```
   https://github.com/SPartenev/Teka_StoreNET_ERP/blob/main/analysis/week1/database/erd-diagram.mermaid
   ```
2. GitHub will automatically render the diagram ✅

### Option 2: Mermaid Live Editor
1. Go to https://mermaid.live/
2. Copy the contents of `erd-diagram.mermaid`
3. Paste into the left panel
4. View rendered diagram on the right
5. Export as PNG/SVG if needed

## 💻 VS Code (Local Development)

### Install Extension:
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "Mermaid Preview"
4. Install "Mermaid Preview" by Mermaid Technologies

### View Diagram:
1. Open `erd-diagram.mermaid` in VS Code
2. Right-click in the editor
3. Select "Preview Mermaid Diagram"
4. Or use shortcut: `Ctrl+Shift+V`

## 📄 Convert to Image

### Using Mermaid CLI:
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Convert to PNG
mmdc -i erd-diagram.mermaid -o erd-diagram.png

# Convert to SVG (better quality)
mmdc -i erd-diagram.mermaid -o erd-diagram.svg
```

### Using Online Tool:
1. Visit https://mermaid.ink/
2. Upload `erd-diagram.mermaid`
3. Download as PNG or SVG

## 📊 Diagram Structure

The ERD includes:
- **~50 entities** from the Store.NET database
- **~45 relationships** with cardinality
- **Key fields** for major tables (Products, Stores, Users, etc.)
- **Color-coded sections** (if rendered with theme support)

## 🔍 Reading the Diagram

### Relationship Notation:
- `||--o{` - One-to-Many (required on left, optional on right)
- `}o--o|` - Many-to-One (optional on left, required on right)
- `||--||` - One-to-One (required both sides)
- `}o--o{` - Many-to-Many (optional both sides)

### Example:
```mermaid
Products ||--o{ Prices : "has"
```
Reads as: "One Product has many Prices"

## ⚠️ Troubleshooting

**Issue:** Diagram not rendering in GitHub
- **Solution:** Ensure file has `.mermaid` extension (not `.mmd` or `.txt`)

**Issue:** Syntax errors in viewer
- **Solution:** Validate file has not been corrupted
- Check that it starts with `erDiagram`

**Issue:** Too large to view comfortably
- **Solution:** Use Mermaid Live Editor's zoom controls
- Or export to SVG and open in image viewer

## 📱 Mobile Viewing

Use Mermaid Live Editor (mermaid.live) in mobile browser for best experience.

---

**Quick Links:**
- [Mermaid Docs](https://mermaid.js.org/syntax/entityRelationshipDiagram.html)
- [Mermaid Live Editor](https://mermaid.live/)
- [GitHub Mermaid Support](https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/)
