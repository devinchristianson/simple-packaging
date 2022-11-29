local generic_packager = import 'pkg_types/generic.jsonnet';
local image = import 'image.jsonnet';
local step = import 'step.jsonnet';
{
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
            ],
            outputs: ["packaged"],
            image: generic_packager.image(type),
            arguments: [
                    "fpm",
                    "-t",
                    type,
                    "-s",
                    "dir",
                    "--name",
                    pkg.name,
                    "--version",
                    "((.:current-version))",
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