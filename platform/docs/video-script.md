# Recruiter demo — 8–10 minutes

**Rule:** record terminal and dashboard evidence only after a real run. Do not narrate a draft manifest as a deployed system. Blur subscription IDs, tokens, internal URLs, private logs and personal identifiers.

| Time | On screen | Say | Proof to capture |
|---|---|---|---|
| 0:00–0:35 | Repo homepage and one architecture diagram | “I’m Arun. My testing background taught me to verify outcomes, so I built a delivery path from a pull request through a container scan into AKS.” | Repository commit |
| 0:35–1:20 | Existing VM lab and new `platform/` folder | “The original workflow built a WAR and deployed it to an Azure VM with Jenkins and Ansible. I extended that app into a container path so I could compare operations, failure handling and repeatability.” | Existing Jenkinsfile and new folder |
| 1:20–2:20 | PR, test result, Trivy log | “The PR runs Maven tests, builds the image, and fails on fixable high or critical findings. A merged commit is the version used for the registry tag.” | Real green PR and pipeline URL |
| 2:20–3:10 | Dockerfile, ACR repository | “Tomcat 9 matches the servlet API. I publish a commit tagged image to a private registry and give AKS pull permission through its kubelet identity.” | Image tag and digest |
| 3:10–4:20 | Terraform plan, Azure resource overview | “Terraform defines the network, AKS, ACR, Key Vault and log workspace. Remote state and federated pipeline credentials avoid local state and stored Azure secrets.” | Successful plan and resources; never show credentials |
| 4:20–5:25 | Helm templates, Argo CD UI | “Helm holds repeatable Deployment and Service definitions. Git contains the desired image tag. Argo CD shows whether the cluster matches that version.” | Rendered chart, Argo sync and commit |
| 5:25–6:20 | `kubectl get pods`, HTTP response, logs | “A running pod is only one signal. I verify readiness, the HTTP endpoint, events, and application output.” | Healthy response and pod status |
| 6:20–7:45 | Controlled bad release; events and logs | “I introduce a known bad image tag. Image pull fails, so I inspect pod events, identify the missing tag, revert the Git change, sync, and verify recovery.” | Failed event, revert PR, healthy sync |
| 7:45–8:30 | Log Analytics query and evidence index | “I can trace deployment events and container logs. The evidence page links the exact commits and runs behind each claim.” | Real query result and links |
| 8:30–9:00 | Summary card | “I owned the change from code through validation, infrastructure, deployment and recovery. My next iteration adds workload identity for application secrets and service metrics.” | Honest limitations |

## Rehearsal questions and answers

**Why Terraform?** Repeatable, reviewable infrastructure changes and a plan before apply.

**Why Helm and Argo CD together?** Helm renders reusable Kubernetes resources. Argo CD reconciles the Git version of those resources with AKS.

**What happens when a deployment fails?** Check Argo status, pod events and logs, fix or revert the Git source, sync, then check the endpoint and logs again.

**How are credentials handled?** Azure Pipelines uses a federated ARM service connection. The registry has admin login disabled; AKS gets a scoped pull role. Key Vault exists as a foundation but the app does not yet read it.
