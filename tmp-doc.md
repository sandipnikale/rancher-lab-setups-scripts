# Rancher VEX Scanner: Project Overview & Demo Guide

## 1. What is the Rancher VEX Scanner?
The **Rancher VEX Scanner** is a security tool built to turn complicated vulnerability reports into clear, actionable data. It automatically "cleans up" scan results by filtering out vulnerabilities that don't actually affect Rancher, using official engineering VEX (Vulnerability Exploitability eXchange) reports as the source of truth.

### **The Problem It Solves:**
*   **Security Noise**: Most scanners report every possible risk, even if it’s a false positive. This tool hides that noise.
*   **Manual Triage**: Instead of spending hours checking CVEs one by one, the tool does the cross-referencing for you in seconds.
*   **Scattered Data**: It pulls together data from the CVE database, Rancher scan portals, and VEX reports into a single, easy-to-read dashboard.

### **The Traditional Manual Triage**

1.  **Understand the Customer Report**: Analyse the reports generated with the scanner tool  (Trivy, Prisma, Aqua, etc.).
2.  **Validate the CVE Against the Image**: Confirm if the CVE is actually present in that specific version.
3.  **Check if It Is a False Positive**: Manually verify if the finding is a false positive (many tools only match versions, not actual patches).
4.  **Check If the CVE Is Already Fixed**: Look up if a fix or suppression exists in engineering databases.
5.  **Identify the Fixed Version**: If yes, determine exactly which release version contains the patch.

---
---

## 2. Key Features 
### **A. Smart Filtering (VEX Intelligence)**
The tool doesn't just scan; it **filters**. By applying official VEX data at runtime, it identifies which vulnerabilities are "Not Affected" or "Already Mitigated," so you only see what truly needs your attention.

### **B. Cluster-Aware Performance**
The scanner knows its environment. It automatically detects your Rancher and Kubernetes versions and tailors its security analysis to match exactly what you are running—no manual configuration required.

### **C. AI-Powered Analysis (Gemini 2.0)**
*   **The Scenario**: You have a 100-page scan report from a customer and need to know which findings are real risks.
*   **The Solution**: Upload the report, and the AI (Gemini) will cross-reference every finding against Rancher’s official security data to tell you exactly: "This is safe," "This is affected," or "This is resolved."

---

## 3. How it's different from traditional tools
| Feature | Standard Scanners (Trivy/Grype) | Rancher VEX Scanner |
| :--- | :--- | :--- |
| **Accuracy** | Reports everything (lots of noise) | **Filters noise** using official VEX data |
| **Effort** | Hours of manual checking | **Instant, automated answers** |
| **Context** | Generic security info | **Cluster-Aware** (Knows your setup) |
| **Intelligence** | Static data only | **AI-Powered** triage and advice |

---

## 4. UI Sections: Behind the Scenes
*   **Single Image Scan**: Fires off an isolated, temporary Kubernetes Job to scan any image you provide.
*   **Batch Scan**: Efficiently processes a large list of images in the background and generates a detailed CSV report.
*   **Component Explorer**: A quick way to "look inside" an image to see exactly which versions of packages it contains.
*   **Release Finder**: A search engine to find which Rancher, RKE2, or K3s releases include a specific image or security fix.
*   **AI Analysis**: A central hub where you upload reports and let Gemini correlate them with official security data.

---

## 5. Demo Flow: Showing the Value
1.  **The "Before & After"**: Run a scan on an image and show how many "Affected" findings are actually explained away as "Safe" by the VEX logic.
2.  **The "Fix Finder"**: Use the Release Finder to show a team exactly which version of Rancher or K3s they need to upgrade to for a specific fix.
3.  **The "Instant Triage" (The Hero Demo)**: Upload a customer report to the AI tab and show how a pile of 50 CVEs becomes a clean, prioritized triage report in 30 seconds.
