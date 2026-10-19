-- ==========================================================
-- SCRIPT DE BASE DE DATOS: KARTA APP
-- ==========================================================

-- ==========================================================
-- 1. TABLAS DE CATÁLOGOS (PRE-CONFIGURADOS)
-- ==========================================================

CREATE TABLE cuisines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE, -- Ej: 'Mexicana', 'Italiana', 'Sushi'
    icon_url TEXT
) ENGINE=InnoDB;

CREATE TABLE dietary_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE -- Ej: 'Vegano', 'Sin Gluten', 'Vegetariano'
) ENGINE=InnoDB;





-- ==========================================================
-- 2. IDENTIDAD Y USUARIOS
-- ==========================================================

CREATE TABLE users (
    id CHAR(36) PRIMARY KEY, -- Se usará UUID almacenado en formato de texto/char
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) DEFAULT 'explorer' CHECK (role IN ('explorer', 'owner', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;




-- ==========================================================
-- 3. MÓDULO B2B (NEGOCIOS)
-- ==========================================================

CREATE TABLE restaurants (
    id CHAR(36) PRIMARY KEY,
    owner_id CHAR(36),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    phone VARCHAR(20),
    email VARCHAR(150),
    rating DECIMAL(2,1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INT DEFAULT 0,
    -- Estatus B2B
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'pending_review', 'active', 'suspended')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_restaurants_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Ubicación física del restaurante
CREATE TABLE locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id CHAR(36),
    address_line TEXT NOT NULL,
    neighborhood VARCHAR(100),
    zip_code VARCHAR(10),
    city VARCHAR(100),
    state VARCHAR(100),
    -- Coordenadas para el mapa
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    UNIQUE KEY uk_restaurant_location (restaurant_id),
    CONSTRAINT fk_locations_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Horarios de operación
CREATE TABLE business_hours (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id CHAR(36),
    day_of_week INT CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Domingo, 1=Lunes...
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    UNIQUE KEY uk_restaurant_day (restaurant_id, day_of_week),
    CONSTRAINT fk_hours_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB;






-- ==========================================================
-- 4. MÓDULO DE MENÚ (LA CARTA)
-- ==========================================================

-- Categorías del menú (Ej: 'Entradas', 'Platos Fuertes')
CREATE TABLE menu_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id CHAR(36),
    name VARCHAR(100) NOT NULL,
    display_order INT DEFAULT 0,
    CONSTRAINT fk_categories_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Platillos individuales
CREATE TABLE dishes (
    id CHAR(36) PRIMARY KEY,
    category_id INT,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(5) DEFAULT 'MXN',
    image_url TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dishes_category FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB;






-- ==========================================================
-- 5. RELACIONES MUCHOS A MUCHOS (M:N)
-- ==========================================================

-- Relación Restaurante <-> Tipos de Cocina
CREATE TABLE restaurant_cuisines (
    restaurant_id CHAR(36),
    cuisine_id INT,
    PRIMARY KEY (restaurant_id, cuisine_id),
    CONSTRAINT fk_rc_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    CONSTRAINT fk_rc_cuisine FOREIGN KEY (cuisine_id) REFERENCES cuisines(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Relación Platillo <-> Etiquetas Dietéticas (Ej: Tacos de Setas es 'Vegano')
CREATE TABLE dish_dietary_tags (
    dish_id CHAR(36),
    tag_id INT,
    PRIMARY KEY (dish_id, tag_id),
    CONSTRAINT fk_ddt_dish FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE,
    CONSTRAINT fk_ddt_tag FOREIGN KEY (tag_id) REFERENCES dietary_tags(id) ON DELETE CASCADE
) ENGINE=InnoDB;







-- ==========================================================
-- 6. INTERACCIÓN Y ANALÍTICAS (B2C & B2B)
-- ==========================================================

-- Favoritos del usuario (Lugares)
CREATE TABLE user_favorites_places (
    user_id CHAR(36),
    restaurant_id CHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, restaurant_id),
    CONSTRAINT fk_ufp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ufp_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Favoritos del usuario (Platillos específicos)
CREATE TABLE user_favorites_dishes (
    user_id CHAR(36),
    dish_id CHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, dish_id),
    CONSTRAINT fk_ufd_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ufd_dish FOREIGN KEY (dish_id) REFERENCES dishes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Analíticas para el dueño del negocio
CREATE TABLE analytics_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id CHAR(36),
    user_id CHAR(36), -- Null si es invitado
    event_type VARCHAR(50) NOT NULL, -- 'view_menu', 'click_navigation', 'save'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_analytics_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    CONSTRAINT fk_analytics_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;






-- ==========================================================
-- 7. DATOS SEED (CATÁLOGOS INICIALES)
-- ==========================================================

INSERT INTO cuisines (name) VALUES 
('Tacos'), ('Hamburguesas'), ('Italiana'), ('Japonesa/Sushi'), 
('Mexicana'), ('Vegana'), ('Mariscos'), ('Cafetería');

INSERT INTO dietary_tags (name) VALUES 
('Vegetariano'), ('Vegano'), ('Sin Gluten'), ('Halal'), ('Keto');