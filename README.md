# JavaLearning

Hands-on Java study workspace with runnable examples, modeled after [Java-Project](https://github.com/chaitussm/Java-Project).

## Prerequisites

- JDK 17+ (JDK 21 recommended)
- Apache Maven 3.8+

## Build

```bash
cd demo
mvn -B clean compile
```

## Run a program

Each class with a `main` method can be run after compiling:

```bash
cd demo
mvn -B compile
mvn -q exec:java -Dexec.mainClass="com.imports.PrintStatementInjava"
```

Or with `java` directly:

```bash
cd demo
mvn -B compile
java -cp target/classes com.imports.PrintStatementInjava
```

Browse sources under `demo/src/main/java/` (packages such as `com.imports`, `com.exceptionHandling`, collections, serialization, and more).

## Daily CI pipeline

GitHub Actions workflow [`.github/workflows/java-end-to-end-ci.yml`](.github/workflows/java-end-to-end-ci.yml) runs **every day at 18:30 UTC** (and on pushes/PRs to `master`). It compiles the demo module, runs every class with a `main` method, and uploads a styled HTML execution report as the `java-execution-report-*` artifact.

Trigger manually from the **Actions** tab → **Java Daily Execution CI** → **Run workflow**.
