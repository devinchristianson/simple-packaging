{
    simple_s3(name, bucket, endpoint="s3.us-east-2.wasabisys.com"):: {
        "name": name,
        "type": "simple-s3",
        "source": {
            "access_key_id": "((s3-mdics-repo.access-key))",
            "secret_access_key": "((s3-mdics-repo.secret-key))",
            "bucket": bucket,
            "aws_options": [
                "--endpoint-url " + std.format("https://%s/", endpoint)
            ]
        }
    },
    s3(name, bucket, regexp, endpoint="s3.us-east-2.wasabisys.com"):: {
        "name": name,
        "type": "s3",
        "source": {
            "regexp": regexp,
            "bucket": bucket,
            "endpoint": endpoint,
            "access_key_id": "((s3-mdics-repo.access-key))",
            "secret_access_key": "((s3-mdics-repo.secret-key))"
        }
    }
}