{
    task(task):: {
        local task_config = import 'task_config.jsonnet',
        "task": task.name,
        [if std.type(task.image) =="string" then "image" else null]: task.image,
        "config": task_config(task)
    }
}