# jemter-k8s

Automated JMeter stress test runner for Kubernetes or OpenShift.

## What this project provides

- A container image with Apache JMeter.
- A direct runner script (`/opt/run-jmeter.sh`) to execute any `.jmx` test plan.
- A sample Kubernetes/OpenShift-compatible Job manifest.

## Run a custom test file directly

Put your test file in the container (for example by mounting a volume to `/tests`) and run:

```bash
/opt/run-jmeter.sh /tests/your-test-plan.jmx
```

The script also supports environment variables:

- `TEST_PLAN` (default: `/tests/test.jmx`)
- `RESULTS_FILE` (default: `/results/results.csv`)
- `LOG_FILE` (default: `/results/jmeter.log`)
- `RESULTS_FORMAT` (default: `csv`, optional: `xml`)
- `GENERATE_HTML_REPORT` (default: `false`; enable with `true`, `1`, `yes`, or `y`)
- `HTML_REPORT_DIR` (default: `/results/html-report`)

## Add your JMeter test script

Place your `.jmx` test plan in a `tests/` directory at the root of your repository:

```
your-repo/
├── tests/
│   └── test.jmx        ← your JMeter test plan
├── .github/
│   └── workflows/
│       └── load-test.yml
└── .gitlab-ci.yml
```

A sample test plan is provided at [`tests/test.jmx`](tests/test.jmx). It sends HTTP GET requests and accepts the following JMeter properties so you can tune the load and target without editing the file:

| Property | Default | Description |
|---|---|---|
| `TARGET_HOST` | `example.com` | Hostname or IP of the system under test |
| `TARGET_PORT` | `443` | Port number |
| `TARGET_PROTOCOL` | `https` | `http` or `https` |
| `THREADS` | `10` | Number of concurrent virtual users |
| `RAMP_TIME` | `5` | Seconds to reach full thread count |
| `LOOPS` | `1` | Number of iterations per user |

Override any property at runtime with JMeter's `-J` flag (see CI examples below).

## Build image

```bash
docker build -t jemter-k8s:latest .
```

## Run with Docker

```bash
docker run --rm \
  -v "$(pwd)/your-test-plan.jmx:/tests/your-test-plan.jmx:ro" \
  -v "$(pwd)/results:/results" \
  -e GENERATE_HTML_REPORT=true \
  jemter-k8s:latest /tests/your-test-plan.jmx
```

## Run in Kubernetes/OpenShift

1. Create a ConfigMap with your JMeter file:

```bash
kubectl create configmap jmeter-test-plan --from-file=test.jmx=./your-test-plan.jmx
```

2. Run the Job:

```bash
kubectl apply -f k8s/jmeter-job.yaml
```

## Resource limits

JMeter can be memory- and CPU-intensive. Setting resource limits prevents a single test run from starving other workloads.

The recommended defaults (used throughout this guide) are:

| Resource | Request | Limit |
|---|---|---|
| CPU | `500m` (½ core) | `2000m` (2 cores) |
| Memory | `512Mi` | `2Gi` |

Adjust these values based on the number of threads and the duration of your test. As a rough guide, each 100 concurrent JMeter threads adds ~100 MB of heap. You can also control the JVM heap size by setting the `JVM_ARGS` environment variable before running the script, for example: `JVM_ARGS="-Xms512m -Xmx1536m" /opt/run-jmeter.sh tests/test.jmx`.

## Use in GitHub Actions (CSV + HTML artifacts)

Add a workflow file at `.github/workflows/load-test.yml`. The checkout step places your repository (including `tests/test.jmx`) under `/github/workspace`.

```yaml
name: load-test
on: [workflow_dispatch]

jobs:
  jmeter:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/pewpewlab/jemter-k8s:latest
      # Limit the container to 2 CPUs and 2 GB of RAM to prevent resource hogging
      options: "--cpus 2 --memory 2g --memory-swap 2g"
    steps:
      - uses: actions/checkout@v4

      - name: Create results directory
        run: mkdir -p /github/workspace/results

      - name: Run JMeter load test
        # Pass -J flags to override test plan properties without editing the .jmx file.
        # Replace TARGET_HOST with the hostname of the system you want to test.
        run: >-
          /opt/run-jmeter.sh /github/workspace/tests/test.jmx
          -JTARGET_HOST=my-service.example.com
          -JTARGET_PORT=443
          -JTARGET_PROTOCOL=https
          -JTHREADS=20
          -JRAMP_TIME=10
          -JLOOPS=5
        env:
          RESULTS_FILE: /github/workspace/results/results.csv
          LOG_FILE: /github/workspace/results/jmeter.log
          GENERATE_HTML_REPORT: "true"
          HTML_REPORT_DIR: /github/workspace/results/html-report

      - name: Upload load test artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: jmeter-results
          path: |
            results/results.csv
            results/jmeter.log
            results/html-report/
```

## Use in GitLab CI (CSV + HTML artifacts)

Add a job to your `.gitlab-ci.yml`. GitLab checks out your repository under `$CI_PROJECT_DIR`, so `tests/test.jmx` is available automatically.

```yaml
load_test:
  image: ghcr.io/pewpewlab/jemter-k8s:latest
  stage: test
  variables:
    RESULTS_FILE: "$CI_PROJECT_DIR/results/results.csv"
    LOG_FILE: "$CI_PROJECT_DIR/results/jmeter.log"
    GENERATE_HTML_REPORT: "true"
    HTML_REPORT_DIR: "$CI_PROJECT_DIR/results/html-report"
    # Resource limits for the Kubernetes executor (ignored by Docker executor).
    # Adjust values to match your cluster capacity.
    KUBERNETES_CPU_REQUEST: "500m"
    KUBERNETES_CPU_LIMIT: "2000m"
    KUBERNETES_MEMORY_REQUEST: "512Mi"
    KUBERNETES_MEMORY_LIMIT: "2Gi"
  script:
    - mkdir -p "$CI_PROJECT_DIR/results"
    # Pass -J flags to override test plan properties without editing the .jmx file.
    # Replace TARGET_HOST with the hostname of the system you want to test.
    - >-
      /opt/run-jmeter.sh "$CI_PROJECT_DIR/tests/test.jmx"
      -JTARGET_HOST=my-service.example.com
      -JTARGET_PORT=443
      -JTARGET_PROTOCOL=https
      -JTHREADS=20
      -JRAMP_TIME=10
      -JLOOPS=5
  artifacts:
    when: always
    paths:
      - results/results.csv
      - results/jmeter.log
      - results/html-report/
```
