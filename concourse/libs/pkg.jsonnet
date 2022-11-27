local image_resource = import 'image.jsonnet';
local type_to_image_mapping = {
    "pacman": "devinchristianson/fpm:archlinux-latest",
    "rpm": "devinchristianson/fpm:fedora-37",
    "deb": "devinchristianson/fpm:debian-stable-latest"
};

local implementations = {
    pacman: import 'pkg_types/pacman.jsonnet',
    rpm: import 'pkg_types/rpm.jsonnet'
};

# this is a top level arguments function, so in order to get vscode not to complain, it needs arg defaults
# this function converts this generic library into a non-generic one
function(type="", pkg={})  
    if type != "" then  # if type is set, pass to appropriate implementation
        implementations[type](pkg)
    else                # if type is not set, pass to generic implementation - this allows the implementations to use this code
        {
            # used to generate a list of image resources required for the supported types
            images: [   
                image_resource(type_to_image_mapping[type])
                for type in std.objectFields(implementations)
            ],
            # used to get the correct image name for a type 
            # (extra processing to strip out all the chars concourse doesn't like)
            image(type):: std.strReplace(std.strReplace(type_to_image_mapping[type], ":", "_"), "/", "-"),
            # used to get the packager implementations
            implementations:: std.objectFields(implementations)
        }