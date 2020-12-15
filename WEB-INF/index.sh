DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
java -cp "$DIR/lib/alix.jar" alix.cli.Load 1 "$@"
touch $DIR/web.xml # reload webapp
