#!/bin/bash
set -euo pipefail

EXPECTED="SuperSecretToken123"
STUDENT_FILE="/opt/course/5/token"

if [ ! -f "$STUDENT_FILE" ]; then
  echo "❌ File $STUDENT_FILE not found"
  exit 1
fi

# read and strip CR/newline for robust compare
STUDENT_VALUE=$(cat "$STUDENT_FILE" | tr -d '\r\n')

if [ "$STUDENT_VALUE" = "$EXPECTED" ]; then
  echo "✅ Verification passed"
  exit 0
else
  echo "❌ Token in $STUDENT_FILE is incorrect"
  echo "Expected: $EXPECTED"
  echo "Got: $STUDENT_VALUE"
  exit 1
fi
