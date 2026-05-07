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
- `GENERATE_HTML_REPORT` (default: `false`, set `true` to enable JMeter dashboard report)
- `HTML_REPORT_DIR` (default: `/results/html-report`)

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

## Use in GitHub Actions (CSV + HTML artifacts)

```yaml
name: load-test
on: [workflow_dispatch]

jobs:
  jmeter:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/pewpewlab/jemter-k8s:latest
    steps:
      - uses: actions/checkout@v4
      - name: Run JMeter
        run: /opt/run-jmeter.sh /github/workspace/tests/test.jmx
        env:
          RESULTS_FILE: /github/workspace/results/results.csv
          LOG_FILE: /github/workspace/results/jmeter.log
          GENERATE_HTML_REPORT: "true"
          HTML_REPORT_DIR: /github/workspace/results/html-report
      - name: Upload load test artifacts
        uses: actions/upload-artifact@v4
        with:
          name: jmeter-results
          path: |
            results/results.csv
            results/jmeter.log
            results/html-report/
```

## Use in GitLab CI (CSV + HTML artifacts)

```yaml
load_test:
  image: ghcr.io/pewpewlab/jemter-k8s:latest
  stage: test
  script:
    - /opt/run-jmeter.sh tests/test.jmx
  variables:
    RESULTS_FILE: "$CI_PROJECT_DIR/results/results.csv"
    LOG_FILE: "$CI_PROJECT_DIR/results/jmeter.log"
    GENERATE_HTML_REPORT: "true"
    HTML_REPORT_DIR: "$CI_PROJECT_DIR/results/html-report"
  artifacts:
    when: always
    paths:
      - results/results.csv
      - results/jmeter.log
      - results/html-report/
```
