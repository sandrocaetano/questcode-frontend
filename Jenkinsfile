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
    def GIT_URL = "git@github.com:sandrocaetano/questcode-frontend.git"
    def CHARTMUSEUM_URL = "http://chartmuseum-lab-chartmuseum:8080"
    def DEPLOY_NAME = "questcode-frontend"
    def DEPLOY_CHART = "actarlab/questcode-frontend"
    def INGRESS_HOST = "questcode.org"
    def VAULT_SERVER = [vaultUrl: 'http://192.168.0.18:8200',
                         vaultCredentialId: 'vault-token',
                         engineVersion: 1]


    node(LABEL_ID) {
        stage('Checkout') {
            echo 'Iniciando Clone do Repositorio'
            REPOS = checkout scm
            GIT_BRANCH = REPOS.GIT_BRANCH

            echo GIT_BRANCH

            if(GIT_BRANCH.equals("master")) {
                KUBE_NAMESPACE = "production"
            } else if(GIT_BRANCH.equals("develop")) {
                KUBE_NAMESPACE = "staging"
                INGRESS_HOST = "staging.questcode.org"
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
                def SECRETS = [
                    [path: 'secret/jenkins/dockerhub/credentials', engineVersion: 1, secretValues: [
                        [envVar: 'DOCKER_HUB_USER', vaultKey: 'username'],
                        [envVar: 'DOCKER_HUB_PASSWORD', vaultKey: 'password']]]]

                echo 'Iniciando Empacotamento com Docker'
                withVault([configuration: VAULT_SERVER, vaultSecrets: SECRETS]) {
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
                sh "helm upgrade --install ${DEPLOY_NAME} ${DEPLOY_CHART} --set image.tag=${IMAGE_VERSION} --set ingress.host[0]=${INGRESS_HOST} -n ${KUBE_NAMESPACE}"
            }
        }
    }
}
