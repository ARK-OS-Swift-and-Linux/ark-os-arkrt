.PHONY: all clean Wayland GTK3

all: Wayland GTK3

Wayland:
	@echo 'Building Wayland...'
	@$(MAKE) -C Wayland

GTK3:
	@echo 'Building GTK3...'
	@$(MAKE) -C GTK3

clean:
	@$(MAKE) -C Wayland clean
	@$(MAKE) -C GTK3 clean
