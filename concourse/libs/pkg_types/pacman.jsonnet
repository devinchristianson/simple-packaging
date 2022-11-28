local resources = import '../resources.jsonnet';
local fpm = import '../fpm.jsonnet';
local image = import '../image.jsonnet';
local concourse = import '../concourse.jsonnet';
local step = import '../step.jsonnet';
local generic_packager = import '../pkg_types/generic.jsonnet';
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
function(pkg=test_pkg) pkg + {
    local this = self,
    type: "pacman",
    final_artifact: resources.s3("pacman-pkg-" + pkg.name, "pkg.mdics.me", "pacman/" + pkg.name + "-(.*)-x86_64.pkg.tar.zst", ),
    resources: [
        this.final_artifact,
        resources.s3("pacman-pkg-" + pkg.name + "-sig", "pkg.mdics.me", "pacman/" + pkg.name + "-(.*)-x86_64.pkg.tar.zst.sig")
    ],
    finish_build: [
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
        }), step.in_parallel([
            {
                "put": "pacman-pkg-" + pkg.name,
                "params": {
                    "file": "packaged/" + pkg.name + "-*-x86_64.pkg.tar.zst"
                }
            },
            {
                "put": "pacman-pkg-" + pkg.name + "-sig",
                "params": {
                    "file": "packaged/" + pkg.name + "-*-x86_64.pkg.tar.zst.sig"
                }
            }
        ])   
    ],
}   