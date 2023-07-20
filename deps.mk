check-deps:
	@mkdir -p $(TOPDIR)/repos
	while IFS= read -r line; do \
		name=$$(echo "$$line" | cut -d ',' -f 1); 	\
		hash=$$(echo "$$line" | cut -d ',' -f 2); 	\
		if [ ! -d "$(TOPDIR)/repos/$$name" ]; then \
			echo "checking out repo $$name hash $$hash";	\
			git clone https://github.com/TunnelBear/$$name $(TOPDIR)/repos/$$name;	\
			cd $(TOPDIR)/repos/$$name && git checkout $$hash;	\
		fi \
	done < $(TOPDIR)/containers.deps
