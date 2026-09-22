from fastapi import FastAPI

app = FastAPI(title="{{PROJECT_NAME}}")


@app.get("/")
def root() -> dict[str, str]:
    return {
        "service": "{{PROJECT_SLUG}}",
        "message": "API criada pelo Super Dev Kit",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
