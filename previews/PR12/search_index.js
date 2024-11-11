var documenterSearchIndex = {"docs":
[{"location":"#JobQueueMPI.jl","page":"Home","title":"JobQueueMPI.jl","text":"","category":"section"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You can install JobQueueMPI.jl using the Julia package manager. From the Julia REPL, type ] to enter the Pkg REPL mode and run:","category":"page"},{"location":"","page":"Home","title":"Home","text":"pkg> add JobQueueMPI","category":"page"},{"location":"#How-it-works","page":"Home","title":"How it works","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"First, when running a program using MPI, the user has to set the number of processes that will parallelize the computation. One of these processes will be the controller, and the others will be the workers.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We can easily delimit the areas of the code that will be executed only by the controller or the worker.","category":"page"},{"location":"","page":"Home","title":"Home","text":"JobQueueMPI.jl has the following components:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Controller: The controller is responsible for managing the jobs and the workers. It keeps track of the jobs that have been sent and received and sends the jobs to the available workers.\nWorker: The worker is responsible for executing the jobs. It receives the jobs from the controller, executes them, and sends the results back to the controller.","category":"page"},{"location":"#API","page":"Home","title":"API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"JobQueueMPI.Controller\nJobQueueMPI.Worker\nJobQueueMPI.add_job_to_queue!\nJobQueueMPI.send_jobs_to_any_available_workers\nJobQueueMPI.send_termination_message\nJobQueueMPI.check_for_job_answers\nJobQueueMPI.send_job_answer_to_controller\nJobQueueMPI.receive_job\nJobQueueMPI.get_message\nJobQueueMPI.pmap","category":"page"},{"location":"#JobQueueMPI.Controller","page":"Home","title":"JobQueueMPI.Controller","text":"Controller\n\nThe controller struct is used to manage the workers and the jobs. It keeps track of the workers' status, the job queue, and the pending jobs. It also keeps track of the last job id that was sent to the workers.\n\n\n\n\n\n","category":"type"},{"location":"#JobQueueMPI.Worker","page":"Home","title":"JobQueueMPI.Worker","text":"Worker\n\nA worker process.\n\n\n\n\n\n","category":"type"},{"location":"#JobQueueMPI.add_job_to_queue!","page":"Home","title":"JobQueueMPI.add_job_to_queue!","text":"add_job_to_queue!(controller::Controller, message::Any)\n\nAdd a job to the controller's job queue.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.send_jobs_to_any_available_workers","page":"Home","title":"JobQueueMPI.send_jobs_to_any_available_workers","text":"send_jobs_to_any_available_workers(controller::Controller)\n\nSend jobs to any available workers.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.send_termination_message","page":"Home","title":"JobQueueMPI.send_termination_message","text":"send_termination_message()\n\nSend a termination message to all workers.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.check_for_job_answers","page":"Home","title":"JobQueueMPI.check_for_job_answers","text":"check_for_job_answers(controller::Controller)\n\nCheck if any worker has completed a job and return the answer.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.send_job_answer_to_controller","page":"Home","title":"JobQueueMPI.send_job_answer_to_controller","text":"send_job_answer_to_controller(worker::Worker, message)\n\nSend a job answer to the controller process.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.receive_job","page":"Home","title":"JobQueueMPI.receive_job","text":"receive_job(worker::Worker)\n\nReceive a job from the controller process.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.get_message","page":"Home","title":"JobQueueMPI.get_message","text":"get_message(job::AbstractJob)\n\nGet the message from a job.\n\n\n\n\n\n","category":"function"},{"location":"#JobQueueMPI.pmap","page":"Home","title":"JobQueueMPI.pmap","text":"pmap(f, jobs, data_defined_in_process = nothing)\n\nParallel map function that works with MPI. If the function is called in parallel, it will distribute the jobs to the workers and collect the results. If the function is called in serial, it will just map the function to the jobs.\n\nThe function f should take one argument, which is the message to be processed. If data_defined_in_process is not nothing, the function f should take two arguments, the first one being data_defined_in_process.\n\nThe controller process will return the answer in the same order as the jobs were given. The workers will return nothing.\n\n\n\n\n\n","category":"function"}]
}
