package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"google.golang.org/genai"
)

func checkArgs() {
	if len(os.Args) <= 1 {
		log.Fatal("You did not provide a question to ask")
	}
}

func listModels() {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, nil)
	if err != nil {
		log.Fatal(err)
	}

	for item, err := range client.Models.All(ctx) {
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(item.Name)
	}
}

func main() {
	checkArgs()
	if os.Args[1] == "list" {
		listModels()
		return
	}
	question := os.Args[1]
	fmt.Printf("Asking Gemini: %s\n", question)
	ctx := context.Background()
	client, err := genai.NewClient(ctx, nil)
	if err != nil {
		log.Fatal(err)
	}

	result, err := client.Models.GenerateContent(
		ctx,
		"gemini-2.5-flash",
		genai.Text(question),
		nil,
	)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(result.Text())
}
