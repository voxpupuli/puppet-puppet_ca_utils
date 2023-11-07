# puppet\_ca\_utils

Synchrozies certificates from differing Puppet CAs so that agents can be transfered easily between them.

## Usage

### puppet\_ca\_utils::configure\_ca\_server\_trust plan

Basic usage. Configures both puppet-ca-01 and puppet-ca-02 to trust certs issued by either CA.

```
bolt plan run puppet_ca_utils::configure_ca_server_trust \
  --target puppet-ca-01.example.com \
  --target puppet-ca-02.example.com
```

Asymetrical usage. Configures puppet-ca-01 to trust certs issued by either CA, but does not configure puppet-ca-02 to trust puppet-ca-01.

```
bolt plan run puppet_ca_utils::configure_ca_server_trust \
  --target puppet-ca-01.example.com \
  ca_hosts='["puppet-ca-01.example.com","puppet-ca-02.example.com"]'
```

### puppet\_ca\_utils::configure\_agent\_trust task

In order to trust a given CA server, an agent may need to have its CA bundle and CRL refreshed. An example task is included to do this. The example below shows using the task to configure agent-01 to connect to puppet-lb-01.example.com (a load balancer in front of compilers attached to puppet-ca-01.example.com).

```
bolt task run puppet_ca_utils::configure_agent_trust \
  --target agent-01.example.com \
  server=puppet-lb-01.example.com
```

## Limitations

The puppet\_ca\_utils::configure\_ca\_servers plan does not have safeguards. It is possible to accidentally overwrite CA configuration in a non-ideal way if the parameters given are incorrect. For example, it is possible to configure a CA server not to trust its own issued certificates, and lose CA data in the process.

## Development
