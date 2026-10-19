from durus.connection import Connection
from durus.file_storage import FileStorage
from durus.persistent_list import PersistentList
from models import Dish, SpecialDish, Restaurant

def main() -> None:
    # 1. Inicializar almacenamiento local y conexión de Durus
    storage = FileStorage('karta_db.durus')
    connection = Connection(storage)
    root = connection.get_root()

    try:
        # Inicializar la raíz usando sintaxis de diccionario (Persistencia por alcanzabilidad)
        if 'restaurants' not in root:
            root['restaurants'] = PersistentList()

        # --- CRUD: ALTA (CREATE) ---
        print("=== 1. CRUD: ALTA (CREATE) ===")
        restaurant = next((r for r in root['restaurants'] if r.name == "Karta Bistro"), None)

        if restaurant is None:
            restaurant = Restaurant("Karta Bistro", "Cocina fusión mexicana", "555-1234-5678")
            taco = Dish("Tacos al Pastor", "Orden de 4 tacos tradicionales", 95.00)
            special_taco = SpecialDish("Tacos Especiales de la Casa", "Con queso costra", 120.00, discount_percentage=10)

            restaurant.add_dish(taco)
            restaurant.add_dish(special_taco)

            root['restaurants'].append(restaurant)
            connection.commit()  # Confirmación de transacción
            print("[OK] Restaurante y platillos creados y guardados con commit().")
        else:
            print("[INFO] El restaurante 'Karta Bistro' ya existe en la base de datos (se reutiliza).")

        # --- CRUD: CONSULTA Y NAVEGACIÓN DEL GRAFO (READ) ---
        print("\n=== 2. CRUD: CONSULTA Y POLIMORFISMO (READ) ===")
        for rest in root['restaurants']:
            print(f"Restaurante: {rest.name}")
            for d in rest.dishes:
                print(f" -> Platillo: {d.name} | Precio final: ${d.price:.2f}")

        # --- CRUD: ACTUALIZACIÓN (UPDATE) ---
        print("\n=== 3. CRUD: ACTUALIZACIÓN (UPDATE) ===")
        taco_to_update = next((d for d in restaurant.dishes if d.name == "Tacos al Pastor"), None)
        if taco_to_update:
            nuevo_precio = 105.00
            print(f"Actualizando precio de '{taco_to_update.name}': ${taco_to_update.price:.2f} -> ${nuevo_precio:.2f}")
            taco_to_update.price = nuevo_precio
            connection.commit()
            print("[OK] Cambio de precio guardado exitosamente con commit().")

        # --- PRUEBA DE TRANSACCIONES: REVERSIÓN (ABORT) ---
        print("\n=== 4. CONTROL DE TRANSACCIONES: ABORT ===")
        total_antes = len(root['restaurants'])
        temp_restaurant = Restaurant("Negocio Temporal a Borrar", "Prueba de fallo", "000-0000")
        root['restaurants'].append(temp_restaurant)
        print(f"Restaurantes tras append en memoria: {len(root['restaurants'])}")

        # Revertimos los cambios antes de confirmar
        connection.abort()
        print("[OK] Transacción abortada con connection.abort().")
        print(f"Total de restaurantes tras abort(): {len(root['restaurants'])} (esperado: {total_antes})")

        # --- CRUD: BAJA (DELETE / COMPOSICIÓN EN CASCADA) ---
        print("\n=== 5. CRUD: BAJA DE OBJETO HIJO (DELETE) ===")
        platillo_a_eliminar = "Platillo Temporal"
        temp_dish = Dish(platillo_a_eliminar, "Platillo para probar eliminación", 50.00)
        restaurant.add_dish(temp_dish)
        connection.commit()
        print(f"Platillos antes de eliminar: {[d.name for d in restaurant.dishes]}")

        restaurant.remove_dish(platillo_a_eliminar)
        connection.commit()
        print(f"[OK] '{platillo_a_eliminar}' eliminado. Platillos actuales: {[d.name for d in restaurant.dishes]}")

    finally:
        # Garantizar el cierre del archivo de almacenamiento y liberación del lock en Windows
        storage.close()
        print("\n[OK] Almacenamiento 'karta_db.durus' cerrado de forma segura.")

if __name__ == "__main__":
    main()