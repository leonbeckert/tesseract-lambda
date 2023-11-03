# Deploy Tesseract on AWS Lambda

This repository provides a guide and the necessary scripts to deploy Tesseract OCR in an AWS Lambda function using a Docker container to build the required binaries and the Serverless Framework for deployment.

## Overview

Tesseract is a popular OCR (Optical Character Recognition) engine. `pytesseract` is a Python wrapper for Tesseract, but since AWS Lambda runs on Amazon Linux, `pytesseract` alone won't work out of the box. We need to compile Tesseract for Amazon Linux and include it in our deployment package.

By following this guide, you will build Tesseract within an Amazon Linux Docker container, create a ZIP file with the necessary binaries and dependencies, and then deploy it to AWS Lambda as a layer.

## Prerequisites

- Docker
- Serverless Framework configured

## Choosing the Python Version and Runtime for Docker Build

When preparing to build Tesseract within a Docker container, it is essential to select an appropriate base image that aligns with your target AWS Lambda execution environment. The Dockerfile provided in this repository starts with a specific version of the Lambda base image for Python. Here is an example:

  ```Dockerfile
  FROM public.ecr.aws/lambda/python:3.9-arm64
  ```

### Python Version

Ensure the Python version in the Dockerfile (python:3.9-arm64) matches the AWS Lambda runtime to maintain code compatibility and leverage consistent runtime features. Using the same version avoids issues with library support specific to Python 3.9.

### Runtime Architecture
The arm64 tag indicates an ARM64 architecture, optimal for certain AWS Lambda workloads due to its cost-to-performance benefits. Confirm that all dependencies, including Tesseract, support ARM64. For x86_64 workloads, adjust the Dockerfile accordingly.

## Customizing Tesseract OCR Languages

When building Tesseract OCR in Docker, you have the option to include language-specific `.traineddata` files according to your requirements. However, keep in mind that AWS Lambda layers have a size limit of 50MB. The `.traineddata` files can be quite large, and including too many can exceed this limit.

To customize the languages included in your build, you will need to modify the `ENV TESSDATA_VERSION` environment variable in the Dockerfile provided in this repository. You have three options for the source of the `.traineddata` files, which vary in file size and accuracy:

- `tessdata`: This is the standard version with a balance between size and accuracy.
- `tessdata_fast`: These are smaller, less accurate files optimized for speed and size.
- `tessdata_best`: These files are larger and more accurate but may cause you to reach the Lambda layer size limit more quickly.
Here's an excerpt from the Dockerfile where you can set the environment variable:

  ```Dockerfile
  # Dockerfile
  ...
  # Set the TESSDATA_VERSION to the desired tessdata repository
  ENV TESSDATA_VERSION="tessdata"
  # Alternatively, set TESSDATA_VERSION to "tessdata_fast" or "tessdata_best" for different versions
  ...
  ```

After setting `TESSDATA_VERSION`, you should list the languages you want to include in your Docker build environment. For example:

  ```Dockerfile
  # Dockerfile
  ...
  # Set the TESSDATA_LANGUAGES to the languages you want to include, separated by spaces
  ENV TESSDATA_LANGUAGES="eng spa deu"
  ...
  ```

In the build script `build_tesseract.sh`, include a loop that downloads the specified `.traineddata` files for each language you set in `TESSDATA_LANGUAGES`. Here's an example snippet you could use:

  ```sh
  #!/bin/bash
  # build_tesseract.sh

  # Loop through each language in the TESSDATA_LANGUAGES environment variable
  for lang in $TESSDATA_LANGUAGES; do
      # Download the respective .traineddata file
      wget "https://github.com/tesseract-ocr/${TESSDATA_VERSION}/raw/main/${lang}.traineddata" -P path_to_tessdata_dir
  done

  # Continue with the rest of the build process
  ...
  ```

Remember to replace `path_to_tessdata_dir` with the actual path to the tessdata directory in your build environment.

By adjusting the `TESSDATA_VERSION` and `TESSDATA_LANGUAGES` environment variables, you can control which `.traineddata` files are included in your Tesseract build and manage the overall size of your Lambda layer. Always test your final build to ensure that it fits within the Lambda layer size limit and meets your performance expectations.

## Building Tesseract in Docker

Before building Tesseract, ensure you have Docker installed and running.

1. Clone this repository to your local machine:

  ```sh
  git clone https://github.com/leonbeckert/tesseract-lambda.git
  cd tesseract-lambda
  ```

2. Inside the repository, you will find a build script build_tesseract.sh. Make sure it's executable:

  ```sh
  chmod +x build_tesseract.sh
  ```

3. Use the following Docker commands to build the Tesseract binaries:

  ```sh
  docker build -t tesseract .
  docker run -v $PWD/tesseract:/tmp/build --entrypoint /tmp/build_tesseract.sh tesseract
  ```

4. After the build process is complete, the Tesseract binaries will be located in the tesseract folder as `tesseract.zip`.

## Creating the Lambda Layer with the Serverless Framework

Once Tesseract has been built and the `tesseract.zip` file has been created inside the new `tesseract` directory, follow these steps to create your Lambda Layer:

1. Navigate to the `tesseract` folder created by the Docker process and extract the contents of `tesseract.zip`:

  ```sh
  cd tesseract
  unzip tesseract.zip -d /path/to/your/lambda-layer/tesseract-layer
  ```

Replace /path/to/your/lambda-layer with the actual path to your Lambda Layer directory. This step will create a tesseract-layer directory within your Lambda Layer directory with all the necessary binaries and files for Tesseract.

1. In your serverless.yml file, define the layer with its path and specify the runtimes that are compatible with the Tesseract binaries. Below is an example configuration:

  ```yml
  # serverless.yml

  functions:
    myFunction:
      handler: handler.myHandler
      layers:
        - {Ref: TesseractLambdaLayer}

  layers:
    tesseract:
      path: lambda_layers/tesseract-layer
      compatibleRuntimes:
        - python3.9
  ```

In this configuration, myFunction is your AWS Lambda function that will use the layer. The layer itself is defined under layers, where you set the path to the extracted tesseract binaries and specify python3.9 as the compatible runtime.

## Modifying Your Python Script

After adding the Lambda Layer, you need to set an environment variable in your Python script to point to the Tesseract data:

  ```python
  import os
  os.environ['TESSDATA_PREFIX'] = '/opt/tessdata'
  ```

## Deployment

After configuring your environment and script, deploy your AWS Lambda function with the Serverless Framework:

  ```sh
  serverless deploy
  ```

or shorter

  ```sh
  sls deploy
  ```

The Serverless Framework will handle the creation and deployment of the layer. It will also attach the layer to your Lambda function as specified in the serverless.yml file.

## Troubleshooting

If you encounter any issues during deployment or execution:

- Ensure you have the right permissions set for Serverless Framework.
- Verify that the Python versions in your build_tesseract.sh and serverless.yml match.
- Check the Lambda function's logs for any runtime errors.

## Credits

This AWS Lambda Tesseract deployment guide is largely based on the concepts and procedures outlined in the blog post ["Tesseract on AWS Lambda: OCR as a Service"](https://typless.com/2023/08/29/tesseract-on-aws-lambda-ocr-as-a-service/) by Typless. The content here has been adapted, improved upon, and updated to fix some errors and suit the current deployment strategies and best practices. I extend my heartfelt thanks to the Typless team for their original and valuable contribution to the community.
