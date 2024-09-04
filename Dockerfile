# official Ubuntu 20.04 as a base image
FROM ubuntu:24.04

# install needed packages
RUN apt update && apt install -y fortune-mod cowsay netcat-openbsd

ENV PATH="/usr/games:${PATH}"

# Copying script into container
COPY web_app.sh /usr/local/bin/web_app.sh

# Making script executable
RUN chmod +x /usr/local/bin/web_app.sh

# Seting the default command to run the script
CMD ["/usr/local/bin/web_app.sh"]
