# cdc-vagrant

## introduce

This project is for experiment of flink-cdc and doris.

CDC(Change Data Capture) is made up of two components, the CDD and the CDT. CDD is stand for Change Data Detection and CDT is stand for Change Data Transfer.

## architecture

| vm  | role               | ip             | xxx_home       |
|-----|--------------------|----------------|----------------|
| vm1 | doris FE(leader)   | 192.168.56.111 | /opt/doris/fe/ |
| vm2 | doris FE(observer) | 192.168.56.112 | /opt/doris/fe/ |
| vm3 | doris BE           | 192.168.56.113 | /opt/doris/be/ |
| vm4 | doris BE           | 192.168.56.114 | /opt/doris/be/ |
| vm5 | doris BE           | 192.168.56.115 | /opt/doris/be/ |
