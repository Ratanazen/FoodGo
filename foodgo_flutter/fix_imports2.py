import os
import glob

# For all files in lib/features/*/presentation/*.dart
files = glob.glob('lib/features/*/presentation/*.dart')

def replace_imports(content):
    content = content.replace("import '../../widgets/", "import '../../../widgets/")
    content = content.replace("import '../../core/", "import '../../../core/")
    # sometimes they might have been replaced already by the first script, but for newly created ones:
    return content

for file in files:
    with open(file, 'r') as f:
        content = f.read()
    # avoid double replacement if already has 3 dots
    if "import '../../widgets/" in content or "import '../../core/" in content:
        content = replace_imports(content)
        with open(file, 'w') as f:
            f.write(content)

