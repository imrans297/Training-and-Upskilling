# Setup Guide: Push Mario Game to Your Remote Repository

**Created by:** Imran Shaikh

---

## Steps to Push to Your Own Remote

### 1. Create New Repository on GitHub
- Go to https://github.com/new
- Repository name: `gitops-mario-game` (or your choice)
- Make it **Public** (for ArgoCD to access)
- **DO NOT** initialize with README, .gitignore, or license
- Click "Create repository"

### 2. Update Remote URL

```bash
cd mario-game-repo

# Remove original remote
git remote remove origin

# Add your new remote (replace with your GitHub username)
git remote add origin https://github.com/<YOUR-USERNAME>/gitops-mario-game.git

# Verify remote
git remote -v
```

### 3. Push to Your Repository

```bash
# Push to your remote
git push -u origin main
```

If branch is named `master` instead of `main`:
```bash
git push -u origin master
```

### 4. Update ArgoCD Application Manifest

Edit: `../applications/mario-game.yaml`

Change the `repoURL` to your repository:
```yaml
source:
  repoURL: https://github.com/<YOUR-USERNAME>/gitops-mario-game.git
  targetRevision: main
  path: .
```

### 5. Verify Repository

Visit your GitHub repository:
```
https://github.com/<YOUR-USERNAME>/gitops-mario-game
```

You should see all the Mario game files!

---

## Quick Commands

```bash
# Navigate to repo
cd /home/einfochips/TrainingPlanNew/GitOps-with-Kubernetes_(K8S)_Terraform_AWS/4GitopsPipeline-SupermarioGame/mario-game-repo

# Check current remote
git remote -v

# Remove old remote
git remote remove origin

# Add your remote
git remote add origin https://github.com/<YOUR-USERNAME>/gitops-mario-game.git

# Push to your repo
git push -u origin main
```

---

## Benefits of Your Own Repository

✅ **Full Control** - Make changes as needed  
✅ **GitOps Practice** - Learn by modifying manifests  
✅ **Portfolio** - Show in interviews  
✅ **Customization** - Add your own features  

---

## Next Steps

1. Create GitHub repository
2. Update remote URL
3. Push code
4. Update ArgoCD manifest with your repo URL
5. Deploy via ArgoCD!
