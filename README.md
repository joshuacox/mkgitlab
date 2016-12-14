# mkgitlab

## Requirements

pwgen

## Usage

For a bunch of defaults set for you:

```
make example
```

Or you can skip that step and you will be prompted, there are values you will be prompted in the next step regardless:

```
make temp
```

After the temporary finishes ( you can watch with `make templogs` ) you can prepare for production with:

```
make next
```

aftr that you will have running gitlab, after which you can restart anytime with:


```
make run
```
