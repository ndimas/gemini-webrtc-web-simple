# Stage 1: Build the web app
FROM node:20-slim AS web-builder

WORKDIR /app

# Copy web app package.json and lockfile
COPY package*.json ./

# Install web app dependencies
RUN npm install

# Copy the rest of the web app code
COPY . .

# Build the web app
RUN npm run build

# Stage 2: Build the Python server
FROM python:3.12-slim AS server-builder

WORKDIR /server

# Copy python server requirements and environment config
COPY server/requirements.txt server/env.example ./

# Create a python virtual environment
RUN python3 -m venv venv
ENV VIRTUAL_ENV /server/venv
ENV PATH "$VIRTUAL_ENV/bin:$PATH"

# Install python server dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the python server code
COPY server .

# Stage 3: Final image
FROM python:3.12-slim

# Copy built web app
COPY --from=web-builder /app/dist /app/dist
WORKDIR /app

# Copy python server
COPY --from=server-builder /server /server
ENV VIRTUAL_ENV /server/venv
ENV PATH "$VIRTUAL_ENV/bin:$PATH"


# Install uvicorn and gunicorn
RUN pip install uvicorn gunicorn

# Expose the ports
EXPOSE 7860
EXPOSE 5173

# Command to run both the Python server and the web app
CMD  gunicorn -w 4 -k uvicorn.workers.UvicornWorker server.server:app --bind 0.0.0.0:7860  & npm run preview -- --port 5173 --host 0.0.0.0
