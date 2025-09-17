# 📝 Git Cheatsheet

A quick reference for common Git commands.  

---

## 🔍 Status
Check the current state of the working directory and staging area:
```bash
git status
```

---

## 📂 Staging & Commit

Stage all changes:
```bash
git add .
```

Stage a specific file:
```bash
git add Daily-learning-monitor.html
```

Commit staged changes to the local repository:
```bash
git commit -m "First version of daily tracker"
```

> 💡 Remember: Commits stay **local** until pushed.

Push commits to the remote repository:
```bash
git push
```

---

## 📜 Logs
View commit history:
```bash
git log
```

---

## 📡 Sync with Remote

If you **delete a file locally** but want to sync with the remote:
```bash
git checkout -- <filename>   # Restore a specific file
git checkout -- .            # Restore all deleted files
```

To pull the latest changes from remote:
```bash
git pull
```

---

## 🔄 Undo Changes (Uncommitted)

Undo changes in a specific file:
```bash
git checkout -- <filename>
```

Undo changes in all files:
```bash
git checkout -- .
```

---

## 🔙 Undo Commits

Find the commit ID:
```bash
git log
```

Revert a commit (creates a new commit to undo changes):
```bash
git revert <commit-id>
```

Revert without committing immediately:
```bash
git revert -n <commit-id>
```

---

## 🔧 Compare Changes

Compare working directory with last commit:
```bash
git diff
```

Use a difftool (e.g., **Meld**):
```bash
git difftool HEAD
```

---

## 🐑 Clone a Repository
Clone a repo from GitHub:
```bash
git clone <repo-url>
```
