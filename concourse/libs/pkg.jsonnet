local type_to_image_mapping = {
    "pacman": "archlinux-latest",
    "rpm": "fedora-37",
    "deb": "ubuntu-20.04"
};

# functions that can be shared between pkg types
local local_fcns = {
    image(type):: {
        "name": "fpm-" + type + "-image",
        "type": "docker-image",
        "source": {
            "repository": "devinchristianson/fpm",
            "tag": type_to_image_mapping[type]
        }
    }
};

# this is a top level arguments function, so in order to get vscode not to complain, it needs arg defaults
# converts this generic library into a non-generic one
function(type="")  if type == "pacman" then
                            local pacman = import 'pkg_types/pacman.jsonnet';
                            {
                                image: local_fcns.image(type),
                            } + pacman
                        else 
                            local_fcns