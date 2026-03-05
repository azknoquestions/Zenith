# Push Zenith to GitHub (azknoquestions)

Your folder is a Git repo with `origin` → **https://github.com/azknoquestions/Zenith**. To get it live and keep it in sync with Cursor and collaborators:

## 1. Create the repository on GitHub (one-time)

- Go to [github.com/new](https://github.com/new)
- **Repository name:** `Zenith`
- **Public** or **Private** — your choice
- **Do not** check "Add a README" or "Add .gitignore"
- Click **Create repository**

## 2. Sign in and push (one-time)

Git needs to authenticate with GitHub. Use one of these:

### Option A: GitHub CLI (recommended)

```bash
brew install gh
gh auth login
```

Then push:

```bash
cd "/Users/zak/Library/Mobile Documents/com~apple~CloudDocs/Zenith"
git push -u origin main
```

### Option B: HTTPS with token

1. GitHub → Settings → Developer settings → [Personal access tokens](https://github.com/settings/tokens) → Generate new token (classic), enable `repo`.
2. When you run `git push`, use your **username** and the **token** as the password.

### Option C: SSH

```bash
# If you don't have an SSH key: ssh-keygen -t ed25519 -C "your@email.com"
# Add the key to GitHub: https://github.com/settings/keys
cd "/Users/zak/Library/Mobile Documents/com~apple~CloudDocs/Zenith"
git remote set-url origin git@github.com:azknoquestions/Zenith.git
git push -u origin main
```

## 3. Keep it live for Cursor and collaborators

- **You:** After making changes, run `git add . && git commit -m "your message" && git push` so GitHub is always up to date.
- **Collaborators:** They open the folder in Cursor, run `git pull` when they start, and push their changes the same way.
- **Cursor:** This project has a rule so the AI is aware of the GitHub remote and can remind you to push/pull.

Repo URL (after you create it): **https://github.com/azknoquestions/Zenith**
