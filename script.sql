-- Drop tables in reverse order of creation to handle dependencies
DROP TABLE IF EXISTS public.seller_offer;
DROP TABLE IF EXISTS public.book_category;
DROP TABLE IF EXISTS public.book_author;
DROP TABLE IF EXISTS public.book_image;
DROP TABLE IF EXISTS public.seller_address;
DROP TABLE IF EXISTS public.book;
DROP TABLE IF EXISTS public.seller;
DROP TABLE IF EXISTS public.category;
DROP TABLE IF EXISTS public.author;
DROP TABLE IF EXISTS public.publisher;

-- Create a reusable function to update the 'updated_at' column
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Table: publisher
-- Stores information about book publishers.
CREATE TABLE public.publisher (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    website VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: author
-- Stores information about book authors.
CREATE TABLE public.author (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: category
-- Stores the master list of approved book categories.
CREATE TABLE public.category (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: seller
-- Stores information about the online stores selling books.
CREATE TABLE public.seller (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    website_url VARCHAR(255) NOT NULL,
    logo_url VARCHAR(255),
    credit INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: book
-- The central table containing core information about each unique book.
CREATE TABLE public.book (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn_13 VARCHAR(13) NOT NULL UNIQUE,
    isbn_10 VARCHAR(10),
    description TEXT,
    publication_date DATE,
    page_count INTEGER,
    publisher_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_publisher
        FOREIGN KEY(publisher_id)
        REFERENCES public.publisher(id)
        ON DELETE SET NULL -- If a publisher is deleted, we keep the book but nullify the publisher link
);

-- Table: seller_address
-- Stores physical/mailing addresses for each seller.
CREATE TABLE public.seller_address (
    id BIGSERIAL PRIMARY KEY,
    seller_id BIGINT NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    is_primary_address BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_seller
        FOREIGN KEY(seller_id)
        REFERENCES public.seller(id)
        ON DELETE CASCADE -- If a seller is deleted, their addresses are also deleted
);

-- Table: book_image
-- Stores multiple gallery images for each book.
CREATE TABLE public.book_image (
    id BIGSERIAL PRIMARY KEY,
    book_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255),
    is_primary_cover BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_book
        FOREIGN KEY(book_id)
        REFERENCES public.book(id)
        ON DELETE CASCADE -- If a book is deleted, its images are also deleted
);

-- Junction Table: book_author
-- Links books to their authors (Many-to-Many).
CREATE TABLE public.book_author (
    book_id BIGINT NOT NULL,
    author_id BIGINT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book
        FOREIGN KEY(book_id)
        REFERENCES public.book(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_author
        FOREIGN KEY(author_id)
        REFERENCES public.author(id)
        ON DELETE CASCADE
);

-- Junction Table: book_category
-- Links books to their categories (Many-to-Many).
CREATE TABLE public.book_category (
    book_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    CONSTRAINT fk_book
        FOREIGN KEY(book_id)
        REFERENCES public.book(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_category
        FOREIGN KEY(category_id)
        REFERENCES public.category(id)
        ON DELETE CASCADE
);

-- Table: seller_offer
-- Core transactional table linking a book to a seller with a specific price offer.
CREATE TABLE public.seller_offer (
    id BIGSERIAL PRIMARY KEY,
    book_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_in_stock BOOLEAN DEFAULT TRUE,
    seller_product_url VARCHAR(2048) NOT NULL,
    last_scraped_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_book
        FOREIGN KEY(book_id)
        REFERENCES public.book(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_seller
        FOREIGN KEY(seller_id)
        REFERENCES public.seller(id)
        ON DELETE CASCADE
);

-- Create triggers to automatically update 'updated_at' columns on row change
CREATE TRIGGER set_publisher_timestamp
BEFORE UPDATE ON public.publisher
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_author_timestamp
BEFORE UPDATE ON public.author
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_category_timestamp
BEFORE UPDATE ON public.category
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_seller_timestamp
BEFORE UPDATE ON public.seller
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_book_timestamp
BEFORE UPDATE ON public.book
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_seller_address_timestamp
BEFORE UPDATE ON public.seller_address
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- Create Indexes for performance optimization
-- Index on foreign keys for faster joins
CREATE INDEX ON public.book (publisher_id);
CREATE INDEX ON public.seller_address (seller_id);
CREATE INDEX ON public.book_image (book_id);
CREATE INDEX ON public.book_author (book_id);
CREATE INDEX ON public.book_author (author_id);
CREATE INDEX ON public.book_category (book_id);
CREATE INDEX ON public.book_category (category_id);
CREATE INDEX ON public.seller_offer (book_id);
CREATE INDEX ON public.seller_offer (seller_id);

-- Index on frequently queried or sorted columns
CREATE INDEX ON public.book (title);
CREATE INDEX ON public.seller (name);
CREATE INDEX ON public.seller_offer (price);
