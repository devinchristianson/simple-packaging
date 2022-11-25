local generic_packager = import 'pkg.jsonnet';
{
    task(pkg, type, architecture):: {
        local packager = generic_packager(type),
        "task": "build-" + type + "-" + pkg.name,
        "config": {
            "platform": "linux",
            "image_resource": packager.image,
            "inputs": [
                {
                    "name": resource.name,
                }
                for resource in pkg.resources
            ],
            "outputs": [
                {
                    "name": "output"
                }
            ],
            "run": {
                "path": "fpm",
                "args": [
                    "-t",
                    type,
                    "-s",
                    "dir",
                    "--name",
                    pkg.name,
                    "--version",
                    pkg.version,
                    "--architecture",
                    architecture,
                    "--depends",
                    pkg.depends,
                    "--description",
                    pkg.description,
                    "-p",
                    "../../../output/",   
                ] + pkg.file_mappings,
                "dir": "simple-packaging/packages/" + pkg.name
            }
        }
    },
}   