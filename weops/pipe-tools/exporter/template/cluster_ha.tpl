apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pg-exporter-cluster-ha-{{VERSION}}
  namespace: postgres
spec:
  serviceName: pg-exporter-cluster-ha-{{VERSION}}
  replicas: 1
  selector:
    matchLabels:
      app: pg-exporter-cluster-ha-{{VERSION}}
  template:
    metadata:
      annotations:
        telegraf.influxdata.com/interval: 1s
        telegraf.influxdata.com/inputs: |+
          [[inputs.cpu]]
            percpu = false
            totalcpu = true
            collect_cpu_time = true
            report_active = true

          [[inputs.disk]]
            ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

          [[inputs.diskio]]

          [[inputs.kernel]]

          [[inputs.mem]]

          [[inputs.processes]]

          [[inputs.system]]
            fielddrop = ["uptime_format"]

          [[inputs.net]]
            ignore_protocol_stats = true

          [[inputs.procstat]]
          ## pattern as argument for pgrep (ie, pgrep -f <pattern>)
            pattern = "exporter"
        telegraf.influxdata.com/class: opentsdb
        telegraf.influxdata.com/env-fieldref-NAMESPACE: metadata.namespace
        telegraf.influxdata.com/limits-cpu: '300m'
        telegraf.influxdata.com/limits-memory: '300Mi'
      labels:
        app: pg-exporter-cluster-ha-{{VERSION}}
        exporter_object: postgres
        object_mode: cluster
        object_version: {{VERSION}}
        pod_type: exporter
    spec:
      nodeSelector:
        node-role: worker
      shareProcessNamespace: true
      containers:
      - name: pg-exporter-cluster-ha-{{VERSION}}
        image: registry-svc:25000/library/postgres-exporter:latest
        imagePullPolicy: Always
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        args:
        - --collector.xlog_location
        - --collector.long_running_transactions
        - --collector.postmaster
        - --collector.stat_statements
        env:
        - name: DATA_SOURCE_HOST
          value: "pg-cluster-ha-{{VERSION}}-postgresql-ha-pgpool.postgres"
        - name: DATA_SOURCE_PORT
          value: "5432"
        - name: DATA_SOURCE_USER
          value: "weops"
        - name: DATA_SOURCE_PASS
          value: "Weops123!"
        - name: DATA_SOURCE_DB
          value: "postgres"
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 300m
            memory: 300Mi
        ports:
        - containerPort: 9187

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: pg-exporter-cluster-ha-{{VERSION}}
  name: pg-exporter-cluster-ha-{{VERSION}}
  namespace: postgres
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9187"
    prometheus.io/path: '/metrics'
spec:
  ports:
  - port: 9187
    protocol: TCP
    targetPort: 9187
  selector:
    app: pg-exporter-cluster-ha-{{VERSION}}
