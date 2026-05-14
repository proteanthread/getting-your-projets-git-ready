#!/bin/sh
SCRIPT_VERSION="2.0.0"
DRY_RUN=0
DEBUG=0

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Interactive scaffolding script for language-agnostic projects."
    echo "  --help       Display this help message and exit"
    echo "  --version    Display script version and exit"
    echo "  --dry-run    Simulate execution without modifying the file system"
    echo "  --about      Describe the purpose of this script"
    echo "  --debug      Enable verbose diagnostic output"
    echo "  --license    Display the full MIT License"
    echo ""
    echo "Run without arguments to interactively initialize a project repository."
}

show_license() {
    cat << 'EOF'
MIT License

Copyright (c) 2026 Jeff Wood

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --help) show_help; exit 0 ;;
        --version) echo "project-scaffold.sh version $SCRIPT_VERSION"; exit 0 ;;
        --dry-run) DRY_RUN=1 ;;
        --about) echo "This script interactively scaffolds a Git repository, creates directories, and generates project files."; exit 0 ;;
        --debug) DEBUG=1 ;;
        --license) show_license; exit 0 ;;
        *)
            echo "Unknown argument: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

printf "Enter the project filename to document in the README: "
read SOURCE

if [ ! -f "$SOURCE" ] && [ "$DRY_RUN" -eq 0 ]; then
    echo "Notice: Source file '$SOURCE' not found. Comment extraction will be skipped if it does not exist."
fi

printf "Enter the project title for the README: "
read PROJECT_TITLE

printf "Enter a brief description of what the project does: "
read PROJECT_DESC

printf "Describe the Architecture and Design for this project: "
read ARCH_DESIGN

printf "Enter sub-directories to create, separated by spaces (e.g., src docs tests) or leave blank: "
read DIRECTORIES

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would create directories: $DIRECTORIES"
    echo "[DRY RUN] Would generate README.md, LICENSE, and .gitignore."
    echo "[DRY RUN] Would append source filename and extracted comments from $SOURCE to README.md."
    echo "[DRY RUN] Would execute: git init && git add . && git commit -m \"Initial commit: $PROJECT_TITLE\""
    exit 0
fi

if [ -n "$DIRECTORIES" ]; then
    if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Creating specified sub-directories..."; fi
    for dir in $DIRECTORIES; do
        mkdir -p "$dir"
        if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Created $dir"; fi
    done
fi

if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Writing core README.md..."; fi
cat << EOF > README.md
# $PROJECT_TITLE

$PROJECT_DESC

## Architecture and Design
$ARCH_DESIGN

## Project File
$SOURCE
EOF

if [ -f "$SOURCE" ]; then
    if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Appending source documentation..."; fi
    cat << EOF >> README.md

## Source Code Documentation
EOF

    if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Extracting comments from $SOURCE..."; fi
    awk '
    BEGIN { in_block_comment = 0 }
    /^[[:space:]]*\/\*/ { in_block_comment = 1 }
    in_block_comment == 1 {
        print $0
        if (/\*\//) { in_block_comment = 0 }
        next
    }
    /^[[:space:]]*(#|\/\/|::|[Rr][Ee][Mm][[:space:]]|\047)/ { print $0 }
    ' "$SOURCE" >> README.md
fi

if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Writing LICENSE..."; fi
cat << 'EOF' > LICENSE
MIT License

Copyright (c) 2026 Jeff Wood

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Writing .gitignore..."; fi
cat << EOF > .gitignore
*~
*.tmp
*.log
.DS_Store
EOF

echo "Repository scaffolding files generated successfully."
if command -v git >/dev/null 2>&1; then
    echo "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: $PROJECT_TITLE scaffolding"
    if [ $? -ne 0 ]; then
        echo "Notice: Git initialized, but the commit failed."
        echo "Ensure your Git user.email and user.name are configured globally."
    else
        echo "Git repository successfully initialized and committed."
    fi
else
    echo "Notice: Git binary not found on this system. Skipping version control initialization."
fi
