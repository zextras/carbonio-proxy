library(
    identifier: 'jenkins-lib-common@v4.10.7',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)

properties(defaultPipelineProperties())

pipeline {
    agent {
        node {
            label 'zextras-v1'
        }
    }

    environment {
        JAVA_OPTS = '-Dfile.encoding=UTF8'
        jenkins_build = 'true'
        LC_ALL = 'C.UTF-8'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '25'))
        disableConcurrentBuilds()
        skipDefaultCheckout()
        timeout(time: 2, unit: 'HOURS')
    }

    stages {
        stage('Setup') {
            steps {
                checkout scm
                gitMetadata()
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    gitleaksStage()
                }
            }
        }

        stage('Maven') {
            steps {
                script {
                    mavenStage()
                }
            }
        }

        stage('Build and upload artifacts') {
            parallel {
                stage('Packages') {
                    stages {
                        stage('Build deb/rpm') {
                            steps {
                                buildStage(buildFlags: ' -ds ', useDefaultExcludes: false)
                            }
                        }
                        stage('Upload artifacts') {
                            tools {
                                jfrog 'jfrog-cli'
                            }
                            steps {
                                uploadStage()
                            }
                        }
                    }
                }
                stage('Docker images') {
                    steps {
                        dockerStage([
                                dockerfile: 'Dockerfile',
                                imageName : 'carbonio-proxy',
                                ocLabels  : [title: 'Carbonio Proxy'],
                                platforms : ['linux/amd64', 'linux/arm64'] as Set,
                        ])
                        dockerStage([
                                dockerfile: 'Dockerfile-sidecar',
                                imageName : 'carbonio-proxy-sidecar',
                                ocLabels  : [title: 'Carbonio Proxy Sidecar'],
                                platforms : ['linux/amd64', 'linux/arm64'] as Set,
                        ])
                    }
                }
            }
        }

        stage('Bump version') {
            steps {
                script {
                    semanticRelease()
                }
            }
        }
    }
}
