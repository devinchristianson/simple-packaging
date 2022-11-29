{
    task(task):: {
        local task_config = import 'task_config.jsonnet',
        "task": task.name,
        [if std.objectHas(task, "input_mapping") then "input_mapping" else null]: task.input_mapping,
        [if std.objectHas(task, "output_mapping") then "output_mapping" else null]: task.output_mapping,
        [if std.type(task.image) == "string" then "image" else null]: task.image,
        "config": task_config(task)
    },
    in_parallel(tasks):: {
        "in_parallel": tasks
    },
    in_series(tasks):: {
        "do": tasks
    }
}