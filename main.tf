provider "aws" {
region = "var.region" 
AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY }}
AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_KEY }}
  
}
