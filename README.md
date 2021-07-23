# reprepro
```sh
docker run --rm -v $(pwd)/data:/data -e "PASS=pass" aktin-reprepro:latest
```

## Install repository
```sh
echo "deb https://aktin.org/software/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/aktin.list
wget -O- https://aktin.org/software/ubuntu/aktin.gpg | sudo apt-key add -
```

