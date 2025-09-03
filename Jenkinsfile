library identifier: 'mailbox-packages-lib@master', retriever: modernSCM(
        [$class: 'GitSCMSource',
         remote: 'git@github.com:zextras/jenkins-packages-build-library.git',
         credentialsId: 'jenkins-integration-with-github-account'])

def buildContainer(String title, String description, String dockerfile, String imageName, List<String> versions, String commitHash) {
    tagsToAdd = []
    versions.each {
        version -> tagsToAdd.add("-t " + imageName + ":" + version)
    }
    sh 'docker build ' +
            '--label org.opencontainers.image.title="' + title + '" ' +
            '--label org.opencontainers.image.description="' + description + '" ' +
            '--label org.opencontainers.image.vendor="Zextras" ' +
            '--label org.opencontainers.image.revision="' + commitHash + '" ' +
            '-f ' + dockerfile + ' ' + tagsToAdd.join(" ") + ' .'
    sh 'docker push --all-tags ' + imageName
}

def isBuildingTag() {
    return !!env.TAG_NAME
}


pipeline {
    agent {
        node {
            label 'zextras-v1'
        }
    }
    environment {
        JAVA_OPTS = '-Dfile.encoding=UTF8'
        LC_ALL = 'C.UTF-8'
        jenkins_build = 'true'
    }
    parameters {
        booleanParam defaultValue: false, description: 'Whether to upload the packages in playground repositories', name: 'PLAYGROUND'
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '25'))
        timeout(time: 2, unit: 'HOURS')
        skipDefaultCheckout()
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                }
            }
        }
        stage('Stash Nginx build files') {
            steps {
                stash includes: '**', name: 'staging'
            }
        }
        stage('Publish containers') {
            when {
                expression {
                    return isBuildingTag() || env.BRANCH_NAME == 'devel'
                }
            }
            steps {
                container('dind') {
                    withDockerRegistry(credentialsId: 'private-registry', url: 'https://registry.dev.zextras.com') {
                        script {
                            def commitHash = env.GIT_COMMIT
                            def tagVersions = []
                            if (isBuildingTag()) {
                                tagVersions.add(env.TAG_NAME)
                                tagVersions.add("stable")
                            } else {
                                tagVersions.add("devel")
                                tagVersions.add("latest")
                            }
                            buildContainer('Carbonio Proxy',
                                    'Carbonio Proxy container',
                                    'Dockerfile',
                                    'registry.dev.zextras.com/dev/carbonio-proxy',
                                    tagVersions,
                                    commitHash)
                        }
                    }
                }
            }
        }
        stage ('Build Packages') {
            steps {
                script {
                    buildStage(["carbonio-proxy"], 'staging', '.')()
                }
            }
        }
    }
}
