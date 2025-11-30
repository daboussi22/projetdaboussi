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
                    waitForQualityGate abortPipeline: false
                }
            }
        }

       stage('SCA with Trivy') {
           steps {
               sh '''
                   trivy fs . --severity CRITICAL,HIGH --format json --exit-code 1 --output trivy-fs-report.json
                   trivy image timesheet-devops-1.0 --severity CRITICAL,HIGH --format json --exit-code 1 --output trivy-image-report.json
               '''
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
                            --exit-code 1
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
                archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
            }
        }

        stage('DockerHub Login & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        docker build -t $DOCKER_USER/timesheet-devops-1.0 .
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $DOCKER_USER/timesheet-devops-1.0
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
