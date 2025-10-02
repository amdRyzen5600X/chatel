# Chatel

To start this project:
  * install phoenix:
    ```console
    curl https://new.phoenixframework.org/myapp | sh
    ```
  * clone this repo:
    ```console
    git clone https://github.com/amdryzen5600x/chatel.git
    cd chatel
    ```
  * install dependencies:
    ```console
    make deps_get
    ```
  * configure your database in config/dev.exs and config/prod.exs and then:
    ```console
    make create
    ```
  * run migrations:
    ```console
    make migrate
    ```
  * and finally:
    ```console
    make serve
    ```


Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
