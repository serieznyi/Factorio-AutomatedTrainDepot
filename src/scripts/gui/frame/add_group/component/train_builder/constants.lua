local constants = {}

constants.COMPONENT_NAME = "train_builder"

constants.ACTION = {
    TRAIN_CHANGED = "train_changed",
    DELETE_TRAIN_PART = "delete_train_part",
    CHANGE_LOCOMOTIVE_DIRECTION = "change_locomotive_direction",
    FORM_CHANGED = "form_changed",
}

constants.LOCOMOTIVE_DIRECTION = {
    LEFT = 1,
    RIGHT = 2,
}

return constants