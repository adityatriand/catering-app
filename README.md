# Catering App

A web-based catering management application designed to help restaurant owners manage their menu items, track orders, and monitor inventory efficiently. The application provides a clean, modern interface that makes it easy to handle daily catering operations.



## Overview

This application streamlines the catering business workflow by digitizing menu management and order processing. It provides a centralized system for managing food and beverage menus, tracking customer orders, monitoring inventory levels, and generating daily reports.

The application follows a business process where customers place orders through WhatsApp, owners record and manage those orders in the system, and the application automatically handles inventory tracking and order status management.

## Business Workflow

The application is designed around the following business process:

1. Menu items and prices are announced to customers via WhatsApp
2. Customers place orders and make payments through bank transfer
3. Restaurant owners record customer orders in the application
4. Orders that remain unpaid by 5:00 PM are automatically canceled
5. After 5:00 PM, owners view the list of paid orders and prepare the meals

This workflow ensures efficient order management while preventing issues with unpaid orders by implementing automatic cancellation based on payment deadlines.

## Features

### Menu Item Management

The Items module allows you to view all available menu items, add new items, update existing item information, and remove items that are no longer available.

Key features include:
- Display all menu items with their details
- Add new menu items with name, description, price, and categories
- Edit existing menu item information
- Delete menu items that are no longer available
- Stock level tracking for each item
- Category assignment for better organization

When adding or editing items, you can also create new categories on the fly, making it easy to organize your menu as your offerings grow.

The detail view provides a comprehensive look at each menu item, including all assigned categories and current stock levels.

### Order Management

The Orders module provides comprehensive order tracking and management capabilities. You can view all orders, create new orders, modify existing orders, and delete orders when necessary.

The order listing supports multiple filtering options:
- View all orders
- Filter orders by current day
- Filter orders by customer email
- Filter orders by total price (with comparison operators)
- Filter orders by date range

When creating a new order, you can select multiple menu items and specify quantities for each. The system validates stock availability in real-time to ensure orders can be fulfilled.

Orders can be updated as long as they haven't been canceled. The system automatically prevents modification of canceled orders.

### Stock Management

The application includes automatic stock management that tracks inventory levels:
- Stock decreases when orders are created or confirmed as paid
- Stock increases when orders are canceled or items are removed from orders
- Real-time stock validation prevents orders that exceed available inventory
- Visual indicators show stock levels and out-of-stock items

### Order Status Management

Orders have three possible statuses:
- **NEW**: Order has been created but not yet paid
- **PAID**: Customer has confirmed payment
- **CANCELED**: Order was not paid by the deadline or was manually canceled

The system automatically updates order statuses at 5:00 PM, canceling any unpaid orders. Once an order is canceled, it cannot be modified further.

## Technology Stack

This application is built with:

- **Ruby 3.1.1**
- **Rails 7.0.2**
- **SQLite3** (database)
- **Bootstrap 5** (frontend framework)
- **Puma** (web server)
- **Turbo Rails** (for SPA-like navigation)
- **RSpec** (testing framework)
- **FactoryBot** (test data generation)

## Database Schema

### Items Table

Stores menu item information:
- `id`: Primary key (integer, auto increment)
- `name`: Item name (string, unique)
- `description`: Item description (string, max 150 characters)
- `price`: Item price (float, minimum 0.01)
- `stock`: Available quantity (integer, minimum 0)
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Categories Table

Stores menu categories:
- `id`: Primary key (integer, auto increment)
- `name`: Category name (string)
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Item Categories Table

Junction table linking items to categories (many-to-many relationship):
- `id`: Primary key (integer, auto increment)
- `item_id`: Foreign key to items
- `category_id`: Foreign key to categories
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Orders Table

Stores customer order information:
- `id`: Primary key (integer, auto increment)
- `email`: Customer email address (string, validated format)
- `status_order`: Order status enum (NEW, PAID, CANCELED)
- `total_price`: Total order price (float)
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Order Details Table

