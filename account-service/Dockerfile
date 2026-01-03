FROM node:18-alpine AS build


WORKDIR /app


COPY . .


FROM node:18-alpine


COPY --from=build /app .


CMD ["node", "app.js"]
