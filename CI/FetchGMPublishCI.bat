@echo off
setlocal
curl -L -O https://github.com/ZehMatt/gmpublish-ci/releases/download/v1.0.0/gmpublish-ci-1.0.0.zip
powershell "Expand-Archive -Force -Path './gmpublish-ci-1.0.0.zip' -DestinationPath './gmpublish-ci'"