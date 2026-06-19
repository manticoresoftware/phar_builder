# PHAR Builder

Scripts to help us to maintain the building process the same way for all our PHP-related projects that run with `manticore-executor`.

## Build modes

By default, `bin/build` creates a module directory with `src/`, `vendor/`, Composer metadata, and generated wrappers that launch `src/main.php` through `manticore-executor`.

Add `--phar` to collapse that generated module tree into `build/share/modules/<package>/<package>.phar` and rewrite generated wrappers to launch the PHAR instead:

```bash
./bin/build --name="Manticore Backup" --package="manticore-backup" --template=sh --phar
```

Use `--compat-src-main` for modules that must still expose `src/main.php` outside the PHAR, e.g. bundled Buddy auto-discovery by `searchd`:

```bash
./bin/build --name="Manticore Buddy" --package="manticore-buddy" --phar --compat-src-main
```

The PHAR entrypoint is `src/main.php`.
