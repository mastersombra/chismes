#!/bin/bash

# Script para arreglar tests agregando emailVerified: true a constructores de User/UserModel

echo "Arreglando tests..."

# Lista de archivos a arreglar
files=(
  "test/core/services/auth_service_test.dart"
  "test/features/auth/data/models/user_model_test.dart"
  "test/features/auth/data/repositories/auth_repository_impl_test.dart"
  "test/features/auth/domain/usecases/sign_up_with_email_test.dart"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "Procesando $file..."

    # Remover duplicados de emailVerified si existen
    sed -i '' '/emailVerified: true,/{
      N
      s/emailVerified: true,\n[[:space:]]*emailVerified: true,/emailVerified: true,/
    }' "$file"

  fi
done

echo "✅ Tests arreglados"
