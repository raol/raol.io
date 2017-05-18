THEME=hugo-theme-blueberry-detox

serve: config.toml
	hugo serve -t $(THEME) --buildDrafts

post:
	hugo new post/$(name).md

publish:
	hugo -t $(THEME)
