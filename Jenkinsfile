#!groovy

pipeline {
  options {
    gitLabConnection('gitlab@cr.imson.co')
    gitlabBuilds(builds: ['jenkins'])
    disableConcurrentBuilds()
    timestamps()
  }
  post {
    failure {
      updateGitlabCommitStatus name: 'jenkins', state: 'failed'
    }
    unstable {
      updateGitlabCommitStatus name: 'jenkins', state: 'failed'
    }
    aborted {
      updateGitlabCommitStatus name: 'jenkins', state: 'canceled'
    }
    success {
      updateGitlabCommitStatus name: 'jenkins', state: 'success'
    }
    always {
      cleanWs()
    }
  }
  agent any
  environment {
    CI = 'true'
  }
  stages {
    stage('Prepare') {
      steps {
        updateGitlabCommitStatus name: 'jenkins', state: 'running'
      }
    }
    stage('QA') {
      steps {
        sh 'find . -type f -iname "*.sh" -print0 | xargs -0 bash -n'
      }
    }
    stage('Build image') {
      steps {
        script {
          withDockerRegistry(credentialsId: 'e22deec5-510b-4fbe-8916-a89e837d1b8d', url: 'https://docker.cr.imson.co/v2/') {
            withCredentials([file(credentialsId: '24f103dd-4f2d-4714-94f7-77478831dca8', variable: 'GIT_CONFIG_FILE')]) {
              sh "cp ${env.GIT_CONFIG_FILE} ${env.WORKSPACE}/.gitconfig"
              docker.build('docker.cr.imson.co/git-mirror').push()
            }
          }
        }
      }
    }
  }
}
