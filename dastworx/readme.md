## Dastworx

_D AST works_ is a tool that processes the AST of a D module to extract several information used by Coedit.

It's notably used by the _symbol list_ and the _todo list_ widgets.

## Build

If Coedit is build manually you'll certainly have to build _dastworx_ too.
Two options exist.

#### Using Coedit & the submodules

- If you've cloned this repository, make sure that the submodule are also here with `git submodule update --init`. 
- In Coedit open the project `dastworx.ce`.
- Select the `release` configuration.
- Click `Compile project`

#### Using the scripts

- Windows: `build.bat`
- Linux: `sh ./build.sh`