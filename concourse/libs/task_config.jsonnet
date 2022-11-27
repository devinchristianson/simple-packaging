local image = import 'image.jsonnet';
local test_task = {
    name: "test-task",
    inputs: [],
    outputs: [],
    image: "",
    arguments: "",
};
function(task=test_task) {
            "platform": "linux",
            [if std.type(task.image) =="object" then "image_resource" else null]: 
                if std.type(task.image) =="object" then task.image else image(task.image),
            "inputs": [
                {
                    "name": input,
                }
                for input in task.inputs
            ],
            "outputs": [
                {
                    "name": output,
                }
                for output in task.outputs
            ],
            "run": 
                if std.type(task.arguments) == "string" then 
                    if std.get(task, "in_shell", false) then 
                        {
                            "path": "sh",
                            "args":[
                                "-exc",
                                task.arguments
                            ]
                        }
                    else 
                        local args = std.split(task.arguments, " ");
                        {
                            "path": args[0],
                            "args": args[1:],
                        }
                else if std.type(task.arguments) == "array" then
                    if std.get(task, "in_shell", false) then
                        {
                            "path": "sh",
                            "args":[
                                "-exc",
                                std.join(" ", task.arguments)
                            ]
                        }
                    else 
                        {
                            "path": task.arguments[0],
                            "args": task.arguments[1:],
                        }
                else 
                    task.arguments
                ,
            [if std.objectHas(task, "params") then "params" else null]: std.get(task, "params"),
            [if std.objectHas(task, "run_dir") then "dir" else null]: std.get(task, "run_dir"),
        }