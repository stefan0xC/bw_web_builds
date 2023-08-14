# Compile the web vault using docker
# Usage:
#    Quick and easy:
#    `make docker-extract`
#    or, if you just want to build
#    `make docker`
#
#    docker build -t web_vault_build .
#    image_id=$(docker create web_vault_build)
#    docker cp $image_id:/bw_web_vault.tar.gz .
#    docker rm $image_id
#
#    Note: you can use --build-arg to specify the version to build:
#    docker build -t web_vault_build --build-arg VAULT_VERSION=master .

#    image_id=$(docker create bitwardenrs/web-vault@sha256:feb3f46d15738191b9043be4cdb1be2c0078ed411e7b7be73a2f4fcbca01e13c)
#    docker cp $image_id:/bw_web_vault.tar.gz .
#    docker rm $image_id

FROM node:16-bookworm as build
RUN node --version && npm --version

# Prepare the folder to enable non-root, otherwise npm will refuse to run the postinstall
RUN mkdir /vault
RUN chown node:node /vault
USER node

WORKDIR /vault

COPY --chown=node:node clients /vault

# Build
RUN npm ci
RUN npm audit fix || true

# Switch to the web apps folder
WORKDIR /vault/apps/web

RUN npm run dist:oss:selfhost

# Delete debugging map files, optional
# RUN find build -name "*.map" -delete

# Prepare the final archives
RUN mv build web-vault
RUN tar -czvf "bw_web_vault.tar.gz" web-vault --owner=0 --group=0

# We copy the final result as a separate empty image so there's no need to download all the intermediate steps
# The result is included both uncompressed and as a tar.gz, to be able to use it in the docker images and the github releases directly
FROM scratch
# hadolint ignore=DL3010
COPY --from=build /vault/apps/web/bw_web_vault.tar.gz /bw_web_vault.tar.gz
COPY --from=build /vault/apps/web/web-vault /web-vault
# Added so docker create works, can't actually run a scratch image
CMD [""]
