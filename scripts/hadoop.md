### HDFS cluster and YARN cluster

| vm    | role                                 | ip             | xxx_home    |
|-------|--------------------------------------|----------------|-------------|
| vm116 | NameNode, zkfc, JournalNode          | 192.168.56.116 | /opt/hadoop |
| vm117 | NameNode, zkfc, JournalNode          | 192.168.56.117 | /opt/hadoop |
| vm118 | NameNode, zkfc, JournalNode          | 192.168.56.118 | /opt/hadoop |
| vm119 | DataNode                             | 192.168.56.119 | /opt/hadoop |
| vm120 | DataNode                             | 192.168.56.120 | /opt/hadoop |
| vm121 | DataNode                             | 192.168.56.121 | /opt/hadoop |

| vm    | role     | ip             | xxx_home    |
|-------|----------|----------------|-------------|
| vm116 | yarn RM  | 192.168.56.116 | /opt/hadoop |
| vm117 | yarn RM  | 192.168.56.117 | /opt/hadoop |
| vm118 | yarn RM  | 192.168.56.118 | /opt/hadoop |
| vm119 | yarn NM  | 192.168.56.119 | /opt/hadoop |
| vm120 | yarn NM  | 192.168.56.120 | /opt/hadoop |
| vm121 | yarn NM  | 192.168.56.121 | /opt/hadoop |

```bash
###########################################################
# 以下所有操作都需要在hduser用户下执行
# su -l hduser
###########################################################
# vm116
# hdfs --daemon start journalnode
# hdfs namenode -format (执行一次)
# hdfs zkfc -formatZK (执行一次)
# hdfs --daemon start namenode && hdfs --daemon start zkfc



# vm117 vm118
# hdfs --daemon start journalnode
# hdfs namenode -bootstrapStandby （执行一次）
# hdfs --daemon start namenode && hdfs --daemon start zkfc


## test hdfs HA
(
hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2
hdfs haadmin -getServiceState nn3
)

active
standby
standby


# vm119 vm120 vm121
# hdfs --daemon start datanode
```

```bash
# yarn --daemon start resourcemanager   //vm116 vm117 vm118
# yarn --daemon start nodemanager       //vm119 vm120 vm121
```