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
docker run --rm lcoe-r Rscript tests/test_hook_schema.R
```

## Declared inputs and outputs

[`hook-schema.json`](hook-schema.json) declares the inputs this container reads and the outputs it writes. The publish workflow puts it in the image label `com.airelabs.schema.v1.hook`. When someone picks this image under **Registry image** in Aire's **Configure Code Block** dialog, the dialog reads the declaration. It lists each input with its description, blocks **Save** until every required input is mapped, and sets **Send as** to the declared unit. It also pre-fills the outputs.

The file is the only copy of the declaration. `main.R` reads its expected units from it through `R/hook_schema.R`, and `tests/test_hook_schema.R` checks that the fixtures and the results match it.

Unit names are the ones Aire sends: `yr`, not `years`; `USD/kWyr`, not `USD/kW/yr`. A declared unit Aire cannot produce makes every run fail its unit check.

The publish workflow validates the file against the published [JSON Schema](https://app.airelabs.com/schemas/v1/siro.v1alpha2.HookSchema.jsonschema.strict.bundle.json) before it builds. To check it yourself:

```bash
pipx run check-jsonschema --schemafile https://app.airelabs.com/schemas/v1/siro.v1alpha2.HookSchema.jsonschema.strict.bundle.json hook-schema.json
```

The registry does not fail a push with a bad label. It ignores the label and shows the reason on the **Container Registry** page, next to the tag, and in the **Configure Code Block** dialog. The file cannot carry a `$schema` key, because the registry rejects any key it does not know.

To build locally with the label:

```bash
docker build --label "com.airelabs.schema.v1.hook=$(jq -c . hook-schema.json)" -t lcoe-r .
docker inspect lcoe-r --format '{{ index .Config.Labels "com.airelabs.schema.v1.hook" }}'
```

## Try other inputs

```bash
cp fixtures/hook-input-wind.json /tmp/airelabs/hook-input.json           # wind instead of solar
cp fixtures/hook-input-bad-rate.json /tmp/airelabs/hook-input.json       # invalid discount rate (error result)
cp fixtures/hook-input-unknown-dataset.json /tmp/airelabs/hook-input.json # unknown dataset (hard error)
```

See the [full guide](https://www.airelabs.com/docs/docker-programming-language-r) for a walkthrough of the code and how to write your own function.
