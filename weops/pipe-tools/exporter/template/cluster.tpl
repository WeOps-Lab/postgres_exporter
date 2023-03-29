apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
  namespace: postgres
spec:
  serviceName: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
  replicas: 1
  selector:
    matchLabels:
      app: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
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
        app: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
        exporter_object: postgres
        object_mode: cluster
        object_version: {{VERSION}}
        pod_type: exporter
    spec:
      nodeSelector:
        node-role: worker
      shareProcessNamespace: true
      volumes:
        - name: pg-extend-queries
          configMap:
            name: pg-extend-queries
      containers:
      - name: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
        image: registry-svc:25000/library/postgres-exporter:latest
        imagePullPolicy: Always
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        args:
          - --extend.query-path=/query_conf/queries.yaml
          - --log.level=debug
        volumeMounts:
          - mountPath: /query_conf
            name: pg-extend-queries
        env:
        - name: DATA_SOURCE_NAME
          value: "postgresql://weops:Weops123!@pg-cluster-{{VERSION}}-postgresql-{{ARCHITECTURE}}.postgres:5432/postgres?sslmode=disable"
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
    app: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
  name: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
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
    app: pg-exporter-cluster-{{ARCHITECTURE}}-{{VERSION}}
