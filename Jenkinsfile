def buildContainer(String title, String description, String dockerfile, String tag) {
    sh 'docker build ' +
            '--label org.opencontainers.image.title="' + title + '" ' +
            '--label org.opencontainers.image.description="' + description + '" ' +
            '--label org.opencontainers.image.vendor="Zextras" ' +
            '-f ' + dockerfile + ' -t ' + tag + ' .'
    sh 'docker push ' + tag
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
        stage('Publish containers - devel') {
            when {
                branch 'devel';
            }
            steps {
                container('dind') {
                    withDockerRegistry(credentialsId: 'private-registry', url: 'https://registry.dev.zextras.com') {
                        buildContainer('Carbonio Proxy', 'Carbonio Proxy container',
                                'Dockerfile', 'registry.dev.zextras.com/dev/carbonio-proxy:latest')
                    }
                }
            }
        }
        stage('Build deb/rpm') {
            stages {
                stage('Stash') {
                    steps {
                        sh 'cp conf/nginx/errors/* package/proxy'
                        sh 'cp conf/nginx/templates/* package/proxy'
                        stash includes: '**', name: 'staging'
                    }
                }
                stage('yap') {
                    parallel {
                        stage('Ubuntu 20') {
                            agent {
                                node {
                                    label 'yap-ubuntu-20-v1'
                                }
                            }
                            steps {
                                container('yap') {
                                    unstash 'staging'
                                    script {
                                        if (BRANCH_NAME == 'devel') {
                                            def timestamp = new Date().format('yyyyMMddHHmmss')
                                            sh "yap build ubuntu-focal package -r ${timestamp} -s"
                                        } else {
                                            sh 'yap build ubuntu-focal package -s'
                                        }
                                    }
                                    stash includes: 'artifacts/*focal*.deb', name: 'artifacts-ubuntu-focal'
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/*focal*.deb', fingerprint: true
                                }
                            }
                        }
                        stage('Ubuntu 22') {
                            agent {
                                node {
                                    label 'yap-ubuntu-22-v1'
                                }
                            }
                            steps {
                                container('yap') {
                                    unstash 'staging'
                                    script {
                                        if (BRANCH_NAME == 'devel') {
                                            def timestamp = new Date().format('yyyyMMddHHmmss')
                                            sh "yap build ubuntu-jammy package -r ${timestamp} -s"
                                        } else {
                                            sh 'yap build ubuntu-jammy package -s'
                                        }
                                    }
                                    stash includes: 'artifacts/*jammy*.deb', name: 'artifacts-ubuntu-jammy'
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/*jammy*.deb', fingerprint: true
                                }
                            }
                        }
                        stage('Ubuntu 24') {
                            agent {
                                node {
                                    label 'yap-ubuntu-24-v1'
                                }
                            }
                            steps {
                                container('yap') {
                                    unstash 'staging'
                                    script {
                                        if (BRANCH_NAME == 'devel') {
                                            def timestamp = new Date().format('yyyyMMddHHmmss')
                                            sh "yap build ubuntu-noble package -r ${timestamp} -s"
                                        } else {
                                            sh 'yap build ubuntu-noble package -s'
                                        }
                                    }
                                    stash includes: 'artifacts/*noble*.deb', name: 'artifacts-ubuntu-noble'
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/*noble*.deb', fingerprint: true
                                }
                            }
                        }
                        stage('RHEL8') {
                            agent {
                                node {
                                    label 'yap-rocky-8-v1'
                                }
                            }
                            steps {
                                container('yap') {
                                    unstash 'staging'
                                    script {
                                        if (BRANCH_NAME == 'devel') {
                                            def timestamp = new Date().format('yyyyMMddHHmmss')
                                            sh "yap build rocky-8 package -r ${timestamp} -s"
                                        } else {
                                            sh 'yap build rocky-8 package -s'
                                        }
                                    }
                                    stash includes: 'artifacts/*el8*.rpm', name: 'artifacts-rhel8'
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/*el8*.rpm', fingerprint: true
                                }
                            }
                        }
                        stage('RHEL9') {
                            agent {
                                node {
                                    label 'yap-rocky-9-v1'
                                }
                            }
                            steps {
                                container('yap') {
                                    unstash 'staging'
                                    script {
                                        if (BRANCH_NAME == 'devel') {
                                            def timestamp = new Date().format('yyyyMMddHHmmss')
                                            sh "yap build rocky-9 package -r ${timestamp} -s"
                                        } else {
                                            sh 'yap build rocky-9 package -s'
                                        }
                                    }
                                    stash includes: 'artifacts/*el9*.rpm', name: 'artifacts-rhel9'
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/*el9*.rpm', fingerprint: true
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('Upload To Devel') {
            when {
                branch 'devel'
            }
            steps {
                unstash 'artifacts-ubuntu-focal'
                unstash 'artifacts-ubuntu-jammy'
                unstash 'artifacts-ubuntu-noble'
                unstash 'artifacts-rhel8'
                unstash 'artifacts-rhel9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = """{
                        "files": [
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/*jammy*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/*noble*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el8.x86_64.rpm",
                                "target": "centos8-devel/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el9.x86_64.rpm",
                                "target": "rhel9-devel/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload To Playground') {
            when {
                anyOf {
                    branch 'playground/*'
                    expression { params.PLAYGROUND == true }
                }
            }
            steps {
                unstash 'artifacts-ubuntu-focal'
                unstash 'artifacts-ubuntu-jammy'
                unstash 'artifacts-ubuntu-noble'
                unstash 'artifacts-rhel8'
                unstash 'artifacts-rhel9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = """{
                        "files": [
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/*jammy*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/*noble*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el8.x86_64.rpm",
                                "target": "centos8-playground/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el9.x86_64.rpm",
                                "target": "rhel9-playground/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload & Promotion Config') {
            when {
                anyOf {
                    branch 'release/*'
                    buildingTag()
                }
            }
            steps {
                unstash 'artifacts-ubuntu-focal'
                unstash 'artifacts-ubuntu-jammy'
                unstash 'artifacts-ubuntu-noble'
                unstash 'artifacts-rhel8'
                unstash 'artifacts-rhel9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    def config

                    // ubuntu
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += '-ubuntu'
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/*jammy*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            },
                            {
                                "pattern": "artifacts/*noble*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64;vcs.revision=${env.GIT_COMMIT}"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'ubuntu-rc',
                            'targetRepo'         : 'ubuntu-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: 'Ubuntu Promotion to Release'
                    server.publishBuildInfo buildInfo

                    // rocky8
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += '-centos8'
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el8.x86_64.rpm",
                                "target": "centos8-rc/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'centos8-rc',
                            'targetRepo'         : 'centos8-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: 'Centos8 Promotion to Release'
                    server.publishBuildInfo buildInfo

                    // rocky9
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += '-rhel9'
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el9.x86_64.rpm",
                                "target": "rhel9-rc/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras;vcs.revision=${env.GIT_COMMIT}"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'rhel9-rc',
                            'targetRepo'         : 'rhel9-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: 'RHEL9 Promotion to Release'
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }
}
