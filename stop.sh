#!/bin/bash
docker stop single_clm clm_clm clmdb | docker rm -v single_clm clm_clm clmdb
# docker rm $(docker ps -aqf status=exited)
# docker rm $(docker ps -aqf status=created)
