ARG TERRAFORM_VERSION=latest
FROM hashicorp/terraform:${TERRAFORM_VERSION} AS hashicorp
FROM alpine:3.13
RUN apk update && apk add --no-cache \
        bash \
        git \
        wget \
        python3 \
        py3-pip \
        jq
# Install Terraform
COPY --from=hashicorp /bin/terraform /usr/local/bin/terraform
# Install cloud SDK
ENV PATH /usr/local/google-cloud-sdk/bin:$PATH
ARG CLOUD_SDK_VERSION
ENV CLOUD_SDK_VERSION ${CLOUD_SDK_VERSION}
ADD install_cloud_sdk.sh /build/
RUN /build/install_cloud_sdk.sh ${CLOUD_SDK_VERSION}
RUN rm -rf /build
# install pipenv
RUN pip install pipenv
#output versions
RUN terraform version && gcloud version
RUN which terraform
RUN echo $PATH
CMD ["/bin/bash"]
