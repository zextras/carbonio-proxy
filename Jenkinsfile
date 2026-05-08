library(
        identifier: 'jenkins-dt2-lib@main',
        retriever: modernSCM([
                $class: 'GitSCMSource',
                credentialsId: 'jenkins-integration-with-github-account',
                remote: 'git@github.com:zextras/jenkins-dt2-lib.git',
        ])
)

String profile = env.TAG_NAME ? '-Pprod' : ''

defaultPipeline {

    withMaven {
        withEnv([
                'MAVEN_OPTS=-Xmx2g',
                "MAVEN_ARGS=-B -s ${SETTINGS_PATH} -Ddebug=0 -Dis-production=1 ${profile} -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn",
        ]) {
            stage('Build') {
                sh 'mvn -DskipTests=true clean install'
                stash includes: 'target/proxyconfgen.jar', name: 'staging'
            }

            stage('Tests') {
                sh 'mvn verify'
                junit allowEmptyResults: true,
                        testResults: '**/target/surefire-reports/*.xml,**/target/failsafe-reports/*.xml'
            }

            stage('Sonarqube Analysis') {
                withSonarQube {
                    sh 'mvn sonar:sonar -Dsonar.junit.reportPaths=target/surefire-reports,target/failsafe-reports'
                }
            }
        }
    }

    stage('Build and upload artifacts') {
        parallel(
                'Packages': {
                    stage('Build deb/rpm') {
                        echo 'Building deb/rpm packages'
                        buildStage(buildFlags: ' -ds ')
                    }
                    stage('Publish packages') {
                        withJfrog {
                            uploadStage(packages: yapHelper.resolvePackageNames())
                        }
                    }
                },
                'Docker images': {
                    stage('Build and Publish Docker images') {
                        withCredentials([usernamePassword(
                                credentialsId: 'artifactory-jenkins-gradle-properties-splitted',
                                usernameVariable: 'USERNAME',
                                passwordVariable: 'SECRET',
                        )]) {
                            try {
                                sh '''
set +x
cat > auth.conf <<EOF
machine zextras.jfrog.io
login $USERNAME
password $SECRET
EOF
'''
                                dockerStage([
                                        dockerfile: 'Dockerfile',
                                        imageName : 'carbonio-proxy',
                                        ocLabels  : [title: 'Carbonio Proxy'],
                                ])
                                dockerStage([
                                        dockerfile: 'Dockerfile-sidecar',
                                        imageName : 'carbonio-proxy-sidecar',
                                        ocLabels  : [title: 'Carbonio Proxy Sidecar'],
                                ])
                            } finally {
                                sh 'rm -f auth.conf'
                            }
                        }
                    }
                },
        )
    }
}
