#!/bin/bash


MACHINE_PATH=${MACHINE_IMAGE_PATH}

if [ "$#" -ne 1 ] && [[ ! ${MACHINE_PATH} ]]; then
    echo "tests require at least path to machine image"
    exit 1
fi

if [[ ! ${MACHINE_PATH} ]]; then
  MACHINE_PATH=$1
  fi

echo "using images from ${MACHINE_PATH}"
export MACHINE_IMAGE_PATH=$MACHINE_PATH

ginkgo
