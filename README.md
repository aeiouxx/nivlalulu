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
