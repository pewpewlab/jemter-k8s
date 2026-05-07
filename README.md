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
- `RESULTS_FILE` (default: `/results/results.jtl`)
- `LOG_FILE` (default: `/results/jmeter.log`)

## Build image

```bash
docker build -t jemter-k8s:latest .
```

## Run with Docker

```bash
docker run --rm \
  -v "$(pwd)/your-test-plan.jmx:/tests/your-test-plan.jmx:ro" \
  -v "$(pwd)/results:/results" \
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
