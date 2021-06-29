# MySQLLinux

This is the Markdown-based documentation for mysqllinux repository.

## Local Testing
Install dependencies for building documentation and run `pipenv run mkdocs serve`

```
$ pipenv install
```
```
$ pipenv run mkdocs serve
```

The docs would be served up at [http://127.0.0.1:8000](http://127.0.0.1:8000).

### Debugging

#### mkdocs not found
```
$ pipenv run mkdocs serve
Error: the command mkdocs could not be found within PATH or Pipfile's [scripts].
```
Run `pipenv install` to make sure all the dependencies are installed from the Pipfile.

## Live Testing via Github Pages
To publish doc change to your individual fork for review, we use github pages. To set this up follow these following steps.

1. Create a new local branch named `gh-pages`.
2. Using the same virtual environment above run:
```
pipenv run mkdocs build --clean
```
This will generate the `site` directory which will contain all the gererated docs.
3. Copy all these files to the root directory of the mysqllinux repo and delete all other files.
4. Commit and push these changes to your individual fork.
5. Go to your individual mysqllinux repo settings, scroll to the bottom and verify under the GitHub Pages section the `Source` is set to `gh-pages branch`.
6. Right above this will be a link explaining where your docs are published.

