package oapi

//go:generate oapi-codegen -package main -o ./resources_gen.go -generate types,client,chi-server -package oapi resources.yaml
