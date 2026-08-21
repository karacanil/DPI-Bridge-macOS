#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>

#define LISTEN_PORT 1081
#define SOCKS_PORT 1080
#define BUFFER_SIZE 65536
#define HEADER_LIMIT 16384

static int send_all(int fd, const void *buffer, size_t length) {
    const uint8_t *bytes = buffer;
    while (length > 0) {
        ssize_t sent = send(fd, bytes, length, 0);
        if (sent <= 0) return -1;
        bytes += sent;
        length -= (size_t)sent;
    }
    return 0;
}

static int has_allowed_suffix(const char *host, const char *suffix) {
    size_t host_length = strlen(host);
    size_t suffix_length = strlen(suffix);
    if (host_length < suffix_length) return 0;
    const char *start = host + host_length - suffix_length;
    if (strcasecmp(start, suffix) != 0) return 0;
    return host_length == suffix_length || start[-1] == '.';
}

static int host_is_allowed(const char *host) {
    static const char *suffixes[] = {
        "discord.com",
        "discordapp.com",
        "discordapp.net",
        "discord.gg",
        "discord.media",
        "discordcdn.com"
    };
    for (size_t index = 0; index < sizeof(suffixes) / sizeof(suffixes[0]); index++) {
        if (has_allowed_suffix(host, suffixes[index])) return 1;
    }
    return 0;
}

static int connect_to_socks(const char *host, uint16_t port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_in address = {0};
    address.sin_family = AF_INET;
    address.sin_port = htons(SOCKS_PORT);
    inet_pton(AF_INET, "127.0.0.1", &address.sin_addr);
    if (connect(fd, (struct sockaddr *)&address, sizeof(address)) != 0) {
        close(fd);
        return -1;
    }

    const uint8_t greeting[] = {0x05, 0x01, 0x00};
    uint8_t greeting_response[2];
    if (send_all(fd, greeting, sizeof(greeting)) != 0 ||
        recv(fd, greeting_response, sizeof(greeting_response), MSG_WAITALL) != 2 ||
        greeting_response[0] != 0x05 || greeting_response[1] != 0x00) {
        close(fd);
        return -1;
    }

    size_t host_length = strlen(host);
    if (host_length == 0 || host_length > 255) {
        close(fd);
        return -1;
    }

    uint8_t request[4 + 1 + 255 + 2];
    size_t offset = 0;
    request[offset++] = 0x05;
    request[offset++] = 0x01;
    request[offset++] = 0x00;
    request[offset++] = 0x03;
    request[offset++] = (uint8_t)host_length;
    memcpy(request + offset, host, host_length);
    offset += host_length;
    request[offset++] = (uint8_t)(port >> 8);
    request[offset++] = (uint8_t)(port & 0xff);
    if (send_all(fd, request, offset) != 0) {
        close(fd);
        return -1;
    }

    uint8_t response[4];
    if (recv(fd, response, sizeof(response), MSG_WAITALL) != 4 ||
        response[0] != 0x05 || response[1] != 0x00) {
        close(fd);
        return -1;
    }

    size_t address_length;
    if (response[3] == 0x01) address_length = 4;
    else if (response[3] == 0x04) address_length = 16;
    else if (response[3] == 0x03) {
        uint8_t domain_length;
        if (recv(fd, &domain_length, 1, MSG_WAITALL) != 1) {
            close(fd);
            return -1;
        }
        address_length = domain_length;
    } else {
        close(fd);
        return -1;
    }

    uint8_t discard[258];
    if (recv(fd, discard, address_length + 2, MSG_WAITALL) != (ssize_t)(address_length + 2)) {
        close(fd);
        return -1;
    }
    return fd;
}

static void relay(int client, int upstream) {
    uint8_t buffer[BUFFER_SIZE];
    for (;;) {
        fd_set read_set;
        FD_ZERO(&read_set);
        FD_SET(client, &read_set);
        FD_SET(upstream, &read_set);
        int maximum = client > upstream ? client : upstream;
        if (select(maximum + 1, &read_set, NULL, NULL, NULL) <= 0) return;

        int source = FD_ISSET(client, &read_set) ? client : upstream;
        int destination = source == client ? upstream : client;
        ssize_t received = recv(source, buffer, sizeof(buffer), 0);
        if (received <= 0 || send_all(destination, buffer, (size_t)received) != 0) return;
    }
}

static void *handle_client(void *context) {
    int client = *(int *)context;
    free(context);
    int upstream = -1;
    char headers[HEADER_LIMIT + 1];
    size_t used = 0;

    while (used < HEADER_LIMIT) {
        ssize_t received = recv(client, headers + used, HEADER_LIMIT - used, 0);
        if (received <= 0) goto cleanup;
        used += (size_t)received;
        headers[used] = '\0';
        if (strstr(headers, "\r\n\r\n")) break;
    }

    char method[16], target[512], version[16];
    if (sscanf(headers, "%15s %511s %15s", method, target, version) != 3 ||
        strcasecmp(method, "CONNECT") != 0) {
        send_all(client, "HTTP/1.1 405 Method Not Allowed\r\n\r\n", 35);
        goto cleanup;
    }

    char *separator = strrchr(target, ':');
    if (!separator) goto forbidden;
    *separator = '\0';
    char *end = NULL;
    long parsed_port = strtol(separator + 1, &end, 10);
    if (!end || *end != '\0' || parsed_port != 443 || !host_is_allowed(target)) goto forbidden;

    upstream = connect_to_socks(target, (uint16_t)parsed_port);
    if (upstream < 0) {
        send_all(client, "HTTP/1.1 502 Bad Gateway\r\n\r\n", 28);
        goto cleanup;
    }
    if (send_all(client, "HTTP/1.1 200 Connection Established\r\n\r\n", 39) != 0) goto cleanup;
    relay(client, upstream);
    goto cleanup;

forbidden:
    send_all(client, "HTTP/1.1 403 Forbidden\r\n\r\n", 26);

cleanup:
    if (upstream >= 0) close(upstream);
    close(client);
    return NULL;
}

int main(void) {
    signal(SIGPIPE, SIG_IGN);
    int listener = socket(AF_INET, SOCK_STREAM, 0);
    if (listener < 0) return EXIT_FAILURE;

    int reuse = 1;
    setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    struct sockaddr_in address = {0};
    address.sin_family = AF_INET;
    address.sin_port = htons(LISTEN_PORT);
    inet_pton(AF_INET, "127.0.0.1", &address.sin_addr);
    if (bind(listener, (struct sockaddr *)&address, sizeof(address)) != 0 ||
        listen(listener, 32) != 0) {
        close(listener);
        return EXIT_FAILURE;
    }

    for (;;) {
        int client = accept(listener, NULL, NULL);
        if (client < 0) {
            if (errno == EINTR) continue;
            break;
        }
        int *context = malloc(sizeof(int));
        if (!context) {
            close(client);
            continue;
        }
        *context = client;
        pthread_t thread;
        if (pthread_create(&thread, NULL, handle_client, context) == 0) {
            pthread_detach(thread);
        } else {
            free(context);
            close(client);
        }
    }
    close(listener);
    return EXIT_FAILURE;
}
