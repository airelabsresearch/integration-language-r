# Aire Labs Container Function — R Example

Computes LCOE (Levelized Cost of Energy) from bundled solar and wind cost data. A working example you can build and run locally with Docker.

**Full guide:** [Container Functions with R](https://www.airelabs.com/docs/docker-programming-language-r)

## Quick start

Requires [Docker](https://orbstack.dev/download) (or [Docker Desktop](https://docs.docker.com/desktop/)). Commands below assume macOS or Linux.

```bash
docker build -t lcoe-r .

mkdir -p /tmp/airelabs
cp fixtures/hook-input.json /tmp/airelabs/hook-input.json

docker run --rm \
  -v /tmp/airelabs:/airelabs \
  -e AIRELABS_HOOK_INPUT_PATH=/airelabs/hook-input.json \
  -e AIRELABS_HOOK_OUTPUT_PATH=/airelabs/hook-output.json \
  lcoe-r
```

You should see: `OK — dataset=solar, year=2027, lcoe=43.39 USD/MWh`

Inspect the output: `cat /tmp/airelabs/hook-output.json`

## Run tests

```bash
docker run --rm lcoe-r Rscript tests/test_model.R
docker run --rm lcoe-r Rscript tests/test_main.R
```

## Try other inputs

```bash
cp fixtures/hook-input-wind.json /tmp/airelabs/hook-input.json           # wind instead of solar
cp fixtures/hook-input-bad-rate.json /tmp/airelabs/hook-input.json       # invalid discount rate (error result)
cp fixtures/hook-input-unknown-dataset.json /tmp/airelabs/hook-input.json # unknown dataset (hard error)
```

See the [full guide](https://www.airelabs.com/docs/docker-programming-language-r) for a walkthrough of the code and how to write your own function.
