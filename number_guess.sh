#!/bin/bash

# PSQL variable for database queries
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt for username
echo "Enter your username:"
read USERNAME

# Ensure username is less than or equal to 22 characters
if [[ ${#USERNAME} -gt 22 ]]; then
  echo "Error: Username cannot be longer than 22 characters."
  exit 1
fi

# Check if username exists in the database
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

# If user exists
if [[ -n "$USER_INFO" ]]; then
  # Parse user information
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  
  # Greet returning user
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  # If user does not exist, insert them into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  GAMES_PLAYED=0
  BEST_GAME=0
fi

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Output to indicate the game has started
echo "Guess the secret number between 1 and 1000:"

# Initialize guess counter
GUESS_COUNT=0
GUESS=0

# Function to check if input is an integer
is_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

# Loop to take guesses
while [[ $GUESS -ne $SECRET_NUMBER ]]; do
  echo "Enter your guess:"
  read GUESS

  # Increment guess counter
  GUESS_COUNT=$(( GUESS_COUNT + 1 ))

  # Check if input is an integer
  if ! is_integer "$GUESS"; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare the guess with the secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  fi
done

# Congratulate the user
echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

# Update user statistics in the database
GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))

if [[ -z "$BEST_GAME" || $GUESS_COUNT -lt $BEST_GAME || $BEST_GAME -eq 0 ]]; then
  BEST_GAME=$GUESS_COUNT
fi
UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE username='$USERNAME'")


