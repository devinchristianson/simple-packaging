local test_image = "alpine";
function(image=test_image) {
    local parsed_image = std.split(image, ":"),
    "name": std.strReplace(std.strReplace(image, ":", "_"), "/", "-"),
    "type": "registry-image",
    "source": {
        "repository": parsed_image[0],
        [if std.length(parsed_image) == 2 then "tag" else null]: parsed_image[1]
    }
}