Stores individual items within each order:
- `id`: Primary key (integer, auto increment)
- `order_id`: Foreign key to orders
- `item_id`: Foreign key to items
- `price`: Item price at time of order (float)
- `quantity`: Quantity ordered (integer)
- `created_at`: Timestamp
- `updated_at`: Timestamp

## Getting Started

### Prerequisites

Before running this application, ensure you have the following installed:
- Ruby 3.1.1 or compatible version
- RubyGems
- Bundler gem
- SQLite3

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd catering-gigih-app
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
rails db:create
rails db:migrate
rails db:seed  # Optional: Load sample data
```

4. Start the Rails server:
```bash
rails server
```

5. Open your browser and navigate to:
```
http://localhost:3000
```

## Running with Docker

The application can be run using Docker and Docker Compose, which simplifies setup and ensures consistent environments across different systems.

### Prerequisites for Docker

Before running with Docker, ensure you have the following installed:
- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)

You can verify your installation by running:
```bash
docker --version
docker-compose --version
```

### Development Setup with Docker

1. Clone the repository (if you haven't already):
```bash
git clone <repository-url>
cd catering-gigih-app
```

2. Build and start the application using Docker Compose:
```bash
docker-compose up --build
```

This command will:
- Build the Docker image
- Create and migrate the database
- Seed the database with sample data
- Start the Rails server

3. The application will be available at:
```
http://localhost:3000
```

The development setup uses volume mounts, so any code changes you make will be reflected immediately without rebuilding the container.

### Production Setup with Docker

For production deployment, use the production Docker Compose file:

1. Generate and set the `SECRET_KEY_BASE` environment variable. You can generate it using:
```bash
# If you have Rails installed locally:
export SECRET_KEY_BASE=$(rails secret)

# Or generate a random secret key:
export SECRET_KEY_BASE=$(openssl rand -hex 64)
```

2. Start the production environment:
```bash
docker-compose -f docker-compose.prod.yml up --build
```

The production setup:
- Runs in production mode
- Does not mount source code volumes (uses the image)
- Automatically restarts if the container stops
- Requires a `SECRET_KEY_BASE` environment variable

### Docker Commands

Here are some useful Docker commands for managing the application:

**Start the application (in background):**
```bash
docker-compose up -d
```

**Stop the application:**
```bash
docker-compose down
```

**Stop and remove volumes (this will delete the database):**
```bash
docker-compose down -v
```

**View logs:**
```bash
docker-compose logs -f
```

**Execute Rails console:**
```bash
docker-compose exec web rails console
```

**Run database migrations:**
```bash
docker-compose exec web rails db:migrate
```

**Run database seed:**
```bash
docker-compose exec web rails db:seed
```

**Run all tests:**
```bash
docker-compose exec web bundle exec rspec
```

**Run specific test file:**
```bash
docker-compose exec web bundle exec rspec spec/models/item_spec.rb
```

**Run specific test context:**
```bash
docker-compose exec web bundle exec rspec spec/models/item_spec.rb:12
```

**Run tests with documentation format:**
```bash
docker-compose exec web bundle exec rspec --format documentation
```

**Run tests for a specific model or controller:**
```bash
docker-compose exec web bundle exec rspec spec/models/
docker-compose exec web bundle exec rspec spec/controllers/
```

**Set up test database (first time only):**
```bash
docker-compose exec web bundle exec rails db:test:prepare
```

**Run tests in watch mode (if guard is installed):**
```bash
docker-compose exec web bundle exec guard
```

**Access the container shell:**
```bash
docker-compose exec web bash
```

**Run tests from within container shell:**
Once inside the container, you can run tests normally:
```bash
bundle exec rspec
```

### Docker Configuration Details

The Docker setup includes:
- **Dockerfile**: Defines the application image with Ruby 3.1.1, system dependencies, and Rails configuration
- **docker-compose.yml**: Development configuration with volume mounts for live code editing
- **docker-compose.prod.yml**: Production configuration optimized for deployment

The database data is persisted in Docker volumes, so your data remains intact between container restarts. In development mode, your source code is mounted as a volume, allowing for hot-reloading during development.

### Running Tests

The application uses RSpec for testing. To run the test suite:

**Without Docker:**

First, make sure your test database is set up:
```bash
rails db:test:prepare
```

Then run the tests:
```bash
bundle exec rspec
```

**With Docker:**

The easiest way is to run tests in an already running container:
```bash
# Make sure containers are running first
docker-compose up -d

