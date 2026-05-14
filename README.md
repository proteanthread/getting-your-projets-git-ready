# Getting your project git ready.

Just some simple scripts to help you get your project git ready. I may in the future add different scripts for different compilers (or allow you to include your own compilers).

## Architecture and Design
These scripts should be POSIX compliant, therefore should work on ALL *nix systems.

## Project File
github-ready

## Source Code Documentation
/*

* PROJECT ROADMAP
* COMPLIANCE STATUS:
* [MET] 2026-05-13: Replaced Modified MIT License with the standard, full MIT License.
* [MET] 2026-05-13: Added interactive prompt for optional FreeDOS compilation instructions.
* [MET] 2026-05-13: Reorganized documentation to default to Linux (GCC/BCC) and conditionally append FreeDOS toolchains.
* CANDIDATE CRITERIA:
* 1. Add automated C89 static analysis via splint or cppcheck in the build process.
* 2. Implement automated binary size verification to enforce the 512KB limitation.
* 3. Implement interactive cross-compilation target selection (e.g., POSIX vs DOSBox-X deployment).
* VERSION: 1.7.0
* Parse command line arguments
* Interactive Prompts
* Dynamically strip the file extension to create the target binary name
* Compilation phase
* Repository scaffolding

*/
