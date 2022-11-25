local resources = import 'libs/resources.jsonnet';
local pkg_lib = import 'libs/pkg.jsonnet';

local packages = [
    {
        name: "hello-world",
        version: "0.1.0",
        depends: "bash",
        description: "Simple hello world program",
        file_mappings: [
            "pkg/hello=/usr/bin/hello-world"
        ],
        resources: [
            {
                name: "simple-packaging",
                trigger: true
            }
        ]
    }
];
{
    local packager = pkg_lib("pacman"),
    resource_types: [
        {
            "name": "simple-s3",
            "type": "docker-image",
            "source": {
                "repository": "troykinsella/s3-resource-simple"
            }
        }
    ],
    resources: [
        {
            "name": "simple-packaging",
            "type": "git",
            "source": {
                "uri": "https://github.com/devinchristianson/simple-packaging.git",
                "branch": "main"
            }
        },
        resources.simple_s3("pacman-index", "pkg.mdics.me")
    ] + std.flatMap(packager.resources, packages),
    jobs: [
        packager.job(pkg),
        for pkg in packages
    ]
}