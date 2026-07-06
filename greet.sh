#!/bin/bash
echo "1innsuu: $1"
echo "2innsuu: $2"
echo "allinnsuu: $@"
echo "numbler of innsuu: $#"

chmod +x ~/greet.sh

#!/bin/bash

greet() {
    echo "こんにちは、$1 さん"
}

greet "いあん"
greet "田中"
