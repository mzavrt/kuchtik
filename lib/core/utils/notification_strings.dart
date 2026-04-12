class NotificationStrings {
 // Private constructor to prevent instantiation
  NotificationStrings._();

  static String expiringTitle(double? price) {
    if (price != null && price > 0) {  
      return 'Pozor, vyhazujete ${price.toInt()} Kč! 💸';
    }
   
    return 'Pozor, blíží se expirace! ⏰';
  }

  static String expiringBody(String ingredientName) => 
      '$ingredientName v lednici právě expiruje. Zachraňte ho, ať vaše jídlo neskončí v koši.';
}