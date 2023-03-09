



## Testing your AEM installation

The dispatcher maps `we-retail.docker.local` and `we-retail` to the local Publish instance on port `4503` and `author.docker.local` on port `4502`to  the Author. Make sure, your local `/etc/hosts`  can resolve either name:



```sh
$ cat /etc/hosts | grep we-retail
127.0.0.1 we-retail.docker.local
127.0.0.1 we-retail
```

If you do not see the entries,  add the names to the file:

```sh
$ sudo sh -c 'echo "127.0.0.1 we-retail.docker.local" >> /etc/hosts'
$ sudo sh -c 'echo "127.0.0.1 we-retail" >> /etc/hosts'
$ sudo sh -c 'echo "127.0.0.1 host.docker.local" >> /etc/hosts'
$ sudo sh -c 'echo "127.0.0.1 author.docker.local" >> /etc/hosts'
```

Run the publisher and navigate to [http://we-retail.docker.local/content/we-retail/language-masters/en.html](http://we-retail.docker.local/content/we-retail/language-masters/en.html)

