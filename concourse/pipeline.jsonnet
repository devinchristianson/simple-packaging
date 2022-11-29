# package definitions to convert github releases or other resources into packages available at pkg.mdics.me
local package_defs = [
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
        build_resources: [
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
        build_resources: [
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
    {
        name: "jq",
        #version can be a command that evaluates the version based on the various inputs
        version: "$(cat jq-release/tag)",
        license: "Custom",
        url: "https://github.com/stedolan/jq",
        description: "Simple hello world program",
        file_mappings: [
            "jq-release/jq-linux64=/usr/bin/jq"
        ],
        build_resources: [
            {
                "name": "jq-release",
                "type": "github-release",
                "source": {
                    owner: "stedolan",
                    repository: "jq",
                    access_token: "((github.access_key))"
                },
                #these fields are hidden as this is eventually rendered as a concourse resource
                "trigger":: true,
                "params":: {
                    globs: ["jq-linux64"]
                }
            }
        ]
    }
];
####### now to actually generate the concourse pipeline
local resources = import 'libs/resources.jsonnet';
local packager_fcn = import 'libs/packager.jsonnet';
local generic = import 'libs/pkg_types/generic.jsonnet';
local packager = packager_fcn(package_defs);
{
    resource_types: [
        {
            "name": "simple-s3",
            "type": "registry-image",
            "source": {
                "repository": "troykinsella/s3-resource-simple"
            }
        },
        {
            "name": "key-value",
            "type": "registry-image",
            "source": {
                "repository": "ghcr.io/cludden/concourse-keyval-resource"
            }
        }
    ],
    resources: [
        resources.simple_s3("index", "pkg.mdics.me"),
    ] + packager.resources,
    jobs: packager.jobs,
#    groups: [
#        {
#            name: pkg.name,
#            jobs: [
#                "package-*-" + pkg.name
#            ]
#        },
#        for pkg in package_defs
#    ] + [
#        {
#            name: type,
#            jobs: [
#                type + "-*",
#                "package-" + type + "-*"
#            ]
#        }
#        for type in generic.types
#    ]
}