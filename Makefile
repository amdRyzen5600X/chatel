migrate:
	mix ecto.migrate

create:
	mix create

prepare_migration:
	mix ecto.gen.migration $(NAME)

deps_get:
	mix deps.get

serve:
	mix phx.server

test:
	mix test

format:
	mix format
