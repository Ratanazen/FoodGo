import os
import glob

# For all files in lib/features/*/presentation/*.dart
files = glob.glob('lib/features/*/presentation/*.dart')

def replace_imports(content):
    content = content.replace("import '../../widgets/", "import '../../../widgets/")
    content = content.replace("import '../../core/", "import '../../../core/")
    content = content.replace("import '../widgets/", "import '../../widgets/")
    content = content.replace("import '../core/", "import '../../core/")
    return content

for file in files:
    with open(file, 'r') as f:
        content = f.read()
    content = replace_imports(content)
    with open(file, 'w') as f:
        f.write(content)

map_screen = 'lib/screens/map_screen.dart'
with open(map_screen, 'r') as f:
    content = f.read()
content = content.replace("import '../widgets/", "import '../../widgets/")
content = content.replace("import '../core/", "import '../../core/")
with open(map_screen, 'w') as f:
    f.write(content)
