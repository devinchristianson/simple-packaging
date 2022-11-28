local image = import '../image.jsonnet';
local step = import '../step.jsonnet';
local type_to_image_mapping = {
    "pacman": "devinchristianson/fpm:archlinux-latest",
    "rpm": "devinchristianson/fpm:fedora-37",
    "deb": "devinchristianson/fpm:debian-stable-latest"
};
local implementations = {
    pacman: import 'pacman.jsonnet',
    rpm: import 'rpm.jsonnet'
};

local convert_image(type) = std.strReplace(std.strReplace(type_to_image_mapping[type], ":", "_"), "/", "-");

{
    
    # used to generate a list of image resources required for the supported types
    images: [   
        image(type_to_image_mapping[type])
        for type in std.objectFields(implementations)
    ],
    # used to get the correct image name for a type 
    # (extra processing to strip out all the chars concourse doesn't like)
    image(type):: convert_image(type),
    # used to get the packager implementations
    types:: std.objectFields(implementations),
    implementations:: implementations,
    getIndexParams(type)::
        if type == "pacman" then
            {
                "prefix": "pacman",
                "source_dir": "index",
                "options": [
                    "--exclude '*'",
                    "--include 'mdicsme.db'",
                    "--include 'mdicsme.files'",
                    "--include 'mdicsme.*.tar.gz'",
                    "--include 'mdicsme.*.tar.gz.sig'"
                ]
            }
        else if type == "rpm" then
        {
            "prefix": "rpm",
            "source_dir": "index",
            "options": [
                "--exclude '*'",
                "--include 'repodata/*'",
                "--include 'cache/*'",
            ]
        }
        else if type == "deb" then
        {

        } 
        else 
        {
            
        },
    reindex(type, resources):: 
        if type == "pacman" then
            [
                step.task({
                    name: "rebuild-paman-index",
                    image: convert_image("pacman"),
                    inputs: [
                        "index",
                    ] + resources,
                    outputs: ["index"],
                    in_shell: true,
                    params: {
                                "GPG_PRIVATE_KEY": "((gpg.private-key))",
                                "GPG_KEY_ID": "((gpg.key-id))"
                            },
                    arguments: [
                                "/gpg-init.sh",
                                "repo-add",
                                "--verify",
                                "--sign",
                                "-n",
                                "index/mdicsme.db.tar.gz",
                            ] + [
                                std.format("%s/*.pkg.tar.zst", [resource])
                                for resource in resources
                            ]
                }),
            ]
        else if type == "rpm" then
        [
            step.task({
                name: "rebuild-rpm-index",
                image: convert_image("rpm"),
                inputs: ["packaged","version","index"],
                outputs: ["index"],
                arguments: "createrepo --update --cachedir cache -o index packaged"           
            }),
            step.task({
                name: "resign-rpm-index",
                image: convert_image("rpm"),
                inputs: ["packaged","version","index"],
                outputs: ["index"],
                arguments: "/gpg-init.sh gpg --yes --detach-sign --armor index/repodata/repomd.xml",
                params: {
                    "GPG_PRIVATE_KEY": "((gpg.private-key))",
                    "GPG_KEY_ID": "((gpg.key-id))"
                },          
            })
        ]
        else if type == "deb" then
        [

        ] else 
        [

        ],
}