local generic_packager = import 'pkg_types/generic.jsonnet';
local image = import 'image.jsonnet';
local step = import 'step.jsonnet';
{
    //this saves the version to the 
    saveVersion(version, resources):: 
            step.task({
                name: "save-version",
                image: image("alpine"),
                //
                inputs: [resource.name for resource in resources ],
                outputs: ["version"],
                arguments: "echo " + version + " > version/version",
                in_shell: true
            }),
    task(pkg, type):: 
        local depends = if std.objectHas(pkg, 'depends') then
                        [
                            "--depends",
                            pkg.depends
                        ]
                        else 
                            []
                        ;
        step.task({
            name: "package-" + type + "-" + pkg.name,
            inputs: [
                resource.name
                for resource in pkg.build_resources
            ] + [ "version" ],
            outputs: ["packaged"],
            image: generic_packager.image(type),
            in_shell: true,
            arguments: [
                    "fpm",
                    "-t",
                    type,
                    "-s",
                    "dir",
                    "--name",
                    pkg.name,
                    "--version",
                    "$(cat version/version)",
                    "--architecture",
                    "native",
                    "--description",
                    std.escapeStringBash(pkg.description),
                    "--license",
                    std.escapeStringBash(pkg.license),
                    "--url",
                     std.escapeStringBash(pkg.url),
                    "--vendor",
                    std.escapeStringBash("Built by github.com/devinchristianson/simple-packaging"),
                    "-p",
                    "packaged/",   
                ] + depends + pkg.file_mappings
        }) 
}   