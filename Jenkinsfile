library(
    identifier: 'jenkins-packages-build-library@1.0.4',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        remote: 'git@github.com:zextras/jenkins-packages-build-library.git',
        credentialsId: 'jenkins-integration-with-github-account'
    ])
)

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

    parameters {
        booleanParam defaultValue: false, 
            description: 'Whether to upload the packages in playground repositories', 
            name: 'PLAYGROUND'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '25'))
        skipDefaultCheckout()
        timeout(time: 2, unit: 'HOURS')
    }

    tools {
        jfrog 'jfrog-cli'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    gitMetadata()
                }
            }
        }

        stage('Publish containers - devel') {
            when {
                expression {
                    return env.TAG_NAME?.trim() || env.BRANCH_NAME == 'devel'
                }
            }
            steps {
                container('dind') {
                    withDockerRegistry(credentialsId: 'private-registry', url: 'https://registry.dev.zextras.com') {
                        script {
                            dockerHelper.buildImage([
                                dockerfile: 'Dockerfile',
                                imageName: 'registry.dev.zextras.com/dev/carbonio-proxy',
                                tags: ['latest'],
                                ocLabels: [
                                    title: 'Carbonio Proxy',
                                    description: 'Carbonio Proxy container',
                                ]
                            ])
                        }
                    }
                }
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
            steps {
                uploadStage(
                    packages: yapHelper.getPackageNames()
                )
            }
        }
    }
}
