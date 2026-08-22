import os

with open('lib/widgets/glass/glass_widgets.dart', 'r') as f:
    lines = f.readlines()

# move exports to top
exports = [l for l in lines if l.startswith('export ')]
declarations = [l for l in lines if not l.startswith('export ')]

with open('lib/widgets/glass/glass_widgets.dart', 'w') as f:
    f.writelines(declarations[:1]) # the import statement
    f.writelines(exports)
    f.writelines(declarations[1:])

with open('lib/widgets/glass/glass_states.dart', 'r') as f:
    content = f.read()
content = content.replace("customColor: Colors.grey.withValues(alpha: 0.1),", "customColor: Colors.grey.withValues(alpha: 0.1),\n      child: const SizedBox(),")
with open('lib/widgets/glass/glass_states.dart', 'w') as f:
    f.write(content)

with open('lib/widgets/glass/glass_modals.dart', 'r') as f:
    content = f.read()
content = content.replace("backgroundColor: Colors.transparent,", "surfaceTintColor: Colors.transparent,\n        shadowColor: Colors.transparent,")
with open('lib/widgets/glass/glass_modals.dart', 'w') as f:
    f.write(content)
