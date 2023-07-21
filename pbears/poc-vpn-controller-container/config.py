import argparse
import json
import sys
import os
from jinja2 import Environment, FileSystemLoader

container_configs = \
{ 
	'nginx_user':	'www-data',
	'nginx_group':	'www-data',

	'nginx_worker_processes':4,

	'nginx_pid_file': '/var/run/nginx.pid',
	'nginx_worker_rlimit_nofile': 1024,

	'nginx_events_params': ['worker_connections 512'],

	'nginx_http_params': 
	[
		'sendfile "on"',
        	'tcp_nopush "on"',
        	'tcp_nodelay "on"',
        	'keepalive_timeout 65',
        	'access_log "/var/log/nginx/access.log"',
        	'error_log "/var/log/nginx/error.log"',
        	'server_tokens "off"', 
        	'types_hash_max_size 2048'
	],

	'nginx_conf_dir': '/etc/nginx'
}

if __name__ == "__main__":
    # Create an ArgumentParser object
    parser = argparse.ArgumentParser(description="Use a JSON mapping to resolve J2 file")

    # Add an argument to specify the JSON file
    parser.add_argument("j2_file", help="Path to the J2 file")
    parser.add_argument("out_file", help="Path to the output file")

    # Parse the command-line arguments
    args = parser.parse_args()

    # Load the Jinja2 environment with the current directory as the template directory
    env = Environment(loader=FileSystemLoader('/workdir'))

    # Read the template file
    template = env.get_template(args.j2_file)

    # Render the template with the variables
    rendered_content = template.render(container_configs)

    # Write the resolved content to an output file
    with open(args.out_file, "w") as output_file:
        output_file.write(rendered_content)

