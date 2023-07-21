check-deps:
	@mkdir -p $(PBDIR)/repos
	while IFS= read -r line; do \
		name=$$(echo "$$line" | cut -d ',' -f 1); 	\
		hash=$$(echo "$$line" | cut -d ',' -f 2); 	\
		if [ ! -d "$(PBDIR)/repos/$$name" ]; then \
			echo "checking out repo $$name hash $$hash";	\
			git clone https://github.com/TunnelBear/$$name $(PBDIR)/repos/$$name;	\
			cd $(PBDIR)/repos/$$name && git checkout $$hash;	\
		fi \
	done < $(PBDIR)/containers.deps
