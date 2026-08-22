import re
import os

artifact_path = "/home/reny/.gemini/antigravity-cli/brain/9c2b10d4-1361-4900-98da-1c4285f86d4d/Glassmorphism_Redesign.md"
with open(artifact_path, "r") as f:
    content = f.read()

# Pattern to extract filename and code block
# Looks for `## X. `path/to/file`` followed by ```dart ... ```
pattern = re.compile(r'## \d+\. `([^`]+)`\n```(?:dart)?\n(.*?)\n```', re.DOTALL)

matches = pattern.findall(content)

for filename, code in matches:
    # Ensure directory exists
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        f.write(code)
    print(f"Updated {filename}")

