pipeline {
    agent any

    environment {
        SONAR_PROJECT_KEY   = 'timesheet-devops'
        SONAR_PROJECT_NAME  = 'Timesheet DevOps'
    }

    stages {
        stage('Git') {
            steps {
                git branch: 'main', url: 'https://github.com/daboussi22/projetdaboussi.git'
            }
        }

        stage('Maven Build') {
            steps {
                sh "mvn clean compile install -DskipTests=true"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('MySonar') {
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                          -Dsonar.projectName='${SONAR_PROJECT_NAME}'
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: false // do not abort on failure
                }
            }
        }

        stage('SCA with Trivy') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                        trivy fs . --severity CRITICAL,HIGH --format json --exit-code 1 --output trivy-fs-report.json || true
                        trivy image timesheet-devops-1.0 --severity CRITICAL,HIGH --format json --exit-code 1 --output trivy-image-report.json || true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-*-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('DAST Scan with OWASP ZAP') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                        zap-baseline.py \
                            -t http://192.168.50.4:8080 \
                            -r zap_report.html \
                            -x zap_report.xml \
                            --exit-code 1 || true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap_report.*', allowEmptyArchive: true
                }
            }
        }

        stage('Secrets Scan (Gitleaks)') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                        gitleaks detect --source . --report-path gitleaks-report.json || true
                    '''
                }
                post {
                    always {
                        archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t timesheet-devops:1.0 .'
            }
        }

        stage('DockerHub Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker tag timesheet-devops:1.0 $DOCKER_USER/timesheet-devops:1.0
                        docker push $DOCKER_USER/timesheet-devops:1.0
                    '''
                }
            }
        }

        stage('Docker Compose Up') {
            steps {
                sh 'docker compose up -d'
            }
        }
    }
}
