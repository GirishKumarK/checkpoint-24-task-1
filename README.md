ros1_ci — Jenkins CI for ROS1 (Noetic) + Gazebo (Headless)

This repository provides a Dockerized ROS Noetic + Gazebo environment and a Jenkins Pipeline that builds the image and runs tests automatically whenever a Pull Request is merged into the default branch.

Repository URL (for Jenkins & PRs):
https://github.com/Andreas-Ioannou/checkpoint-24-task-1.git

1) What’s inside

Dockerfile — Builds an image with ROS Noetic, Gazebo, your simulation packages, and tests.

Jenkinsfile — Pipeline that:

checks out this repo

builds the Docker image

runs tests (headless Gazebo via rostest)

publishes JUnit XML results

polls SCM every minute (* * * * *) so a PR merge triggers a build soon after.

scripts/

entrypoint.sh — sources ROS + workspace

run_sim.sh — (optional) starts sim headless

test_waypoints.sh — executes rostest (Gazebo + nodes start/stop automatically)

src/ — ROS packages required for the tests (simulation + your node/tests).

2) Prerequisites

Ubuntu 20.04+ recommended

Docker installed and your user allowed to run Docker

Jenkins running (WAR-based is fine, as in course Unit 2)

3) Start Jenkins
cd ~/webpage_ws
bash start_jenkins.sh
# Open the URL printed by the script (or http://localhost:8080)
# Get initial admin password:
cat ~/jenkins_home/secrets/initialAdminPassword


Complete the minimal setup (continue as admin; suggested plugins or none are fine).

4) Create the Jenkins Pipeline (points to this repo)

Jenkins → New Item → Pipeline → name it ros1_ci.

Pipeline → Definition: Pipeline script from SCM

SCM: Git

Repository URL: https://github.com/Andreas-Ioannou/checkpoint-24-task-1.git

Credentials: (none needed; repo is public)

Script Path: Jenkinsfile

Save.
(The Jenkinsfile already contains pollSCM('* * * * *'), so Jenkins checks for new commits every minute.)

What the job does on each run

Build Docker image from Dockerfile.

Run /test_waypoints.sh inside the container (no -it flags).

Publish JUnit results from ~/.ros/test_results.

Show full logs in Console Output.

5) How to trigger a build via Pull Request (for evaluation)

There are two roles: evaluator opens a small PR; student merges it.

A) Evaluator — open a PR

Visit https://github.com/Andreas-Ioannou/checkpoint-24-task-1.git.

Add file ▾ → Create new file.

Name it test_checkpoint.txt, add any short text (e.g., “Testing Checkpoint for student”).

At the bottom select Create a new branch for this commit and start a pull request.

Click Propose new file → Create pull request.

Inform the student to merge the PR.

B) Student — merge the PR

Repo → Pull requests → select the new PR.

Merge pull request → Confirm merge.

C) Jenkins reacts

Jenkins polls the repo every minute. After the merge, the job starts automatically.

Jenkins → job → Build History → latest build → Console Output to watch:

Docker image build

Headless Gazebo start (via rostest)

Tests running

Clean shutdown and SUCCESS (or failure details)

6) Manual (optional) commands

Build image locally:

cd ~/simulation_ws/src/ros1_ci
docker build -t ros1_ci:noetic .


Run tests (headless Gazebo) locally:

docker run --rm --network=host ros1_ci:noetic /test_waypoints.sh


JUnit results are produced under /root/.ros/test_results in the container.

7) Repository layout
ros1_ci/
├─ Dockerfile
├─ Jenkinsfile
├─ README.md
├─ .dockerignore
├─ scripts/
│  ├─ entrypoint.sh
│  ├─ run_sim.sh
│  └─ test_waypoints.sh