FROM alpine:latest

RUN apk add --no-cache python3 py3-pip
RUN pip3 install --upgrade pip; pip3 install flask gunicorn; mkdir /plugin 

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
COPY plugin.py /plugin


# Set the entry point to run the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

