local generic = import 'pkg_types/generic.jsonnet';
local concourse = import 'concourse.jsonnet';
local fpm = import 'fpm.jsonnet';
local step = import 'step.jsonnet';
local image = import 'image.jsonnet';
local resources = import 'resources.jsonnet';
function (pkg_defs=[])
{
    local packages = [
        generic.implementations[type](pkg),    #generate packages per-type-per-package
        for pkg in pkg_defs
        for type in generic.types
    ],
    resources: std.flattenArrays([ # pull in resources required per-package-job
            pkg.resources,
            for pkg in packages
        ] + [                   # pull in shared resources per-package 
            pkg_def.build_resources,
            for pkg_def in pkg_defs
        ]) + [
            resources.keyval(
                type + "-needs-indexing",
                "pkg.mdics.me",
                type + "/.index_status"
            )
            for type in generic.types 
        ] + generic.images, //shared type-specific resources
    jobs: [     //per-package build jobs
            {
                local indexName = pkg.type + "-needs-indexing",
                name: std.format("package-%s-%s", [pkg.type, pkg.name]),
                serial_groups: [std.format("%s-reindex", [pkg.type])],
                plan: [
                    step.in_parallel([
                            {
                                "get": resource.name,
                                "trigger": resource.trigger,
                                [if std.objectHasEx(resource, "params", true) then "params" else null]: resource.params
                            },
                            for resource in pkg.build_resources
                        ] + [
                            {
                                "get": generic.image(pkg.type)
                            }
                        ]),
                        step.task({
                            name: "save-version",
                            image: image("alpine"),
                            # needs all build resources as we don't know where the version might be
                            inputs: [resource.name for resource in pkg.build_resources ],
                            outputs: ["version"],
                            # saves the version to the version file (interpreting any bash), then replaces illegal chars with underscore
                            arguments: "echo " + pkg.version + " | sed -r 's/[-]+/_/g' > version/version",
                            in_shell: true
                        }),
                        {
                        "load_var": "current-version",
                        "file": "version/version"
                        },
                        fpm.task(pkg, pkg.type),
                ] + pkg.finish_build + [
                    {
                        "get": indexName
                    },
                    {   # mark this index as requiring a rebuild
                        "put": indexName,
                        "params": {
                            "mapping" : std.format(|||
                                root = file("%s").parse_json()
                                root."%s" = "false"
                            |||, [indexName + "/version.json", pkg.name])
                        }
                    }
                ]
            },
            for pkg in packages
    ] + [   //shared per-type re-indexing jobs
            {
                local indexName = type + "-needs-indexing",
                local isType(pkg) = pkg.type == type,
                name: type + "-reindex",
                serial_groups: [std.format("%s-reindex", [type])],
                serial: true,
                plan: [
                    {
                        "get": indexName
                    },
                    {
                        "load_var": "needs-indexing",
                        "file": indexName + "/version.json"
                    },
                    step.in_parallel([
                        {
                            "get": "index",
                            "params": generic.getIndexParams(type)
                        },
                        {
                            "get": generic.image(type)
                        }
                    ] + [
                        {
                            "get": pkg.final_artifact.name,
                            "passed": [ std.format("package-%s-%s", [pkg.type, pkg.name]) ],
                            "trigger": true,
                            "params": {
                                # avoids downloading packages that don't need re-indexing
                                "skip_download": std.format("((.:needs-indexing.%s))", [pkg.name]) 
                            }
                        }
                        for pkg in std.filter(isType, packages)
                    ]),
                ] + generic.reindex(type, [
                   pkg.final_artifact.name
                   for pkg in std.filter(isType, packages)
                ]) +
                [
                    {
                        local params = generic.getIndexParams(type),
                        "put": "index",
                        "params": params,
                        "get_params": params # needed to avoid downloading the whole S3 bucket
                    }
                ]
                + [
                    {
                        "put": indexName,
                        "params": {
                            "mapping" : std.format(|||
                                root = file("%s").parse_json()
                                map thing {
                                    root = "true"
                                }
                                root = root.map_each(raw -> raw.apply("thing"))
                            |||, [indexName + "/version.json"]) //configure to skip all versions
                        }
                    }
                ]
            }
            for type in generic.types
        ] 
}