# JM x Stacksync assignement

Assignement: https://drive.google.com/file/d/1uaPRGXqNqbCqGKqULqSw2CQ2dcid3T3r/view

Disclaimers:

```
- The assignement example result mentions `stdout`, however the assignement itself mentions to not include it, only the return value should be captured. I excluded it.
```

To run the project you have to build the docker image:

```bash
docker build -t stacksync . --no-cache
```

And then run it:

```bash
docker run -p 8080:8080 stacksync
```

You can test the API with curl:

```bash
curl -X POST "https://jm-stacksync-1043345859573.europe-central2.run.app/execute" \
  -H "Content-Type: application/json" \
  -d '{
    "script": "import pandas as pd\n\ndef main():\n    df = pd.DataFrame({\"a\": [1, 2, 3], \"b\": [4, 5, 6]})\n    return {\"data\": df.to_dict(), \"shape\": list(df.shape)}"
  }'
```

There are some test cases, in `test.sh` that you can run to verify the functionality (use --local flag to run it locally):

```bash
chmod +x test.sh

./test.sh
```

Command used to deploy to GCP Cloud Run:

```
gcloud run deploy jm-stacksync \
  --source . \
  --platform managed \
  --region europe-central2 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --timeout 60s \
  --execution-environment gen2
```

Thank you for the opportunity to work on this assignement!
