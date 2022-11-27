local resources = import '../resources.jsonnet';
local fpm = import '../fpm.jsonnet';
local pkg_lib = import '../pkg.jsonnet';
local image = import '../image.jsonnet';
local concourse = import '../concourse.jsonnet';
local step = import '../step.jsonnet';
local generic_packager = pkg_lib();
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
    resources: [
        resources.s3("rpm-pkg-" + pkg.name, "pkg.mdics.me", "rpm/" + pkg.name + "-(.*).x86_64.rpm", ),
    ],
    job: {
        "name": std.format("package-rpm-%s",pkg.name),
        "serial_groups": [
            "rpm"
        ],
        "plan":  [
            concourse.in_parallel([
                {
                    "get": resource.name,
                    "trigger": resource.trigger,
                    [if std.objectHasEx(resource, "params", true) then "params" else null]: resource.params
                }
                for resource in pkg.resources
            ] + [
                {
                    "get": "index",
                    "params": {
                        "prefix": "rpm",
                        "options": [
                            "--exclude '*'",
                            "--include 'repodata/*'",
                            "--include 'cache/*'",
                        ]
                    }
                },
                {
                    "get": generic_packager.image("rpm")
                }
            ]),
            fpm.saveVersion(pkg.version, pkg.resources),
            fpm.task(pkg, "rpm"),
            step.task({
                name: "sign-rpm-" + pkg.name,
                image: generic_packager.image("rpm"),
                inputs: ["packaged", "version"],
                outputs: ["packaged"],
                params: {
                            "GPG_PRIVATE_KEY": "((gpg.private-key))",
                            "GPG_KEY_ID": "((gpg.key-id))"
                        },
                in_shell: true,
                arguments: [
                            "/gpg-init.sh",
                            "rpm",
                            "--addsign",
                            std.format("packaged/%s-$(cat version/version)-1.x86_64.rpm", [pkg.name])
                        ]
            }),
            concourse.in_parallel([
                {
                    "put": "rpm-pkg-" + pkg.name,
                    "params": {
                        "file": "packaged/" + pkg.name + "-*.x86_64.rpm"
                    }
                },
                concourse.in_series([
                    step.task({
                        name: "rebuild-index-for-rpm-" + pkg.name,
                        image: generic_packager.image("rpm"),
                        inputs: ["packaged","version","index"],
                        outputs: ["index"],
                        arguments: "createrepo --update --cachedir cache -o index packaged"           
                    }),
                    step.task({
                        name: "resign-index-for-rpm-" + pkg.name,
                        image: generic_packager.image("rpm"),
                        inputs: ["packaged","version","index"],
                        outputs: ["index"],
                        arguments: "/gpg-init.sh gpg --yes --detach-sign --armor index/repodata/repomd.xml",
                        params: {
                            "GPG_PRIVATE_KEY": "((gpg.private-key))",
                            "GPG_KEY_ID": "((gpg.key-id))"
                        },          
                    }),
                    {
                        local params = {
                            "prefix": "rpm",
                            "source_dir": "index",
                            "options": [
                                "--exclude '*'",
                                "--include 'repodata/*'",
                                "--include 'cache/*'",
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
    image: generic_packager.image("rpm"),
    
}   