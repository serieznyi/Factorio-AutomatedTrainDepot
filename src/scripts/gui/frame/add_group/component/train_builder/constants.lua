local constants = {}

constants.COMPONENT = {
    NAME = "train_builder",
}

constants.ACTION = {
    TYPE_OF_TRAIN_PART_CHANGED = "type_of_train_part_changed",
    TRAIN_PART_DELETE = "train_part_deleted",
    LOCOMOTIVE_DIRECTION_CHANGE = "locomotive_direction_changed",
}

constants.LOCOMOTIVE_DIRECTION = {
    LEFT = 1,
    RIGHT = 2,
}

return constants