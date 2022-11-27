local resources = import '../resources.jsonnet';
local fpm = import '../fpm.jsonnet';
local pkg_lib = import '../pkg.jsonnet';
local image = import '../image.jsonnet';
local concourse = import '../concourse.jsonnet';
local step = import '../step.jsonnet';
local generic_packager = pkg_lib();
local pkg_resources(pkg) = {
    main_artifact: "pacman-pkg-" + pkg.name,
    main_artifact_sig: "pacman-pkg-" + pkg.name + "-sig"
};
local test_pkg = {
    name: "test",
    version: "0.0.0",
    depends: "",
    url: "",
    license: "",
    description: "",
    file_mappings: [
    ],
    resources: [
        {
            name: "simple-packaging",
            trigger: true
        }
    ]
};
function(pkg=test_pkg) {
    local resourcer = pkg_resources(pkg),
    resources: [
        resources.s3(resourcer.main_artifact, "pkg.mdics.me", "pacman/" + pkg.name + "-(.*)-x86_64.pkg.tar.zst", ),
        resources.s3(resourcer.main_artifact_sig, "pkg.mdics.me", "pacman/" + pkg.name + "-(.*)-x86_64.pkg.tar.zst.sig")
    ],
    job: {
        "name": std.format("package-pacman-%s",pkg.name),
        "serial_groups": [
            "pacman"
        ],
        "plan":  [
            concourse.in_parallel([
                {
                    "get": resource.name,
                    "trigger": resource.trigger,
                    [if std.objectHasEx(resource, "params", true) then "params" else null]: resource.params
                },
                for resource in pkg.resources
            ] + [
                {
                    "get": "index",
                    "params": {
                        "prefix": "pacman",
                        "options": [
                            "--exclude '*'",
                            "--include 'mdicsme.db'",
                            "--include 'mdicsme.files'",
                            "--include 'mdicsme.*.tar.gz'",
                            "--include 'mdicsme.*.tar.gz.sig'"
                        ]
                    }
                },
                {
                    "get": generic_packager.image("pacman")
                }
            ]),
            fpm.saveVersion(pkg.version, pkg.resources),
            fpm.task(pkg, "pacman"),
            step.task({
                name: "sign-pacman-" + pkg.name,
                image: generic_packager.image("pacman"),
                inputs: ["packaged", "version"],
                outputs: ["packaged"],
                params: {
                            "GPG_PRIVATE_KEY": "((gpg.private-key))",
                            "GPG_KEY_ID": "((gpg.key-id))"
                        },
                in_shell: true,
                arguments: [
                            "/gpg-init.sh",
                            "gpg",
                            "--use-agent",
                            "--output",
                            std.format("packaged/%s-$(cat version/version)-1-x86_64.pkg.tar.zst.sig", [pkg.name]),
                            "--detach-sig",
                            std.format("packaged/%s-$(cat version/version)-1-x86_64.pkg.tar.zst", [pkg.name])
                        ]
            }),
            concourse.in_parallel([
                {
                    "put": resourcer.main_artifact,
                    "params": {
                        "file": "packaged/" + pkg.name + "-*-x86_64.pkg.tar.zst"
                    }
                },
                {
                    "put": resourcer.main_artifact_sig,
                    "params": {
                        "file": "packaged/" + pkg.name + "-*-x86_64.pkg.tar.zst.sig"
                    }
                },
                concourse.in_series([
                    step.task({
                        name: "rebuild-index-for-pacman-" + pkg.name,
                        image: generic_packager.image("pacman"),
                        inputs: ["packaged","version","index"],
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
                                    std.format("packaged/%s-$(cat version/version)-1-x86_64.pkg.tar.zst", [pkg.name])
                                ]
                    }),
                    {
                        local params = {
                            "prefix": "pacman",
                            "source_dir": "index",
                            "options": [
                                "--exclude '*'",
                                "--include 'mdicsme.db'",
                                "--include 'mdicsme.files'",
                                "--include 'mdicsme.*.tar.gz'",
                                "--include 'mdicsme.*.tar.gz.sig'"
                            ]
                        },
                        "put": "index",
                        "params": params,
                        "get_params": params # needed to avoid downloading the whole S3 bucket
                    }
                ])
            ])
        ]
    },
    image: generic_packager.image("pacman"),
    
}   