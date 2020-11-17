DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
java -cp $DIR/lib/ddrlab.jar ddrlab.Base "$@"
touch $DIR/web.xml # reload webapp
