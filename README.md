# Notes Club
This repository (React + Ruby on Rails) is no longer maintained. It has been replaced by a new application (Elixir + Phoenix).

https://notes.club

## Background
Writing is thinking. Note-taking fosters writing. In the open.

The solution to most world problems are out there in peaces. Let's put them together one note at a time.

## License
[MIT license](LICENSE)

## Overview
This project consists of a frontend in React (/front) and a Ruby on Rails API.

## Backend (Ruby on Rails API)

### Database

You'll need a PostreSQL database to run the application.

There is a `docker-compose-yml` file which will start a PostreSQL and a pgAdmin servers. You will need `docker` and `docker-compose` installed in your system. Then, run the following and you should have a postgresql server available for the project:
```
docker-compose up
```

You can acess pgadmin with your browser at http://localhost:8080 (User is "devuser", password "devuser". It will ask a password when connecting to a database, just leave it blank and press enter) You can also access the database server using the command-line client: `psql "user=devuser password=devuser host=localhost port=5433 dbname=notes_dev"`

The servers can be run separately with `docker-compose up database -d` for the database and `docker-compose up pgadmin -d` for pgAdmin.

To completely remove the containers and volumes (note that this will destroy all data): `docker-compose down -v`

### Create and populate database with seed data
```
cp config/database.yml.example config/database.yml
rails db:setup
```

This demo user will have been created:
```
email: marie@curie.com
password: mariecurie
```

### Configure env variables
In development and test environments variables are read from `./.env` file. You should copy the provided `./.env.example` file to `.env`  before running the project. This will affect front and backend environment variables.

Alternatively, you can add environment variables to your bash_profile:
```
# open ~/.bash_profile
export REACT_APP_NOTESCLUB_API_BASE_URL=http://localhost:3000
export REACT_APP_NOTESCLUB_FRONT_BASE_URL=http://localhost:3001
```

Then, run `source ~/.bash_profile` or open a new console to apply the changes.

### Start server
```
bundle install
rails s
```

### Open browser

Open `http://localhost:3000/v1/ping` on your browser and the API will return `pong`.

### Tests

```
bundle exec rspec
```

You can also user [Guard](https://github.com/guard/guard) to watch changes and run tests on modified files:
```
bundle exec guard
```

### API documentation

The application uses rspec-swagger to tests and document the API endpoint using OpenAPI specification. API tests are under `spec/requests/api` folder. Not all API endpoints are documented at the moment, it's a work in progress.

Schema definitions are under `spec/schemas`. All schemas under that directory are included automatically to API's specification. 

To generate API documentation from tests, run `rake rswag:specs:swaggerize`. This must be done when API tests are modified to keep the documentation updated. It will generate the documentation under docs/API/\[VERSION] directory.

## Frontend (React)

### Start server
```
cd front
yarn install --check-files
yarn start
```

### Open browser

Open `http://localhost:3001` and you will see the log in page.

You should be able to log in with the demo credentials from the backend' step [Create and populate database with seed data](https://github.com/notesclub/notesclub#create-and-populate-database-with-seed-data).

### Tests
Jest:
```
cd front
yarn test
```

Integration (Cypress):
```
cd front
./node_modules/.bin/cypress open
```
