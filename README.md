# Lab work: “Automating tasks in Linux: schedulers from at to systemd timers”

## 1. Purpose and competencies to be developed

**Purpose of the assignment:** To master the practical skills of configuring and managing task schedulers in Linux environments for automating system administration, ensuring the selection of the optimal tool depending on the usage scenario.

**Skills and knowledge to be acquired:**

- Forming the syntax of time expressions for one-time and regular tasks
- Managing the task queue via `atd` with access control via `/etc/at.allow/deny`
- Configuring user and system crontabs using advanced patterns
- Setting up delayed execution at system startup via anacron
- Creating persistent systemd timer units as a modern alternative to cron
- Analyzing execution logs and debugging schedulers
- Evaluating performance and choosing a tool (at for one-time tasks, cron for regular tasks on 24/7 servers, anacron for desktops, systemd for complex dependencies)

---

## 2. Tasks

- [Level C (Basic): “Primary automation of routine operations”](./01%20Task%20C/README.md)
- [Level B (Intermediate): “Server Performance Optimization”](./02%20Task%20B/README.md)
- [Level A (Advanced): “Migration to systemd timers and security”](./03%20Task%20A/README.md)
- [Level S (Pet Project): “Building an SLA Monitoring System with Intelligent Planning”](./04%20Task%20S/README.md)

## 3. Assessment methodology

For each task, the student must demonstrate:

- **Level C:** Error-free execution of commands, correct output of test commands, presence of expected files
- **Level B:** Working scripts, log files with correct data, successful simulation of scenarios
- **Level A:** Active systemd units, logs with resource constraints, anomaly detection
- **Level S:** Fully functional system, automated deployment, clear reporting
