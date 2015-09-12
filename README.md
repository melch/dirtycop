#dirtycop
## Credit
A modification of skanev's gist, original found here: https://gist.github.com/skanev/9d4bec97d5a6825eaaf6

## Installation
Place dirty_cop.rb in your repo (in lib, for example).

Use this bash function
```
function dirty() {
  changed_files=`git diff --name-only | grep \.rb$` # list of changed ruby files
  rubocop -D --require ./lib/rubocop/dirty_cop.rb $changed_files
}
```
