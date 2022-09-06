# onboard-binary

Onboard your atSigns easily with the onboard-binary. Just download the binary (via releases) and run it on your machine. Or, if you cloned the repository, just run the main.dart via `dart run bin/main.dart <args>`.

```
./onboard --atsign "@smoothalligator" --email "jeremy.tubongbanua@atsign.com" -v
```

## Usage

| Option | Mandatory | Description | Example |
|--------|-----------|-------------|----|
| --atsign -a | true | atSign to generate .atKeys | "@alice" |
| --email -e | true | Email address that owns the atSign | "email@gmail.com" |
| --root -r | false | Root host to onboard the atSign | "root.atsign.org" |
| --port -p | false | Port of the root host | 64 |

| Flag | Defaults To | Description |
|------|-------------|-------------|
| --verbose -v | false | Verbose logging |