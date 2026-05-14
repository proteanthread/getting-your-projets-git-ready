#!/bin/sh
# PROJECT ROADMAP
# COMPLIANCE STATUS:
# [MET] 2026-05-13: Replaced Modified MIT License with the standard, full MIT License.
# [MET] 2026-05-13: Added interactive prompt for optional FreeDOS compilation instructions.
# [MET] 2026-05-13: Reorganized documentation to default to Linux (GCC/BCC) and conditionally append FreeDOS toolchains.
# CANDIDATE CRITERIA:
# 1. Add automated C89 static analysis via splint or cppcheck in the build process.
# 2. Implement automated binary size verification to enforce the 512KB limitation.
# 3. Implement interactive cross-compilation target selection (e.g., POSIX vs DOSBox-X deployment).
# VERSION: 1.7.0

SCRIPT_VERSION="1.7.0"
COMPILER="cc"
CFLAGS="-ansi -pedantic -Wall"
DRY_RUN=0
DEBUG=0

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Interactive build and scaffolding script for portable C89 projects."
    echo "  --help       Display this help message and exit"
    echo "  --version    Display script version and exit"
    echo "  --dry-run    Simulate execution without modifying the file system"
    echo "  --about      Describe the purpose of this script"
    echo "  --debug      Enable verbose diagnostic output"
    echo "  --license    Display the full MIT License"
    echo "  --clean-up   Remove compilation artifacts, object files, and editor garbage"
    echo ""
    echo "Run without arguments to interactively compile and initialize the repository."
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

cleanup_artifacts() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY RUN] Would execute: rm -f *.o *.obj *.exe *~ core"
        echo "[DRY RUN] Would prompt for specific target binary to remove."
        return 0
    fi
    
    if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Removing standard wildcard artifacts..."; fi
    rm -f *.o *.obj *.exe *~ core
    
    printf "Enter the compiled binary name to remove (leave blank to skip): "
    read BINARY_NAME
    
    if [ -n "$BINARY_NAME" ]; then
        if [ -f "$BINARY_NAME" ]; then
            rm -f "$BINARY_NAME"
            echo "Successfully removed target binary: $BINARY_NAME"
        else
            echo "Notice: Target binary '$BINARY_NAME' not found in the current directory."
        fi
    fi
    echo "Cleanup complete."
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --help) show_help; exit 0 ;;
        --version) echo "github-ready.sh version $SCRIPT_VERSION"; exit 0 ;;
        --dry-run) DRY_RUN=1 ;;
        --about) echo "This script interactively compiles C89 source code, scaffolds a Git repository, and manages artifacts."; exit 0 ;;
        --debug) DEBUG=1 ;;
        --license) show_license; exit 0 ;;
        --clean-up) cleanup_artifacts; exit 0 ;;
        *) 
            echo "Unknown argument: $1"
            show_help
            exit 1 
            ;;
    esac
    shift
done

# Interactive Prompts
printf "Enter the C source filename to compile (e.g., main.c): "
read SOURCE

if [ ! -f "$SOURCE" ] && [ "$DRY_RUN" -eq 0 ]; then
    echo "Error: Source file '$SOURCE' not found."
    exit 1
fi

# Dynamically strip the file extension to create the target binary name
TARGET="${SOURCE%.*}"

printf "Enter the project title for the README: "
read PROJECT_TITLE

printf "Enter a brief description of what the program is about: "
read PROJECT_DESC

printf "Include compilation instructions for FreeDOS (BCC, Open Watcom, Turbo C) in the README? (y/N): "
read INCLUDE_FREEDOS

# Compilation phase
if [ "$DEBUG" -eq 1 ]; then
    echo "DEBUG: Executing $COMPILER $CFLAGS -o $TARGET $SOURCE"
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would compile using: $COMPILER $CFLAGS -o $TARGET $SOURCE"
else
    $COMPILER $CFLAGS -o "$TARGET" "$SOURCE"
    if [ $? -eq 0 ]; then
        echo "Build successful. Executable created: ./$TARGET"
    else
        echo "Build failed. Please check the source code for errors."
        exit 1
    fi
fi

# Repository scaffolding
if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would generate README.md, LICENSE, and .gitignore."
    echo "[DRY RUN] Would parse $SOURCE for comments and conditionally add FreeDOS instructions."
    echo "[DRY RUN] Would execute: git init && git add . && git commit -m \"Initial commit\""
    exit 0
fi

if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Writing core README.md..."; fi
cat << EOF > README.md
# $PROJECT_TITLE

$PROJECT_DESC

## Architecture and Design
This project adheres strictly to Unix design principles: doing one thing well and maintaining predictable modularity. The application logic avoids dynamic allocation where possible, aiming to operate safely within a 512 KB memory limit for reliable execution on constrained and legacy systems.

## Compilation Instructions

**Linux (POSIX) via GCC:**
\`cc -ansi -pedantic -Wall -o $TARGET $SOURCE\`

**Linux (POSIX) via Bruce's C Compiler (BCC):**
\`bcc -ansi -o $TARGET $SOURCE\`
EOF

case "$INCLUDE_FREEDOS" in
    [yY]|[yY][eE][sS])
        if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Appending FreeDOS instructions to README.md..."; fi
        cat << EOF >> README.md

**FreeDOS via Bruce's C Compiler (BCC):**
\`bcc -ansi -o ${TARGET}.exe $SOURCE\`

**FreeDOS via Open Watcom:**
\`wcl -za $SOURCE\`

**FreeDOS via Turbo C / Turbo C++:**
\`tcc -A $SOURCE\`
EOF
        ;;
esac

if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Appending Source Code Comments section header..."; fi
cat << EOF >> README.md

## Source Code Comments
EOF

if [ "$DEBUG" -eq 1 ]; then echo "DEBUG: Extracting comments from $SOURCE..."; fi
# Use POSIX awk to extract C89 block comments (/* ... */) and append them to the README
awk '
BEGIN { in_comment = 0 }
/\/\*/ { in_comment = 1 }
in_comment == 1 { print $0 }
/\*\// { in_comment = 0 }
' "$SOURCE" >> README.md

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
# Ignore compiled executables
$TARGET
${TARGET}.exe

# Ignore object files
*.o
*.obj
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
