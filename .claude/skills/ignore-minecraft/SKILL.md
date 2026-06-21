---
name: ignore-minecraft
description: Enforce that work stays scoped to the unchained Flutter app and never touches the unrelated minecraft* directory. Use whenever searching, listing, globbing, or editing files under /home/isuale/dev, or any time results could include the minecraft folder.
---

# Ignore the minecraft directory

The folder `/home/isuale/dev` is where the user works on the **unchained** Flutter app,
but it ALSO contains a `minecraft*` directory that has nothing to do with this project.

## Rules

1. **Never** read, edit, search, list, or reference anything under a `minecraft*` directory.
   It is not project code.
2. When running searches (`grep`, `glob`, `find`, `rg`, `ls`) that could reach
   `/home/isuale/dev`, exclude the minecraft path. Examples:
   - `rg --glob '!**/minecraft*/**' ...`
   - `find /home/isuale/dev -path '*/minecraft*' -prune -o ... -print`
   - `ls` the specific project subdir, not the whole `dev` folder.
3. The real project lives at:
   `/run/media/isuale/e5806df2-8353-4cdb-8ad8-44e0b7524785/dev/unchained`
   (with a mirror working dir at `/home/isuale/dev/unchained`). Stay inside the
   `unchained` app tree.
4. If a tool result surfaces a minecraft file, drop it silently and continue —
   do not analyze it or mention it as if it were project code.
