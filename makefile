##############################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https:$(D)$(D)www.apache.org$(D)licenses$(D)LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################

#
# Makefile to run various JVM tests
#

ifndef TEST_JDK_HOME
$(error Please provide TEST_JDK_HOME value.)
else
export TEST_JDK_HOME := $(subst \,/,$(TEST_JDK_HOME))
export OLD_JAVA_HOME := $(JAVA_HOME)
export JAVA_HOME := $(TEST_JDK_HOME)
$(info JAVA_HOME is set to $(JAVA_HOME))
endif

ifndef FRAMEWORK_JDK_HOME
export FRAMEWORK_JDK_HOME := $(TEST_JDK_HOME)
endif
$(info FRAMEWORK_JDK_HOME is set to $(FRAMEWORK_JDK_HOME))


ifndef ANT_HOME
export ANT := ant
else
$(info ANT_HOME is set to $(ANT_HOME))
export ANT := $(ANT_HOME)/ant
endif

D = /
MKTREE = mkdir -p
SUBDIRS = ..

ifndef TEST_ROOT
	TEST_ROOT := $(shell pwd)$(D)..
endif

#######################################
# download all dependent jars
#######################################
getdependency:
	perl scripts$(D)getDependencies.pl -path '$(TEST_ROOT)$(D)TKG$(D)lib' -task default

.PHONY: getdependency

#######################################
# run test
#######################################
_TESTTARGET = $(firstword $(MAKECMDGOALS))
TESTTARGET = $(patsubst _%,%,$(_TESTTARGET))
ifneq (compile, $(_TESTTARGET))
ifneq (clean, $(_TESTTARGET))
ifneq (test, $(_TESTTARGET))
ifneq (genParallelList, $(_TESTTARGET))
ifneq (_failed, $(_TESTTARGET))
$(_TESTTARGET):
	$(MAKE) -f makeGen.mk AUTO_DETECT=$(AUTO_DETECT) MODE=tests TESTTARGET=$(TESTTARGET) TESTLIST=$(TESTLIST)
	$(MAKE) -f runtest.mk $(_TESTTARGET)
endif
endif
endif
endif
endif

#######################################
# compile test materials
#######################################
compile: envDetect
	$(MAKE) -f compile.mk compile

#######################################
# If AUTO_DETECT is turned on, compile and execute envDetector in build_envInfo.xml.
#######################################
envDetect: compileTools
ifneq ($(AUTO_DETECT), false)
	@echo "AUTO_DETECT is set to true"
	${TEST_JDK_HOME}$(D)bin$(D)java -cp .$(D)bin$(D)TestKitGen.jar org.openj9.envInfo.EnvDetector
else
	@echo "AUTO_DETECT is set to false"
endif

#######################################
# compile tools
#######################################
include moveDmp.mk
COMPILE_TOOLS_CMD=$(ANT) -f .$(D)scripts$(D)build_tools.xml -DFRAMEWORK_JDK_HOME=$(FRAMEWORK_JDK_HOME)

compileTools: getdependency
	$(RM) -r $(COMPILATION_OUTPUT); \
	$(MKTREE) $(COMPILATION_OUTPUT); \
	($(COMPILE_TOOLS_CMD) 2>&1; echo $$? ) | tee $(Q)$(COMPILATION_LOG)$(Q); \
	$(MOVE_TDUMP)

#######################################
# compile and run all tests
#######################################
test: compile _all
	@$(ECHO) "All Tests Completed"

.PHONY: test

.NOTPARALLEL: test

#######################################
# run failed tests
#######################################
_failed:
	@$(MAKE) -f failedtargets.mk _failed

.PHONY: _failed

.NOTPARALLEL: _failed

#######################################
# generate parallel list
#######################################
genParallelList: envDetect
	$(MAKE) -f makeGen.mk AUTO_DETECT=$(AUTO_DETECT) MODE=parallelList NUM_MACHINES=$(NUM_MACHINES) TEST_TIME=$(TEST_TIME) TESTTARGET=$(TEST) TESTLIST=$(TESTLIST) TRSS_URL=$(TRSS_URL)

#######################################
# clean
#######################################
clean:
	$(MAKE) -f clean.mk clean

.PHONY: clean
