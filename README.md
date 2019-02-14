## Install and run the prototype

#### You'll need:

- a Github account, if not: [create a Github account](https://github.com/join)
- a computer with SSH access to Github, [check if you have and how to get a SSH key ](https://help.github.com/articles/checking-for-existing-ssh-keys/)
- nodeJS, if not: [install nodeJS](https://nodejs.org/en/)


### Download the prototype:

1. press **'Clone or download'**
2. press **'Use SSH'** and copy the **'SSH key'**
3. open your Terminal app: `⌘ + space`, type `terminal` and hit `enter ⏎`
4. navigate to a place to put prototype e.g: `cd Desktop`
5. clone this repository `git clone [SSH key]`


### Install and run the prototype:

1. in your terminal, navigate to the prototype e.g: `cd [prototype name]`
2. install dependancies with the command: `npm install`
3. start the server with: `npm start`
4. stop the server with: `ctrl + c`


***

## Hosting a prototype on Azure

### You'll need:
- An Azure account with permission to create objects.
- Azure CLI installed locally on your laptop. on a mac: `brew install azure-cli`
- Site source code on github.
- A name for your prototype. The name must be globally unique on the entire Azure platform (not just DfE) so make it specific. It also needs to be allowable as a host name. The prototype will be accessed with the url https://{protoname}.azurewebsites.net.
- If you’re deploying an app-based site, Docker installed locally on your laptop. Docker Desktop for Mac is highly recommended.

### Setup on azure:

1. Log into azure cli `az login`
2. Create a new resource group for your prototype. `az group create --location uksouth --name {protoname}`.
3. Create a service plan for your prototype. `az appservice plan create --name {protoname} --resource-group {protoname} --sku B1 --is-linux`
4. Create a container registry for your prototype. This will hold the docker image of your web app. `az acr create --name {protoname} --resource-group {protoname} --sku Basic --admin-enabled`

### Run the prototype locally:

5. Clone your git repo locally on your laptop.
6. Ensure the root of the repo contains a Dockerfile like the example at the end of this document.
7. Install any node dependencies. `npm i`
8. Build a docker image of your app. `docker build -t {protoname}.azurecr.io/{protoname} .`

### Link the dockerfile with azure 

9. Find out the automatically generated password for your private registry. `az acr credential show --name {protoname} --query "passwords[0].value"`
10. Log into the private container registry you created at step 4. Username is your prototype name, password from step 9. `docker login {protoname}.azurecr.io`
11. Upload the docker image you created in step 8 to the private registry `docker push {protoname}.azurecr.io/{protoname}`
12. Create a basic web app with temporary runtime environment. `az webapp create --name {protoname} --resource-group {protoname} --plan {protoname} --runtime "RUBY|2.3"`
13. Update web app to point at docker image. `az webapp config container set --resource-group {protoname} --name {protoname} --docker-custom-image-name "DOCKER|{protoname}.azurecr.io/{protoname}:latest" --docker-registry-server-url https://{protoname}.azurecr.io --docker-registry-server-user {protoname} --docker-registry-server-password {password from step 9}`
14. Enable Continuous Delivery mode for the web app. This will automatically restart the webapp whenever a new docker image is pushed to the registry. Take a note of "CI_CD_URL" that is returned from this command. `az webapp deployment container config --resource-group {protoname} --name {protoname} --enable-cd true`
15. Create a web hook between your repository and the web app using the CI_CD_URL from step 14. `az acr webhook create --name {protoname} --resource-group {protoname} --registry {protoname} --uri {CI_CD_URL} --actions push --scope {protoname}:latest`
16. Tell the web app which port to use to communicate with the docker container `usually 3000 for node`. `az webapp config appsettings set --resource-group {protoname} --name {protoname} --settings WEBSITES_PORT=3000`
17. At this point you will probably need to restart the web app. `az webapp restart --resource-group {protoname} --name {protoname}`

**To redeploy the app after changes on github repeat steps 5 - 10.**

Your app should automatically restart when changes are pushed to the container registry. If it fails to do so do `az webapp stop --resource-group {protoname} --name {protoname}` and `az webapp start --resource-group {protoname} --name {protoname}`. Aka turn it off and on again.

#### Appendix 1: Sample DockerFile for Node

```
FROM ubuntu:latest

RUN mkdir /home/nrsproto
WORKDIR /home/nrsproto
COPY app ./app/
COPY lib ./lib/
COPY node_modules ./node_modules/
COPY *.json ./
COPY *.js ./
COPY public ./public/
COPY docs ./docs/

RUN apt-get update && apt-get install -y nodejs

EXPOSE 3000
CMD node /home/nrsproto/server.js
```

