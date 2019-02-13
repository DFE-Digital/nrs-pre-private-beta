FROM ubuntu:latest

RUN mkdir /home/nrsalpharound4
WORKDIR /home/nrsalpharound4
COPY app ./app/
COPY lib ./lib/
COPY node_modules ./node_modules/
COPY *.json ./
COPY *.js ./
COPY public ./public/
COPY docs ./docs/

RUN apt-get update && apt-get install -y nodejs

EXPOSE 3000

CMD node /home/nrsalpharound4/server.js
