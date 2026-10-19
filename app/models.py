from durus.persistent import Persistent
from durus.persistent_list import PersistentList

class Dish(Persistent):
    """Clase base persistente que representa un platillo"""
    def __init__(self, name: str, description: str, price: float, currency: str = "MXN") -> None:
        super().__init__()
        self.__name: str = name                  
        self.__description: str = description
        self.__price: float = price
        self.__currency: str = currency
        self.__is_available: bool = True

    @property
    def name(self) -> str:
        return self.__name

    @property
    def price(self) -> float:
        return self.__price

    @price.setter
    def price(self, new_price: float) -> None:
        if new_price < 0:
            raise ValueError("El precio no puede ser negativo.")
        self.__price = new_price
        self._p_note_change() # Notifica el cambio a Durus


class SpecialDish(Dish):
    """Subclase para demostrar Herencia y Polimorfismo"""
    def __init__(self, name: str, description: str, price: float, discount_percentage: float) -> None:
        super().__init__(name, description, price)
        self.__discount_percentage: float = discount_percentage

    @property
    def price(self) -> float:
        # Método sobrescrito (Polimorfismo aplicado al precio con descuento)
        base_price = super().price
        return base_price * (1 - (self.__discount_percentage / 100))


class Restaurant(Persistent):
    """Clase principal que compone al Negocio y su Menú (Composición)"""
    def __init__(self, name: str, description: str, phone: str) -> None:
        super().__init__()
        self.__name: str = name
        self.__description: str = description
        self.__phone: str = phone
        self.__dishes: PersistentList = PersistentList()

    def add_dish(self, dish: Dish) -> None:
        self.__dishes.append(dish)
        self._p_note_change()

    def remove_dish(self, dish_name: str) -> None:
        """Baja con efecto en cascada simulado para la composición"""
        for dish in list(self.__dishes):
            if dish.name == dish_name:
                self.__dishes.remove(dish)
                self._p_note_change()
                break

    @property
    def name(self) -> str:
        return self.__name

    @property
    def dishes(self) -> PersistentList:
        return self.__dishes