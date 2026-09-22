var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    service = "{{PROJECT_SLUG}}",
    message = "API criada pelo Super Dev Kit"
}));

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok"
}));

app.Run();
