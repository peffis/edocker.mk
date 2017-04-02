#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

/**********************************************************
 * simple erlang runner for the edocker release image
 * 
 * it currently allows you to set cookie, name and host as 
 * environment variables name and host will be joined 
 * as name@host to form the -name argument to erlexec
 **********************************************************/

#define MAX_PATH 4096
#define MAX_NAME 256

#ifndef ERTS_VERSION
#define ERTS_VERSION "8.2"
#endif

#ifndef REL_VSN
#define REL_VSN "0.1.0"
#endif

#ifndef REL_NAME
#define REL_NAME "release_name"
#endif


#define BINDIR "/erts-" ERTS_VERSION "/bin"



int
main() {
	char path[MAX_PATH];
	char boot[MAX_PATH];
	char config[MAX_PATH];
	char name_arg[MAX_NAME];
	char *argv[13];

	/* -boot_var argument */
	argv[0] = "-boot_var"; argv[1] = "ERTS_LIB_DIR"; argv[2] = "/lib";

	/* -boot argument */
	sprintf(boot, "/releases/1/%s", REL_NAME);
	argv[3] = "-boot"; argv[4] = boot;

	/* -config argument */
	sprintf(config, "/releases/1/sys.config");
	argv[5] = "-config"; argv[6] = config;

	/* -setcookie argument */
	argv[7] = "-setcookie"; argv[8] = getenv("EDOCKER_COOKIE");
	
	/* -name argument */
	sprintf(name_arg, "%s@%s", getenv("EDOCKER_NAME"), getenv("EDOCKER_HOST"));
	argv[9] = "-name"; argv[10] = name_arg;

	/* -noinput */
	argv[11] = "-noinput"; 



	argv[12] = NULL;

	sprintf(path, "%s/erlexec", BINDIR);


	/* log info */
	fprintf(stderr, "%s ", path);
	int i = 0;
	while (argv[i] != NULL) {
		fprintf(stderr, "%s%s", argv[i], argv[i+1] != NULL ? " " : "\n");
		i++;
	}
	
	return execv(path, argv);
}
  
