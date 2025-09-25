@echo off
dotnet build .
odin build . -vet
gateway.exe
