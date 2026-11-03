package main

import (
	"fmt"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	fmt.Fprintf(w, "You are on HOST: %s\n Powered by:Uday Shiwakoti", hostname)
}

func main() {
	// Register the handler function to handle requests on port 80
	http.HandleFunc("/", handler)

	// Start the server on port 80
	fmt.Println("Server listening on port 80...")
	http.ListenAndServe(":80", nil)
}
