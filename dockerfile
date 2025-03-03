# Use the official NGINX image
FROM nginx:alpine

# Copy website files into the container
COPY public/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
