# FoodGo Workspace Engineering & Media Presentation Rules

## 1. Media Artifacts & Video Embed Invariants
- Never append cache-busting query strings (e.g., `?v=...`) to local `<video>`, `<source>`, `poster`, or `<track>` paths inside HTML artifacts.
- Always include both the relative artifact filename (`foodgo-demo-full.mp4`) and absolute `file:///...` fallback `<source>` tag, keep `foodgo_demo_video.md` synchronized with the latest MP4 (`![caption](/abs/path.mp4)`), and provide an inline `<agent-embed>` widget (`height <= 450px`) when delivering video outputs.
- Before claiming video/audio completion, verify with `ffprobe` and `ffmpeg -v error -i <file> -f null -` and visually inspect sampled frames via `read_file`.

## 2. Avatar Rig, Styled Image Frames & University Branding
- Never use global color-keying on characters or logos containing white regions (e.g., white cloak or the `736x200` ACLEDA University emblem); use upscaled exterior floodfill + seeded enclosed pocket punch + skin-toned edge feathering + `Image.alpha_composite`.
- For academic defense presentations (`7–10 min`), embed the ACLEDA University logo (`សាកលវិទ្យាល័យ ពាណិជ្ជសាស្រ្ត អេស៊ីលីដា`), all 5 team members (`01 Em Ratana`, `02 Hen Yaungkuy`, `03 Than Sombath Borarat`, `04 Cheang borin`, `05 Ly KimChhun`), and a styled presenter Avatar frame across **every scene/frame** (`Introduction`, `Technology & Method`, `Live Demo`, `Results & Conclusion`) with non-overlapping safe margins.

## 3. Git & Workspace Hygiene
- Never run `git commit`, `git push`, or delete user source edits unless explicitly requested.
