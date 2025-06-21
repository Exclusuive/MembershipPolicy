module exclusuive::dokpami;

use std::string::{String};

////////// -----------
public struct OldNFT has key, store {
  id: UID,
}

/////////// -----------
public struct Dokpami has key, store {
  id: UID,
}

// Layer
public struct BackgroundLayer has drop {}

public struct BackgroundItem<phantom BackgroundLayer> has key, store {
  id: UID
}

public struct CharacterLayer has drop {}

// Property
public struct StrProperty has drop {}

public struct IntProperty has drop {}

// Item
public struct FireBackground has key, store {
  id: UID
}
public struct SnowBackground has key, store {
  id: UID
}
public struct RainBackground has key, store {
  id: UID
}

public struct Character1 has key, store {
  id: UID
}

public struct Character2 has key, store {
  id: UID
}


public struct LayerConfig has store, drop {
  description: String,
  sub_descir: String,
}

public struct ItemConfig has store, drop {
  description: String,
  sub_descir: String,
}

public struct PropertyConfig has store, drop {
  description: String,
  sub_descir: String,
}


