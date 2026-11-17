import kagglehub

# Download latest version
path = kagglehub.dataset_download("thesohanur/restaurant-and-food-delivery-relational-database")

print("Path to dataset files:", path)