library(
    identifier: 'jenkins-lib-common@1.7.2',
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

        stage('Maven') {
            steps {
                script {
                    mavenStage(
                        profile: env.TAG_NAME ? '-Pprod' : '',
                        mvnOpts: ['Ddebug': '0', 'Dis-production': '1'],
                        extraSonarArgs: '-Dsonar.junit.reportPaths=target/surefire-reports,target/failsafe-reports'
                    )
                }
                stash includes: 'target/proxyconfgen.jar', name: 'staging'
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
