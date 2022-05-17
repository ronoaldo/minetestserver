# Sample Minetest Server with Docker

## Quick start

Quick start (assuming you have installed Docker already):

```
cd sample
./quickstart.sh
```

## Suggested server building/hosting workflow

1. Create a local folder, for instance `server`
2. Create a data folder, for instance `server/data` and change the permissions
   with `sudo chown 30000 ./data`
3. Download the `Dockerfile` and `minetest.conf` and save them into `server`
4. Change to the `server` directory in your terminal
5. Build an image with `docker build -t myserver:latest ./`
6. Run the server with `docker run -it --rm -v $PWD/data:/var/lib/minetest -p
   30000:30000/udp -p 30000:30000/tcp myserver:latest`
7. If you make changes to Dockerfile or minetest.conf, stop the container with
   `CTRL+C` and run the steps 5 and 6 again

## Changing server config

Edit `minetest.conf` adding/changing the configuration values as desired.
After that, run the steps 5 and 6 from the quick start reference.

## Adding mods from ContentDB

To add new mods, edit `Dockerfile` and add more mods from ContentDB in the RUN
statement, like this:

```
RUN contentdb install TenPlus1/ethereal
```

Then run the steps 5 and 6 again from the quick start reference. After you
add the mod to the image, you also need to edit `./data/world/world.mt` to
load it, changing the `load_mod_... = false` to `load_mod_... = true`.
