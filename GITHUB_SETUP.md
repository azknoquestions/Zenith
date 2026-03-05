# Push Zenith to GitHub

Your folder is now a Git repo with an initial commit. To put it on GitHub and collaborate:

## 1. Create the repository on GitHub

- Go to [github.com/new](https://github.com/new)
- **Repository name:** `Zenith` (or any name you like)
- Choose **Public** (or Private if you prefer)
- **Do not** check "Add a README" or "Add .gitignore" — the repo already has them
- Click **Create repository**

## 2. Connect and push from your machine

In Terminal, from the Zenith folder, run (replace `YOUR_USERNAME` with your GitHub username):

```bash
cd "/Users/zak/Library/Mobile Documents/com~apple~CloudDocs/Zenith"

git remote add origin https://github.com/YOUR_USERNAME/Zenith.git
git branch -M main
git push -u origin main
```

If you use SSH instead of HTTPS:

```bash
git remote add origin git@github.com:YOUR_USERNAME/Zenith.git
git branch -M main
git push -u origin main
```

## 3. Optional: set your Git identity

For clearer commit history with your name and email:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Collaborating

- **Invite collaborators:** Repo → Settings → Collaborators → Add people
- **Get updates:** `git pull`
- **Share your changes:** `git add .` → `git commit -m "Your message"` → `git push`

You can delete this file after you’ve pushed to GitHub.
