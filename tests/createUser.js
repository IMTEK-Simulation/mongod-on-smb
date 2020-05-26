use new-db
db.createUser(
    {
        user: "username",
        pwd: "password",
        roles: [ { role: "readWrite", db: "new-db" } ]
    }
)