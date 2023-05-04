FROM node:latest

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci
RUN npx prisma generate

COPY src src/
COPY tsconfig.json ./

RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "dist/app.js"]