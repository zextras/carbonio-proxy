pipeline {
    agent {
        node {
            label 'carbonio-agent-v1'
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
                        stage('Ubuntu') {
                            agent {
                                node {
                                    label 'yap-agent-ubuntu-20.04-v2'
                                }
                            }
                            steps {
                                unstash 'staging'
                                script {
                                    if (BRANCH_NAME == 'devel') {
                                        def timestamp = new Date().format('yyyyMMddHHmmss')
                                        sh "yap build ubuntu package -r ${timestamp} -s"
                                    } else {
                                        sh 'yap build ubuntu package -s'
                                    }
                                }
                                stash includes: 'artifacts/*.deb', name: 'artifacts-deb'
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/*.deb', fingerprint: true
                                }
                            }
                        }
                        stage('RHEL8') {
                            agent {
                                node {
                                    label 'yap-agent-rocky-8-v2'
                                }
                            }
                            steps {
                                unstash 'staging'
                                script {
                                    if (BRANCH_NAME == 'devel') {
                                        def timestamp = new Date().format('yyyyMMddHHmmss')
                                        sh "yap build rocky-8 package -r ${timestamp} -s"
                                    } else {
                                        sh 'yap build rocky-8 package -s'
                                    }
                                }
                                stash includes: 'artifacts/x86_64/*el8*.rpm', name: 'artifacts-rhel8'
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/x86_64/*el8*.rpm', fingerprint: true
                                }
                            }
                        }
                        stage('RHEL9') {
                            agent {
                                node {
                                    label 'yap-agent-rocky-9-v2'
                                }
                            }
                            steps {
                                unstash 'staging'
                                script {
                                    if (BRANCH_NAME == 'devel') {
                                        def timestamp = new Date().format('yyyyMMddHHmmss')
                                        sh "yap build rocky-9 package -r ${timestamp} -s"
                                    } else {
                                        sh 'yap build rocky-9 package -s'
                                    }
                                }
                                stash includes: 'artifacts/x86_64/*el9*.rpm', name: 'artifacts-rhel9'
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: 'artifacts/x86_64/*el9*.rpm', fingerprint: true
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
                unstash 'artifacts-deb'
                unstash 'artifacts-rhel8'
                unstash 'artifacts-rhel9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = '''{
                        "files": [
                            {
                                "pattern": "artifacts/carbonio-proxy*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=focal;deb.distribution=jammy;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-proxy)-(*).el8.x86_64.rpm",
                                "target": "centos8-devel/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-proxy)-(*).el9.x86_64.rpm",
                                "target": "rhel9-devel/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }'''
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
                unstash 'artifacts-deb'
                unstash 'artifacts-rhel8'
                unstash 'artifacts-rhel9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = '''{
                        "files": [
                            {
                                "pattern": "artifacts/carbonio-proxy*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=focal;deb.distribution=jammy;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/(carbonio-proxy)-(*).el8.x86_64.rpm",
                                "target": "centos8-playground/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-proxy)-(*).el9.x86_64.rpm",
                                "target": "rhel9-playground/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }'''
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
                unstash 'artifacts-deb'
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
                    uploadSpec= '''{
                        "files": [
                            {
                                "pattern": "artifacts/carbonio-proxy*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=focal;deb.distribution=jammy;deb.component=main;deb.architecture=amd64"
                            }
                        ]
                    }'''
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
                    uploadSpec= '''{
                        "files": [
                            {
                                "pattern": "artifacts/x86_64/(carbonio-proxy)-(*).el8.x86_64.rpm",
                                "target": "centos8-rc/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }'''
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
                    uploadSpec= '''{
                        "files": [
                            {
                                "pattern": "artifacts/x86_64/(carbonio-proxy)-(*).el9.x86_64.rpm",
                                "target": "rhel9-rc/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }'''
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

