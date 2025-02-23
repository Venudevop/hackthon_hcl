# Use Node.js official image as a base image
FROM node:14

# Set the working directory inside the container
WORKDIR /app

# Copy both package.json and package-lock.json to the container
COPY patient*.js ./

# Install dependencies based on package-lock.json
RUN npm install

# Expose the application port (if relevant)
EXPOSE 3000

# Start the app (replace with your app's start command)
CMD ["npm", "start"]
