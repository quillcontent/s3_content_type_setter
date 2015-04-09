# S3 Content Types Setter

Script / program that runs through all the files present in your S3 bucket and for every file:

- Gets the content type from the file extension
- Updates S3 metadata to match that

---

It uses the simple `S3` and `Mime-Type` ruby gems.

### Configure

Install `s3cmd` and configure it (`s3cmd --configure`)

osx:   `brew install s3cmd`
linux: `apt-get install s3cmd`

(this is not really needed, you just need standard formatted `.s3cfg` file)


### Install

```sh
gem i bundler
bundle
```

### Running it

```sh
ruby s3_assets.rb
```

yay, content types!
