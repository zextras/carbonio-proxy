library(
    identifier: 'jenkins-lib-common@1.5.0',
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
                dockerStage([
                        dockerfile: 'Dockerfile',
                        imageName : 'carbonio-proxy',
                        ocLabels  : [
                                title : 'Carbonio Proxy'
                        ]
                ])
                dockerStage([
                        dockerfile: 'Dockerfile-sidecar',
                        imageName : 'carbonio-proxy-sidecar',
                        ocLabels  : [
                                title : 'Carbonio Proxy Sidecar'
                        ]
                ])
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
                    buildFlags: ' -ds '
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
            steps {
                script {
                    dt2_semanticRelease()
                }
            }
        }
    }
}
