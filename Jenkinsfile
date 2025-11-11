library(
    identifier: 'jenkins-lib-common@feat/docker-stage',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git'
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

        stage('Build artifacts') {
            steps {
                dockerStage([
                    dockerfile: 'docker/mta/Dockerfile',
                    imageName: 'carbonio-mta',
                    ocLabels: [
                        title: 'Carbonio MTA',
                        descriptionFile: 'docker/mta/description.md',
                    ]
                ])

                echo 'Building deb/rpm packages'
                buildStage([
                    buildFlags: ' -s '
                ])

                uploadStage(
                    packages: yapHelper.resolvePackageNames()
                )
            }
        }
    }
}
