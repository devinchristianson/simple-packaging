local resources = import '../resources.jsonnet';
local fpm = import '../fpm.jsonnet';
local pkg_lib = import '../pkg.jsonnet';
local generic_packager = pkg_lib();
{
    resources(pkg):: [
        resources.s3("pacman-pkg-" + pkg.name, "pkg.mdics.me", "pacman/" + pkg.name + "-(.*)-any.pkg.tar.zst", ),
        resources.s3("pacman-pkg-" + pkg.name + "-sig", "pkg.mdics.me", "pacman/" + pkg.name + "-(.*)-any.pkg.tar.zst")
    ],
    job(pkg):: {
        "name": "build-packages",
        "serial_groups": [
            "pacman"
        ],
        "plan": [
            {
                "get": resource.name,
                "trigger": resource.trigger
            }
            for resource in pkg.resources
        ] + [
            fpm.task(pkg, "pacman", "all"),
            {
                "task": "sign-pacman-" + pkg.name,
                "config": {
                    "platform": "linux",
                    "image_resource": generic_packager.image("pacman"),
                    "inputs": [
                        {
                            "name": "output"
                        }
                    ],
                    "outputs": [
                        {
                            "name": "output"
                        }
                    ],
                    "run": {
                        "path": "/gpg-init.sh",
                        "args": [
                            "gpg",
                            "--use-agent",
                            "--output",
                            std.format("%s-%s-1-any.pkg.tar.zst.sig", [pkg.name, pkg.version]),
                            "--detach-sig",
                            std.format("%s-%s-1-any.pkg.tar.zst", [pkg.name, pkg.version])
                        ],
                        "dir": "output"
                    },
                    "params": {
                        "GPG_PRIVATE_KEY": "((gpg.private-key))",
                        "GPG_KEY_ID": "((gpg.key-id))"
                    }
                }
            },
            {
                "put": "pacman-pkg-" + pkg.name,
                "params": {
                    "file": "output/" + pkg.name + "-*-any.pkg.tar.zst"
                }
            },
            {
                "put": "pacman-pkg-" + pkg.name + "-sig",
                "params": {
                    "file": "output/" + pkg.name + "-*-any.pkg.tar.zst.sig"
                }
            },
            {
                "get": "pacman-index",
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
                "task": "rebuild-index-for-pacman-" + pkg.name,
                "config": {
                    "platform": "linux",
                    "image_resource": generic_packager.image("pacman"),
                    "inputs": [
                        {
                            "name": "output"
                        },
                        {
                            "name": "pacman-index"
                        }
                    ],
                    "outputs": [
                        {
                            "name": "pacman-index"
                        }
                    ],
                    "run": {
                        "path": "/gpg-init.sh",
                        "args": [
                            "repo-add",
                            "--verify",
                            "--sign",
                            "-n",
                            "mdicsme.db.tar.gz",
                            std.format("../output/%s-%s-1-any.pkg.tar.zst", [pkg.name, pkg.version])
                        ],
                        "dir": "pacman-index"
                    },
                    "params": {
                        "GPG_PRIVATE_KEY": "((gpg.private-key))",
                        "GPG_KEY_ID": "((gpg.key-id))"
                    }
                }
            },
            {
                "put": "pacman-index",
                "params": {
                    "prefix": "pacman",
                    "source_dir": "pacman-index",
                    "options": [
                        "--exclude '*'",
                        "--include 'mdicsme.db'",
                        "--include 'mdicsme.files'",
                        "--include 'mdicsme.*.tar.gz'",
                        "--include 'mdicsme.*.tar.gz.sig'"
                    ]
                }
            }
        ]
    }
}   