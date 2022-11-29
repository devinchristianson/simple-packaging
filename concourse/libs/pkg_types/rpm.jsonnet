local resources = import '../resources.jsonnet';
local fpm = import '../fpm.jsonnet';
local image = import '../image.jsonnet';
local concourse = import '../concourse.jsonnet';
local step = import '../step.jsonnet';
local generic_packager = import 'generic.jsonnet';
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
    type: "rpm",
    final_artifact: resources.s3("rpm-pkg-" + pkg.name, "pkg.mdics.me", "rpm/" + pkg.name + "-(.*).x86_64.rpm", ),
    resources: [
        this.final_artifact,
    ],
    finish_build: [
        step.task({
                name: "sign-rpm-" + pkg.name,
                image: generic_packager.image("rpm"),
                inputs: ["packaged"],
                outputs: ["packaged"],
                params: {
                            "GPG_PRIVATE_KEY": "((gpg.private-key))",
                            "GPG_KEY_ID": "((gpg.key-id))"
                        },
                arguments: [
                            "/gpg-init.sh",
                            "rpm",
                            "--addsign",
                            std.format("packaged/%s-((.:current-version))-1.x86_64.rpm", [pkg.name])
                        ]
            }),
            {
                "put": "rpm-pkg-" + pkg.name,
                "params": {
                    "file": "packaged/" + pkg.name + "-*.x86_64.rpm"
                }
            }
    ],
    image: generic_packager.image("rpm"),
    
}   