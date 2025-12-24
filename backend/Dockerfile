FROM python:3.10-slim

WORKDIR /code

# Copy requirements and install dependencies
COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copy the app code
COPY ./app /code/app
COPY ./alembic /code/alembic
COPY ./alembic.ini /code/alembic.ini
COPY ./entrypoint.sh /code/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /code/entrypoint.sh

# Cloud Run expects port 8080
EXPOSE 8080

# Run migrations and start server
ENTRYPOINT ["/code/entrypoint.sh"]
