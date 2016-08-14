# logmatic-docker-bash

An alternative to `logmatic-docker` which heavily relies on Node.js and causes hiccups on some clusters for no apparent reason. 

Tested only on OS X, might need a little for work for other unix distros.

# Usage

```
git clone https://github.com/RafalWilinski/logmatic-docker-bash
cd logmatic-docker-bash
chmod a+x ./logmatic.sh
./logmatic.sh -e -a <YOUR_API_KEY>
```

# Parsing data

In order to make any use of incoming data, first you have to enable proper parsing options inside Logmatic console. In order to do that, head to Logmatic Console -> Settings -> Enrichment & Parsing -> ENABLE Key/Value

# Options

Several options are allowed after/before the api key.

```
> ./logmatic.sh -a [apiKey]
   [-e] (Enable sending events)
   [-h HOSTNAME (default "api.logmatic.io")] [-p PORT (default "10514")]
   [-s SECONDS (default 10s)]
```

# What are the data types sent to Logmatic.io?

Scripts sends 3 things:

- [x] the log data published by your containers
- [x] the docker events (e.g. `kill`, `start` `detach`, `die`)
- [ ] docker statistics (e.g cpu usage, mem usage, i/o count)

## License

[MIT License](https://opensource.org/licenses/MIT) © Rafal Wilinski