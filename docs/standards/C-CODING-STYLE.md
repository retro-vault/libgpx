# C-CODING-STYLE.md - C Coding Standards and Project Rules

This document defines the rules that all agents, including AI agents,
must follow when writing, reviewing, or modifying code in this
project.

We are writing C code.

- All compiling and debugging happens inside the generic Docker xcc-z80
  container on Docker Hub: https://hub.docker.com/r/wischner/xcc-z80
- builds must use full warnings and sanitizers while debugging.

## 1. Project Directory Structure

Do not create files outside the approved project directories.
Do not leave editor backups, stray object files, or temporary files in
the tree.

- `src/` contains application `.c` files.
- `include/<name>/` contains each library's public source headers.
- `lib/` contains project libraries and third-party libraries.
- `lib/<name>/` contains the implementation of a library such as
  `lib/dbf/`.
- `bin/` is the distribution root: `bin/loader/`, `bin/lib/`, and
  `bin/include/`.
- `build/` contains disk images, object files, dependency files, maps,
  listings, tests, and temporary build products.
- `docs/` contains project notes and design documents.
- `tests/` contains automated tests.
- `tests/data/` contains data files used by tests.

Rules:

- Public source headers must live in `include/<name>/`; the build copies them
  to `bin/include/<name>/` for distribution.
- Project source files may live in `src/` or in a library directory
  under `lib/`.
- Intermediate build artifacts must go only into the root `build/` directory;
  distributable loaders, libraries, and headers go under `bin/`.
- No nested `build/` directories are allowed.
- Nothing else should be created at the project root except normal
  project files such as `LICENSE`, `README.md`, `Makefile`, and similar
  top-level metadata. Coding standards now live under `docs/standards/`.

## 2. Naming Conventions

- Use lowercase snake_case for C symbols including classes, etc.
- Do not use Hungarian notation, PascalCase, or camelCase.
- Use uppercase only when a true macro-style constant makes sense.
- Use lowercase snake_case for file names.

Examples:

- Good: `screen_clear()`, `player_score`, `dbf_open()`
- Bad: `ScreenClear()`, `playerScore`, `DbfOpen()`

## 3. Header and Implementation Separation

Every module must follow a clear header-and-implementation layout.

- A public `.h` file in `include/<name>/` contains:
  - A file header comment
  - Public declarations
  - Public types
  - Public constants or macros
  - Documentation for every public function
- A `.cpp` file in `src/` or `lib/<name>/` contains:
  - A file header comment
  - `#include "module.h"`
  - Private static helpers and state
  - The implementation

Do not put function bodies in headers unless a tiny static helper is
truly necessary and clearly marked.

## 4. File Header

Every `.cpp` and `.h` file must begin with a real file header in this
style:

```cpp
/*
   Describe exactly what this file does.
   Be specific about the module purpose, important design choices,
   and any hardware assumptions that matter.
  
   GPL 3.0 License (see: LICENSE)
   Copyright (C) 2026 tomaz stih
/*
```

Rules:

- Replace the placeholder text with a real description.
- The comment must describe the file, not just list its symbols.
- Keep lines readable on an 80-column terminal where practical.

## 5. Function Documentation

Every function declared in a public header must have a comment
immediately above its prototype.

Example:

```c
/*
   Look up an application id by application name.
  
   Parameters:
        name        - Application name, usually space-padded in GEM
                      style.
  
   Returns:
        Matching AES application id, or a negative value if not found.
  
   Notes:
        This is commonly used for accessory and desktop integration.
  
   Sample call:
        WORD shell_id = appl_find("DESKTOP ");
*/
WORD appl_find(char *name);
```

Rules:

- Say what the function does.
- Mention parameters and the return value when needed.
- Mention side effects, limits, or hardware requirements when
  relevant.
- Document private static helpers too when their purpose is not
  obvious.

## 6. General Coding Rules

- Fix all warnings.
- Prefer small, focused functions.
- Keep source files under about 500 lines when possible.
- Avoid global variables unless they are truly necessary.
- Keep code readable on an 80-column terminal.
- Use 4 spaces for indentation and no tabs.
- Use K&R braces for functions. Control-flow brace style may vary
  within reason, but keep it consistent inside a file.

## 7. Build Rules

- Always build and test with G++ first.
- Use `-g` for hosted debug builds.
- All build outputs must go into the root `build/` directory only.
- Do not create `build/` directories inside `src/`, `lib/`, `tests/`,
  or any other subdirectory.
- Use nested makefiles.
- The top-level `Makefile` should define the main entry points.
- Subdirectories such as `src/`, `lib/`, `lib/dbf/`, and `tests/`
  should have their own makefiles when needed.
- Keep VS Code `F5` debugging working through `.vscode/`.

## 8. Documentation

- Keep `README.md` up to date.
- `README.md` must explain:
  - How to build the project
  - Dependencies
  - Usage
- Keep notes in `docs/`, using the current subfolders:
  `dist/`, `howtos/`, `research/`, `standards/`, and `todo/`.

## 9. Tests

- Keep automated tests in `tests/`.
- Put test data files in `tests/data/`.
