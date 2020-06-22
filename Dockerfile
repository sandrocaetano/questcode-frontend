FROM node as builder
ARG NPM_ENV=development

WORKDIR /app
COPY package.json .
RUN npm install

COPY src/ ./src/
COPY public ./public/

RUN npm run build:${NPM_ENV}

FROM nginx
COPY --from=builder /app/build/ /usr/share/nginx/html
EXPOSE 80
