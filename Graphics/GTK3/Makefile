.PHONY: all clean 2Dvector CoreLibs Foundation Graphics Support

all: Support 2Dvector CoreLibs Foundation Graphics

2Dvector:
	@echo 'Building 2Dvector...'
	@$(MAKE) -C 2Dvector

CoreLibs:
	@echo 'Building CoreLibs...'
	@$(MAKE) -C CoreLibs

Foundation:
	@echo 'Building Foundation...'
	@$(MAKE) -C Foundation

Graphics:
	@echo 'Building Graphics...'
	@$(MAKE) -C Graphics

Support:
	@echo 'Building Support...'
	@$(MAKE) -C Support

clean:
	@$(MAKE) -C 2Dvector clean
	@$(MAKE) -C CoreLibs clean
	@$(MAKE) -C Foundation clean
	@$(MAKE) -C Graphics clean
	@$(MAKE) -C Support clean
