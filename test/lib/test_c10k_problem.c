#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <netinet/in.h>

#define NUM_CLIENT      (10000)

int main(int argc, char **argv){
  int status = EXIT_SUCCESS;

  /* fill sockattr */
  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(8081);
  addr.sin_addr.s_addr = inet_addr("127.0.0.1");
  
  int i, j, s[NUM_CLIENT];
  for(i = 0; i < NUM_CLIENT; ++i){
    /* create socket */
    s[i] = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    int result = connect(s[i], (struct sockaddr*)&addr, sizeof(addr));
    if(result != 0){
      printf("failed to connect.");
      for(j = 0; j < i; ++j){
        close(s[j]);
      }
      return EXIT_FAILURE;
    }

    char hdr[] = "POST /chat/test HTTP/1.1\r\n";
    char host[] = "Host: 127.0.0.1\r\n\r\n";
    write(s[i], hdr, strlen(hdr));
    write(s[i], host, strlen(host));

    int n = i + 1;
    if(n % 10 == 0) printf(".");
    if(n % 100 == 0) printf(" %d connections\n", n);
  }

  /* close fd and exit */
  for(i = 0; i < NUM_CLIENT; ++i){
    close(s[i]);
  }
  return status;
}
