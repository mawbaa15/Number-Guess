#!/bin/bash

# PSQL variable for executing queries
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Random number between 1 and 1000
RANDOM_NUMBER=$(( RANDOM % 1000 + 1 ))
# Example: Add a comment in your script
# This is a bash script for number guessing game
# COMMNENT + NOTHING
# Or change something trivial
# Prompt user for their username
echo "Enter your username:"
read USERNAME

# Check if username length is valid (up to 22 characters)
USERNAME=${USERNAME:0:22}

# Query the database for the user info
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

# If user does not exist, create a new record
if [[ -z $USER_INFO ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Retrieve existing user data
  echo "$USER_INFO" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Game logic
echo "Guess the secret number between 1 and 1000:"

GUESS_COUNT=0
while true
do
  read GUESS
  ((GUESS_COUNT++))

  # Check if the guess is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Check if the guess is correct, too low, or too high
  if [[ $GUESS -lt $RANDOM_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $RANDOM_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!"
    break
  fi
done

# Update user statistics after the game
if [[ -z $USER_INFO ]]
then
  # First-time user: update games_played and best_game
  UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played = 1, best_game = $GUESS_COUNT WHERE username='$USERNAME'")
else
  # Existing user: increment games_played and update best_game if necessary
  echo "$USER_INFO" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME
  do
    NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
    if [[ -z $BEST_GAME || $GUESS_COUNT -lt $BEST_GAME ]]
    then
      UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $GUESS_COUNT WHERE username='$USERNAME'")
    else
      UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE username='$USERNAME'")
    fi
  done
fi
