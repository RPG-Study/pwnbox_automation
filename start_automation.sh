#!/bin/bash

# Run cleanup first (REQUIRED - fails if missing)
echo "🧹 Running cleanup.sh..."
if [[ -f "cleanup.sh" ]]; then
  if bash cleanup.sh; then
    echo "✅ cleanup.sh OK"
  else
    echo "❌ cleanup.sh FAILED"
    exit 1
  fi
else
  echo "❌ cleanup.sh NOT FOUND - REQUIRED"
  exit 1
fi

count=0
for script in *.sh; do
  [[ "$script" == "start_automation.sh" || "$script" == "cleanup.sh" ]] && continue
  if [[ -f "$script" && -x "$script" ]]; then
    ((count++))
    echo "$count: $script"
    if bash "$script"; then
      echo "✅ $script OK"
    else
      echo "❌ $script FAILED"
      exit 1
    fi
  fi
done

echo "🎉 All done!"
exec bash -l
