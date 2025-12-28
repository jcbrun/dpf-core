# Mise en place de l'environnement dbt + BigQuery + CI/CD (Github + GCP Cloudrun)

## Structure du projet

```
├── .github
│   └── workflows
│       ├── cd.yml
│       └── ci.yml
├── README_cicd.md
├── README_cicd.pdf
├── README_dbt.md
├── README_dbt.pdf
├── README.md
└── scripts
    ├── 00_function.sh
    ├── 01_env.sh
    ├── 02_create_project.sh
    ├── 03_bootstrap_prereq.sh
    ├── 04_build_push_update_execute.sh
    ├── 05_configure_github_envs
    ├── 06_dbt_install.sh
    ├── 07_dbt_init_project.sh
    ├── 08_dbt_create_profiles.sh
    └── 09_dbt_create_docker_assets.sh
```

## Mise en place des pre-requis

### Création du repo (si il n'hesite pas)
```
export LOGIN_GITHUB=jcbrun
export REPO_GITHUB=dpf-core
gh auth login
# Création du repo github
# se positionner dans le répertoire du repo
cd ${REPO_GITHUB}
gh repo create ${REPO_GITHUB} \                               
  --public

# Commit et push
git init
git branch -M main 
git remote add origin git@github.com:${LOGIN_GITHUB}/${REPO_GITHUB}.git
# creer .gitignore
cat > ".gitignore" <<EOF
.DS_Store
venv/
logs/
EOF
git add .github *
git commit -m "Version Initiale"
git push origin main
```
