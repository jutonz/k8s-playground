Sample [Kubernetes](kubernetes.io) deployment of a [Rails](http://rubyonrails.org/) app.

### Getting started

#### 1. Install Docker
The development environment uses [Docker](https://www.docker.com/what-docker). This allows entire devleopment environments to be prebuilt and uploaded to the cloud. All you have to do is download the prebuilt images to your local machine and run them. Not bad, right?

First, install Docker by following the instructions for [Mac](https://store.docker.com/editions/community/docker-ce-desktop-mac), [Linux](https://docs.docker.com/engine/installation/linux/ubuntu/#install-using-the-repository), or [Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows).

You'll also need Docker Compose, which is a convenient way to manage the several Docker containers required to run the app. We're using it here instead of [Foreman](https://github.com/ddollar/foreman), which you may be familiar with if you've done this Rails thing before. Mac and Windows users get Compose automatically with the Docker desktop kits, but Linux users will have to install it separately by running the following commands:

```bash
# Again, this is only necessary for Linux users
$ curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose

# This should return 1.13.0
$ docker-compose --version
```

#### 2. Install the CLI
There is a [Thor](http://whatisthor.com/)-based CLI which wraps most relevant Docker commands so you don't have to remember all the flags and switches. Since it runs on your local machine, you'll have to install Ruby and a few gems locally to use it:

```bash
$ gem install bundler
$ bundle install --gemfile Gemfile.cli
```

#### 3. Pull images and setup the database

Download the prebuilt images to your local machine:

```bash
thor docker:pull
```

To allow database content to be persisted when the database image is destroyed, it must be saved on your local machine. Run this command to setup the database directories locally (this is a one-time thing--you won't have to do this again on your current machine).

```bash
thor docker:initdb
```

If you're curious how this works, the [database persistence](#database-persistence) section has a more detailed rundown of what's happening here.

#### 4. Finally, start the app
Almost there! Just run this command and you're up and running

```bash
thor docker:up
```

You should be able to visit [localhost:3000](localhost:3000) and see the Rails welcome page.

### Container management
Running a Docker-based development environment is a little bit different than running everything locally or using a platform like Vagrant. This section details some of the more notable differences.

#### Each service runs in a separate universe
The individual services that comprise your development environment run in separate containers. This means that, as far as they are aware, they are the only running process on their respective machines (indeed Docker gives them a PID of 1).

For your Rails image to connect to your Postgres image, then, it's not (quite) as simple as making a connection to `localhost:5432`. Instead it must connect to the IP of your Postgres image, which must in turn be configured to accept incomming requests on the correct port. Thankfully, Docker Compose has a DNS feature which makes this pretty nice: Since we've decided to call our Postgres image `psql`, your Rails app can make connections to `psql:5432`, and Compose will automatically resolve `psql` to the correct IP (usually something like `172.18.0.2`) and everything will work how you would expect.

#### <a name="database-persistence"></a>Database persistence is not automatic
Containers are inhernetly transient, meaning that data does not automatically persist across multiple runs of the same container. For anything to exist outside of the regular container lifecycle, it must be persisted to the host machine running Docker (e.g. your computer) via [volumes](https://docs.docker.com/engine/tutorials/dockervolumes/). A volume basically ferries data between your local machine and the OS running in a container such that modifications made on one are reflected in the other.

Data added to your Postgres image is persisted in this way. Essentially, the Postgres processes responsible for doing things like responding to API calls, etc, runs in the `psql` image, but any data committed to your database lives in `docker/tmp/psql` on your local machine. This way you can shut down your `psql` image and still have the data accessible next time you bring it up.


### How To's
Things work slightly differently when your development environment is container-based. Here is a collection of things that might work silghtly differently for you if you're coming from a different dev setup.


#### How to update gem dependencies
The `dev-ruby` container comes pre-packaged with all the gems currently in use in the `master` branch. To use a different version of a gem locally, you have to run `bundle update` from inside a running `dev-ruby` container.

1. Update `Gemfile` to reflect whatever new or updated gems you want installed.
2. If it's not already running, start your app server:
  ```bash
  $ thor docker:up
  ```
2. In another terminal, connect to the `dev-ruby` container:
  ```bash
  $ thor docker:connect ruby
  ```
3. Run whatever bundle commands you need to, e.g.
  ```bash
  $ bundle install
  ```
4. Go back to the terminal where your app server is running and restart it. You can do this by entering `Control + C` to stop it and then running `thor docker:up` again to bring it back up. Your app is now running with the updated gemset.
