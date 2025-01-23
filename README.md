# SELF-SIGNED CERTIFICATES ARE A HUGE PAIN IN THE ASS
  This app comes bundled with a self-signed SSL certificate, however because browsers are annoying, the browser won't trust the backend certificate and you will probably get CORS issues when you push requests to the BE.

  Because I really don't want to get a valid signed certificate for this, we mitigate that the following way:

    1. Connect to the backend via the browser: https://localhost:8443
    2. Select trust certificate (accept risk and continue or some other way to confirm, browser dependent)
    3. Your browser will now trust the self-signed BE certificate and calls on the FE will work normally
    
  ![cry](https://github.com/user-attachments/assets/f6a4073b-bf48-4131-801e-cda7b8af3313)

  (We could also bundle mkcert with this app and install a certificate to your OS, but that seems quite intrusive)
## Workflow
1. **Cloning the repository**
    ```bash
    git submodule update --init
    ```
    this will checkout the `backend` and `frontend` repositories at the commit pointed to by the `nivlalulu` superproject.
    *Updating without the --init switch will only update existing repositories but not checkout new ones*
2. **Updating the repository**:
  Once changes get merged into any of the submodule repositories (e.g. `nivlalulu-be`), switch to the superproject and run:
    ```bash
    git pull # (or git fetch + git pull), 
    git submodule update # (optionally with --init switch)
    ```
    `git pull` is necessary otherwise the submodules would check out commits pointed to by the current local `master` state instead of `HEAD` synced with remote.

## Configuration
Before running the application, you may need to adjust environment variables:

- **For Local Development**: The provided `.env` and `liquibase.properties` files have *sane* defaults. 

- **For Production or Other Environments**:  Update values in the `.env` or create the files based on the `.env.template` template with proper credentials, hosts, passwords, and other configuration details. For example:
  - Update `env/db/.env` with production-ready credentials.
  - Update `env/lb/liquibase.properties` with the requisite values.

### Common Environment Variables

- **Database Host/Port/User/Password**: Defined in `env/db/.env`.
- **SPRING_PROFILES_ACTIVE**: In `docker-compose.yml`, the backend service is set to run with the `docker` profile. This can be adjusted as needed in the `backend/.env` or `docker-compose.yml`. Local development should happen via the `dev` profile.

## Running the application
1. **Build and run services**
    ```bash
    docker-compose up --build
    ```

2. **Migration using the liquibase container**: If composed with the `liquibase` profile, the liquibase container should be accessible, if not launch the container in detached mode via:
    ```bash
    docker-compose up lb -d
    ```
- **Enter the liquibase container**:
  ```bash
  docker exec -it lb bash
  ```
- **Do the stuff**:
  ```bash
  liquibase update
  ```
    the container mounts the changelogs defined in the `./backend/src/main/resources/db/changelog/` location.
  

3. **Stopping the application**:

    When you are done you can stop and remove the containers by:
    ```bash
    docker-compose down
    ```
    If the liquibase container is running, it must be killed manually via:
    ```bash
    docker kill lb
    ```

## Issues
1. **Liquibase 'resource already exists' errors:**

    -  If you run the liquibase migrations via the local-dev profile in spring with liquibase:enabled: true, and then try to 
    run the dockerized app with the same db instance (or the other way around), liquibase will not detect the changesets as applied, try to reapply them and fail because
    the db resources already exist.
    - This is because in docker, we use the internal DNS for intercontainer communication so the JDBC url contains the container name,
    whereas in your local environment it probably contains localhost, 
    this means that liquibase doesn't detect the changesets from one as being ran from another.
      ```bash
      LOCAL_URL = jdbc:postgresql://localhost:5432/my_amazing_database
      CONTAINER = jdbc:postgresql://db_container:5432/my_amazing_database

      # liquibase detects these two as different and changesets from one don't apply to the other one, so it tries to rerun them.
      ```
    - Either disable liquibase in spring and run it only via the container:
      ```yml
      # application-dev.yml
      liquibase:
        enabled: false
      ```
      ```yml
      # docker-compose.yml
      lb:
        container_name: lb
        image: liquibase/liquibase
        entrypoint: ["liquibase", "update"]
        depends_on:
          - db
        volumes:
          - ./env/lb/liquibase.properties:/liquibase/liquibase.properties
          - ./backend/src/main/resources/db/changelog:/liquibase/backend_changelog
        networks:
          - nivlalulu-network
      ```
    - Or drop everything before you run the containerized app
      ```bash
      # connect to the liquibase container (must have the old spinlocked entrypoint to keep the container alive)
      docker exec -it lb bash
      liquibase dropAll
      ```

    - *Or we could write idempotent changesets, but shhhh...* 
2. **Docker: env_file.0 must be a string**:
    - Update your `docker compose version` to be `>= 2.24.0`.
3. **Gradle: :compileJava invalid source release 21**
    - If you have an older version of IntelliJ Idea and running the app from idea, it automatically sets the JVM of the Gradle build tool to JVM 17 or less, even if `./gradlew --version` reports a different one.


