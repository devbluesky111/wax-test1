# Copyright (c) 2019, The WAX Team and respective Authors, all rights reserved.
#
# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

CONTRACT_NAME = waxcontract
DEV_DOCKER_VERSION = wax-1.6.1-1.2.0
NODEOS_URL ?= https://chain.wax.io/
CONTAINER = ${CONTRACT_NAME}-sample
WORK_DIR = /opt/${CONTRACT_NAME}
DOCKER_COMMON = -v `pwd`:${WORK_DIR} --name ${CONTAINER} -w ${WORK_DIR} waxteam/dev:${DEV_DOCKER_VERSION}
AS_LOCAL = --user $(shell id -u):$(shell id -g)
CLEOS=/usr/local/eosio/bin/cleos
CLEOSN=${CLEOS} -u ${NODEOS_URL}

.PHONY: build test clean deploy \
        create_key create_account \
        dev-docker-stop dev-docker-start


build: dev-docker-stop
	@mkdir -p build
	docker run ${AS_LOCAL} ${DOCKER_COMMON} bash -c "cd build && cmake .. && make -j $$(nproc)"


# This requires an already deployed contract
test: dev-docker-stop
ifndef CONTRACT_ACCOUNT
	$(error CONTRACT_ACCOUNT is undefined)
endif
	docker run ${DOCKER_COMMON} bash -c "${CLEOSN} push action ${CONTRACT_ACCOUNT} greet '[]' -p ${CONTRACT_ACCOUNT}@active"


clean:
	-rm -rf build


deploy: dev-docker-stop
ifndef CONTRACT_ACCOUNT
	$(error CONTRACT_ACCOUNT is undefined)
endif
ifndef CONTRACT_PRIVATE_KEY
	$(error CONTRACT_PRIVATE_KEY is undefined)
endif
	docker run ${DOCKER_COMMON} bash -c \
       "rm -f ~/eosio-wallet/${CONTRACT_NAME}.wallet && \
        ${CLEOS} wallet create -n ${CONTRACT_NAME} --to-console && \
        ${CLEOS} wallet import -n ${CONTRACT_NAME} --private-key ${CONTRACT_PRIVATE_KEY} && \
        ${CLEOSN} set contract ${CONTRACT_ACCOUNT} ${WORK_DIR}/build ${CONTRACT_NAME}.wasm ${CONTRACT_NAME}.abi"


create-key: dev-docker-stop
	@docker run ${DOCKER_COMMON} bash -c "${CLEOS} create key --to-console"


create-account: dev-docker-stop
ifndef WAX_ACCOUNT
	$(error WAX_ACCOUNT is undefined)
endif
ifndef WAX_PRIVATE_KEY
	$(error WAX_PRIVATE_KEY is undefined)
endif
ifndef CONTRACT_ACCOUNT
	$(error CONTRACT_ACCOUNT is undefined)
endif
ifndef CONTRACT_PUBLIC_KEY
	$(error CONTRACT_PUBLIC_KEY is undefined)
endif
	docker run ${DOCKER_COMMON} bash -c \
       "rm -f ~/eosio-wallet/${WAX_ACCOUNT}.wallet && \
        ${CLEOS} wallet create -n ${WAX_ACCOUNT} --to-console && \
        ${CLEOS} wallet import -n ${WAX_ACCOUNT} --private-key ${WAX_PRIVATE_KEY} && \
        ${CLEOSN} system newaccount ${WAX_ACCOUNT} ${CONTRACT_ACCOUNT} ${CONTRACT_PUBLIC_KEY} \
                     --stake-net '0.50000000 WAX' --stake-cpu '0.50000000 WAX' --buy-ram-kbytes 32"


dev-docker-stop:
	@-docker rm -f ${CONTAINER}


# Useful for interactive docker work
dev-docker-start: dev-docker-stop
	docker run -it ${AS_LOCAL} ${DOCKER_COMMON} bash
