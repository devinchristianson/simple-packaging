# package definitions to convert github releases or other resources into packages available at pkg.mdics.me
local packages_defs = [
    {
        name: "hello-world",
        version: "0.1.0", # required, can be a command that evaluates the version based on the various inputs
        depends: "bash", # if none, leave out field
        license: "MIT", # required w/ content
        url: "https://github.com/devinchristianson/simple-packaging",
        description: "Simple hello world program",
        file_mappings: [
            "simple-packaging/packages/hello-world/hello=/usr/bin/hello-world"
        ],
        resources: [
            {
                "name": "simple-packaging",
                "type": "git",
                "source": {
                    "uri": "https://github.com/devinchristianson/simple-packaging.git",
                    "branch": "main",
                    "private_key": "((github.private_key))",
                    "paths": [
                        "packages/hello-world/*"
                    ]
                },
                #trigger field is hidden as this is eventually rendered as a concourse resource
                "trigger":: true
            }
        ]
    },
    {
        name: "yq",
        #version can be a command that evaluates the version based on the various inputs
        version: "$(cat yq-release/tag)",
        license: "Apache 2.0",
        url: "https://github.com/mikefarah/yq",
        description: "yq is a portable command-line YAML, JSON, XML, CSV and properties processor",
        file_mappings: [
            "yq-release/yq_linux_amd64=/usr/bin/yq"
        ],
        resources: [
            {
                "name": "yq-release",
                "type": "github-release",
                "source": {
                    owner: "mikefarah",
                    repository: "yq",
                    access_token: "((github.access_key))"
                },
                #these fields are hidden as this is eventually rendered as a concourse resource
                "trigger":: true,
                "params":: {
                    globs: ["yq_linux_amd64"]
                }
            }
        ]
    },
//    {
//        name: "jq",
//        #version can be a command that evaluates the version based on the various inputs
//        version: "$(cat jq-release/tag)",
//        license: "Custom",
//        url: "https://github.com/stedolan/jq",
//        description: "Simple hello world program",
//        file_mappings: [
//            "yq-release/jq-linux64=/usr/bin/jq"
//        ],
//        resources: [
//            {
//                "name": "yq-release",
//                "type": "github-release",
//                "source": {
//                    owner: "stedolan",
//                    repository: "jq",
//                    access_token: "((github.access_key))"
//                },
//                #these fields are hidden as this is eventually rendered as a concourse resource
//                "trigger":: true,
//                "params":: {
//                    globs: ["jq-linux64"]
//                }
//            }
//        ]
//    }
];
####### now to actually generate the concourse pipeline
local resources = import 'libs/resources.jsonnet';
local packager = import 'libs/pkg.jsonnet';
local image = import 'libs/image.jsonnet';
{
    local packages = [
        packager(type, pkg),    #generate packages per-type-per-package
        for pkg in packages_defs
        for type in packager().implementations
    ],
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
        resources.simple_s3("index", "pkg.mdics.me"),
    ] + std.flattenArrays([ # pull in resources required per-package-job
        pkg.resources,
        for pkg in packages
    ] + [                   # pull in shared resources per-package 
        pkg.resources,
        for pkg in packages_defs
    ] + [ packager().images ],   #pull in image resources per-type, using the generic packager
    ),
    jobs: [
        pkg.job,
        for pkg in packages
    ],
    groups: [
        {
            name: pkg.name,
            jobs: [
                "package-*-" + pkg.name
            ]
        }
        for pkg in packages_defs
    ]
}