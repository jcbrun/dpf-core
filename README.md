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