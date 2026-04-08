pipeline {
    agent any

    environment {
        GITHUB_REPO_URL    = 'https://github.com/cheikhtourad19/student-management.git'
        GITHUB_BRANCH      = 'main'
        SONAR_SERVER_NAME  = 'SonarServer'
        SONAR_HOST_URL     = 'http://192.168.56.11:9000'
        SONAR_PROJECT_KEY  = 'jenkins-sonar-key'
        SONAR_PROJECT_NAME = 'student-management'
        COMPOSE_PROJECT    = 'student-management'
        COMPOSE_FILE       = 'docker-compose.yaml'
    }

    stages {
        stage('Checkout') {
            steps {
                sh """
                    if [ -d ".git" ]; then
                        echo "Repo exists — pulling latest changes..."
                        git remote set-url origin ${env.GITHUB_REPO_URL} 2>/dev/null || git remote add origin ${env.GITHUB_REPO_URL}
                        git fetch origin
                        git reset --hard origin/${env.GITHUB_BRANCH}
                        git clean -fd
                    else
                        echo "First run — cloning repository..."
                        git clone -b ${env.GITHUB_BRANCH} ${env.GITHUB_REPO_URL} .
                    fi
                """
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean verify -DskipTests'
            }
        }

        stage('Static Analysis') {
            steps {
                withSonarQubeEnv(env.SONAR_SERVER_NAME) {

                        sh """
                            mvn sonar:sonar \
                                --batch-mode \
                                --no-transfer-progress \
                                -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                                -Dsonar.projectName='${env.SONAR_PROJECT_NAME}'
                        """
                    }

            }
        }


        stage('Quality Gate') {
            steps {
                echo "SonarQube analysis submitted. Check results at: ${env.SONAR_HOST_URL}/dashboard?id=${env.SONAR_PROJECT_KEY}"
            }
        }


        stage('Package') {
            steps {
                sh """
                    docker compose \
                        -p ${env.COMPOSE_PROJECT} \
                        -f ${env.WORKSPACE}/${env.COMPOSE_FILE} \
                        build --pull --no-cache --parallel
                """
            }
        }

        stage('Docker Compose Up') {
            steps {
                sh """
                    docker compose \
                        -p ${env.COMPOSE_PROJECT} \
                        -f ${env.WORKSPACE}/${env.COMPOSE_FILE} \
                        up -d --remove-orphans
                """
                sh "docker compose -p ${env.COMPOSE_PROJECT} -f ${env.WORKSPACE}/${env.COMPOSE_FILE} ps"
            }
        }

    }

    // ─────────────────────────────────────────────────────────────────────────
    // Post-build actions
    // ─────────────────────────────────────────────────────────────────────────
    post {
        success {
            echo "Pipeline completed SUCCESSFULLY — Build #${env.BUILD_NUMBER}"
        }

        failure {
            echo "Pipeline FAILED — Build #${env.BUILD_NUMBER}"
        }

        unstable {
            echo 'Pipeline is UNSTABLE — tests may have failed. Check test reports.'
        }

        always {
            sh """
                docker compose \
                    -p ${env.COMPOSE_PROJECT} \
                    -f ${env.WORKSPACE}/${env.COMPOSE_FILE} \
                    down --volumes --remove-orphans || true
            """
        }
    }
}
