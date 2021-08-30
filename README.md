# Github-import-repo script

This tool can import all repository into Github.

## Usage

```bash
$ ./github.sh
= set param working.directory to .
= set param config.file.path to .
= set param config.file.name to config.properties
= set config private to true
= set config github.user to tfSheol
= set config organization.name to current_organization_name

Usage: ./github.sh {build <all|> | other} [options...]

 options:
    --working-directory=<...>         change current working directory
    --config-path=<...>               change configuration file location path
    --config-name=<...>               change configuration file name (current 'config.properties')

    --organization                    prefere import repository into Github organization

 cmd:
    import <repository_url>           import repository into Github
```

## Usage examples

```bash
# Import into Github user
$ ./github.sh import ssh://git@gitlab.com/group/app.git

# Import into Github organization
$ ./github.sh import ssh://git@gitlab.com/group/app.git --organization
```

## Steps

Steps to import git repository manualy.

```bash
# 1) Create an private repository with custom name
$ gh repo create repo --private

# 1.1) Or create an private repository with custom name in an organization
$ gh repo create cli/repo --private

# 2) Makes a bare clone of the external repository in a local directory
$ git clone --bare https://external-host.com/extuser/repo.git

# 3) Pushes the mirror to the new GitHub repository
$ cd repo.git
$ git push --mirror https://github.com/ghuser/repo.git

# 4) Remove temporary local repository
$ cd ..
$ rm -rf repo.git
```

