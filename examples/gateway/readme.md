# CoreCLR

to build run the following in this folder:

```bash
dotnet build
```

to see the il code use:

```bash
ildasm gateway.dll /out=gateway.il
```

to re-compile use:

```bash
ilasm gateway.il /dll /output=gateway.dll
```
