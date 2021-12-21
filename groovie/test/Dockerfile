FROM python:3.8-alpine
# Copying app to /app directory in container
COPY src /app
# Changing working directory
WORKDIR /app
# Installing requirements
RUN apk update && pip install -r requirements.txt --no-cache-dir
# Listening port 5000
EXPOSE 5000
# Running the app
CMD ["python", "app.py"]