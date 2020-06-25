def LABEL_ID = "questcod-${UUID.randomUUID().toString()}"

podTemplate(
    label: LABEL_ID, 
    containers: [
        containerTemplate(args: 'cat', name: 'docker-container', command: '/bin/sh -c', image: 'docker', ttyEnabled: true),
        containerTemplate(args: 'cat', name: 'helm-container', command: '/bin/sh -c', image: 'lachlanevenson/k8s-helm:latest', ttyEnabled: true)
    ],
    volumes: [
      hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
    ]
){
    def REPOS
    def IMAGE_VERSION
    def IMAGE_NAME = "questcode-frontend"
    def ENVIRONMENT = "staging"
    def GIT_URL = "git@github.com:sandrocaetano/questcode-frontend.git"
    def CHARTMUSEUM_URL = "http://chartmuseum-chartmuseum:8080"
    def DEPLOY_NAME = "questcode-frontend"
    def DEPLOY_CHART = "actarlab/questcode-frontend"
    def NODE_PORT = "30080"

    node(LABEL_ID) {
        stage('Checkout') {
            echo 'Iniciando Clone do Repositorio'
            REPOS = checkout scm
            GIT_BRANCH = REPOS.GIT_BRANCH

            if(GIT_BRANCH.equals("origin/master")) {
                KUBE_NAMESPACE = "production"
            } else if(GIT_BRANCH.equals("origin/develop")) {
                KUBE_NAMESPACE = "staging"
                NODE_PORT = "31080"
            } else {
                def error = "Nao existe pipeline para a branch ${GIT_BRANCH}"
                echo error
                throw new Exception(error)
            }

            IMAGE_VERSION = sh returnStdout: true, script: 'sh read-package-version.sh'
            IMAGE_VERSION = IMAGE_VERSION.trim()
        }
        stage('Package') {
            container('docker-container') {
                echo 'Iniciando Empacotamento com Docker'
                withCredentials([usernamePassword(credentialsId: 'dockerhubid', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USER')]) {
                    sh "docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}"
                    sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_VERSION} --build-arg NPM_ENV='${KUBE_NAMESPACE}' ."
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_VERSION}"
                }
            }
        }
    }
    node(LABEL_ID) {
        stage('Deploy') {
            container('helm-container') {
                echo 'Iniciando o Deploy com Helm'
                sh "helm repo add actarlab ${CHARTMUSEUM_URL}"
                sh 'helm repo update'
                sh "helm upgrade --install ${DEPLOY_NAME} ${DEPLOY_CHART} --set image.tag=${IMAGE_VERSION} --set NodePort=${NODE_PORT} -n ${KUBE_NAMESPACE}"
            }
        }
    }
}