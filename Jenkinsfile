library(
    identifier: 'jenkins-lib-common@1.3.1',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)



properties(defaultPipelineProperties())

boolean isBuildingTag() {
    return env.TAG_NAME ? true : false
}

boolean isCommitTagged() {
    return env.GIT_TAG ? true : false
}

String profile = isBuildingTag() ? '-Pprod' : ''

pipeline {
    agent {
        node {
            label 'zextras-v1'
        }
    }

    environment {
        MVN_OPTS = "-Ddebug=0 -Dis-production=1 ${profile}"
        JAVA_OPTS = '-Dfile.encoding=UTF8'
        jenkins_build = 'true'
        LC_ALL = 'C.UTF-8'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '25'))
        skipDefaultCheckout()
        timeout(time: 2, unit: 'HOURS')
    }

    stages {

        stage('Setup') {
            steps {
                checkout scm
                script {
                    gitMetadata()
                }
            }
        }

        stage('Build') {
            steps {
                container('jdk-21') {
                    sh """
                        mvn ${MVN_OPTS} \
                            -DskipTests=true \
                            clean install
                    """
                    stash includes: 'target/proxyconfgen.jar', name: 'staging'
                }
            }
        }

        stage('Tests') {
            steps {
                container('jdk-21') {
                    sh "mvn ${MVN_OPTS} verify"
                }
                junit allowEmptyResults: true,
                        testResults: '**/target/surefire-reports/*.xml,**/target/failsafe-reports/*.xml'
            }
        }

        stage('Sonarqube Analysis') {
            steps {
                container('jdk-21') {
                    withSonarQubeEnv(credentialsId: 'sonarqube-user-token', installationName: 'SonarQube instance') {
                        sh """
                            mvn ${MVN_OPTS} \
                                sonar:sonar \
                                -Dsonar.junit.reportPaths=target/surefire-reports,target/failsafe-reports
                        """
                    }
                }
            }
        }

        stage('Docker build') {
            steps {
                container('dind') {
                    withDockerRegistry(credentialsId: 'private-registry', url: 'https://registry.dev.zextras.com') {
                        sh 'docker build .'
                    }
                }
            }
        }

        stage('Publish containers - devel') {
            steps {
                dockerStage([
                    dockerfile: 'Dockerfile',
                    imageName: 'carbonio-proxy',
                    ocLabels: [
                        title: 'Carbonio Proxy',
                        description: 'Carbonio Proxy container',
                    ]
                ])
            }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                buildStage([
                    buildFlags: ' -s '
                ])
            }
        }

        stage('Upload artifacts')
        {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage(
                    packages: yapHelper.resolvePackageNames()
                )
            }
        }

        stage('Bump version') {
            agent {
                node {
                    label 'nodejs-v1'
                }
            }
            when {
                allOf {
                    branch 'main'
                    expression { !isCommitTagged() }
                }
            }
            steps {
                script {
                    checkout scm
                    gitMetadata()
                    container('nodejs-20') {
                        withCredentials([usernamePassword(credentialsId: 'jenkins-integration-with-github-account', usernameVariable: 'GH_USERNAME', passwordVariable: 'GH_TOKEN')]) {
                            sh 'apt-get update && apt-get install -y jq openssh-client'
                            sh """
                            npx \
                            --package semantic-release \
                            --package @semantic-release/commit-analyzer \
                            --package @semantic-release/release-notes-generator \
                            --package @semantic-release/exec \
                            --package @semantic-release/git \
                            --package conventional-changelog-conventionalcommits \
                            semantic-release
                        """
                        }
                    }
                }
            }
        }
    }
}
