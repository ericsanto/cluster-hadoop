#!/bin/bash

backup_file() {
    local file="$1"

    [[ -f "$file" ]] && cp "$file" "$file.bak"
}

clear_xml() {
    local file="$1"

    sed -i '/<configuration>/,/<\/configuration>/d' "$file"
}

write_xml() {

    local file="$1"
    local content="$2"

    backup_file "$file"

    clear_xml "$file"

    cat <<EOF > "$file"
$content
EOF
}

detect_java_home() {

    dirname "$(dirname "$(readlink -f "$(which java)")")"

}