# Project: Log Archive Tool

## Overview
You are required to build a tool to archive logs by compressing and storing them in a new directory. This is especially useful for removing old logs and keeping the system clean while maintaining the data in a compressed format for future reference.

The most common location for logs on a Unix-based system is `/var/log`.

---

## Requirements
Your task is to create a script named `log-archive-YOUR_USERNAME.sh`. The tool must run from the command line, accept a directory as an argument, and perform the following actions:

### Core Functionality:
* **Argument Handling:** The tool must accept the log directory as an argument when running.
  ```bash
  ./log-archive-YOUR_USERNAME.sh <log-directory>
  ```

* **Compression:** The tool must compress the logs into a `.tar.gz` file.
* **Storage:** Store the compressed logs in a new directory (e.g., `archives/`).
* **Naming Convention:** The archive file must include a timestamp in its name:
`logs_archive_YYYYMMDD_HHMMSS.tar.gz` (Example: `logs_archive_20240816_100648.tar.gz`).
* **Activity Logging:** The tool must log the date, time, and name of the archive to a tracking file (e.g., `archive_log.txt`).

### Stretch Goals (Optional)

* **Auto-clean:** Add an option to delete the original logs after a successful archive.
* **Size Report:** Display the size of the directory before and after compression.
* **Custom Destination:** Allow the user to provide a second argument for the destination directory.
* **Retention Policy:** Automatically delete archives older than 7 days.

---

## How to Submit Your Work

This project follows the **Standard Open Source Contribution Workflow**. Please follow these steps carefully:

1. **Fork this Repository:** Click the "Fork" button at the top right of this page to create a copy in your own GitHub account.
2. **Clone Your Fork:** Replace `YOUR_USERNAME` with your actual GitHub username.
```bash
git clone [https://github.com/YOUR_USERNAME/Log-Archive-Tool.git](https://github.com/YOUR_USERNAME/Log-Archive-Tool.git)

```


3. **Create Your Script:** Develop your `log-archive-YOUR_USERNAME.sh` inside the repository.
4. **Set Permissions:** Ensure the script is executable:
```bash
chmod +x log-archive-YOUR_USERNAME.sh

```

5. **Commit Your Changes:**
```bash
git add log-archive-YOUR_USERNAME.sh
git commit -m "Add log-archive script - Completed by [Your Name]"

```

6. **Push to GitHub:**
```bash
git push origin main

```

7. **Submit a Pull Request (PR):** Go to the original repository in the organization, click **"New Pull Request"**, and submit your work for review.