# Then run tests
docker-compose exec web bundle exec rspec
```

**Running tests without starting the server:**

If you only want to run tests without starting the Rails server, you can use:
```bash
# This command will start the container, set up the database, run tests, and stop
docker-compose run --rm web bundle exec rspec
```

The `--rm` flag ensures the container is removed after the command completes.

**First-time test setup with Docker:**

If this is your first time running tests, you may need to prepare the test database:
```bash
docker-compose exec web bundle exec rails db:test:prepare
```

Or if containers aren't running:
```bash
docker-compose run --rm web bundle exec rails db:test:prepare
```

**Running specific tests:**

You can run specific test files or contexts:
```bash
# Run a specific file
docker-compose exec web bundle exec rspec spec/models/item_spec.rb

# Run tests matching a pattern
docker-compose exec web bundle exec rspec spec/models/

# Run a specific line
docker-compose exec web bundle exec rspec spec/models/item_spec.rb:104
```

**Test output formats:**

For more readable output:
```bash
docker-compose exec web bundle exec rspec --format documentation
```

For CI/automated environments:
```bash
docker-compose exec web bundle exec rspec --format progress
```

## Usage

### Creating Menu Items

1. Navigate to the Items section from the main menu
2. Click "New Item" to add a new menu item
3. Fill in the item details: name, description, price, and stock quantity
4. Select or create categories for the item
5. Save the item

Note: Item names must be unique, and prices must be at least 0.01.

### Managing Orders

1. Navigate to the Orders section
2. Click "New Order" to create an order
3. Enter the customer's email address
4. Select menu items and specify quantities
5. The system will validate stock availability automatically
6. Save the order (status will be set to NEW)

### Updating Orders

1. Find the order you want to update from the orders list
2. Click "Edit" to modify the order
3. Update items or quantities as needed
4. Change the order status to PAID when payment is confirmed
5. Orders automatically change to CANCELED if not paid by 5:00 PM

### Filtering Orders

Use the filter options in the Orders section to:
- View all orders or orders from today
- Filter by customer email
- Filter by total price with comparison operators
- Filter by date range

## Application Behavior

### Item Management Rules

- Each item name must be unique across the system
- Prices must be positive values (minimum 0.01)
- Descriptions are limited to 150 characters
- Stock levels cannot be negative
- Items can belong to multiple categories

### Order Management Rules

- Customer email addresses must be in valid format
- Orders start with status NEW
- Stock is reserved when an order is created
- Orders automatically cancel at 5:00 PM if unpaid
- Canceled orders cannot be modified
- Stock is automatically restored when orders are canceled or items are removed

### Stock Management Rules

- Stock decreases when orders are created or confirmed as paid
- Stock increases when orders are canceled
- Orders cannot be created if insufficient stock is available
- Real-time validation prevents over-ordering

## Project Structure

The application follows standard Rails conventions:

- `app/controllers/` - Application controllers
- `app/models/` - ActiveRecord models
- `app/views/` - ERB templates
- `app/assets/stylesheets/` - CSS stylesheets
- `config/` - Configuration files
- `db/migrate/` - Database migrations
- `spec/` - Test files
- `config/routes.rb` - Application routes

## Development

This application uses Rails 7 with Hotwire for modern, responsive interactions. The frontend is styled with Bootstrap 5 and custom CSS for a polished, professional appearance.

For development, make sure you have the required gems installed and the database properly configured. The application uses SQLite3 by default, which is suitable for development and small-scale deployments.

## License

This project is part of a learning exercise and is provided as-is for educational purposes.

## Support

For questions or issues, please refer to the demo video or contact the development team.
