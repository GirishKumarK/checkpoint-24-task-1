pipeline {
  agent any

  environment {
    IMAGE_NAME = "ros1_ci:noetic"
    WORKDIR    = "simulation_ws/src/ros1_ci"
  }

  // ✅ Unit 10 alignment: build soon after PR is accepted (merge -> push to default branch)
  triggers {
    pollSCM('* * * * *')   // poll every minute (matches course instructions)
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        dir("${WORKDIR}") {
          sh 'echo "Repo at: $(pwd)" && ls -la'
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        dir("${WORKDIR}") {
          sh '''
            docker build -t ${IMAGE_NAME} .
            docker image ls ${IMAGE_NAME}
          '''
        }
      }
    }

    stage('Run ROS Waypoints Tests (rostest)') {
      steps {
        dir("${WORKDIR}") {
          // ✅ No "-it" here; Jenkins is not a TTY.
          // Host networking simplifies ROS master discovery.
          sh '''
            set -e
            rm -rf test_artifacts && mkdir -p test_artifacts

            # run tests; rostest will bring nodes up and shut them down on completion
            # your /test_waypoints.sh internally calls:
            #   rostest tortoisebot_waypoints waypoints_action.test
            docker run --rm --network=host \
              ${IMAGE_NAME} bash -lc "/test_waypoints.sh" || TEST_FAILED=1

            # collect junit xml produced by rostest
            CID=$(docker create ${IMAGE_NAME} true)
            docker cp "$CID":/root/.ros/test_results ./test_artifacts/ || true
            docker rm "$CID" >/dev/null

            # propagate failure to Jenkins if tests failed
            if [ "${TEST_FAILED:-0}" = "1" ]; then exit 1; fi
          '''
        }
      }
      post {
        always {
          dir("${WORKDIR}") {
            // publish rostest JUnit XML, even if empty/failing
            junit allowEmptyResults: true, testResults: 'test_artifacts/test_results/**/*.xml'
            archiveArtifacts artifacts: 'test_artifacts/**', onlyIfSuccessful: false
          }
        }
      }
    }
  }

  post {
    success { echo '✅ Tests passed and Gazebo shut down cleanly.' }
    failure { echo '❌ Tests failed. See Console Output + JUnit details.' }
  }
}
