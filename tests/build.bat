@echo off
dotnet build .
odin test . -vet
