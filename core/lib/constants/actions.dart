typedef UserActionListener<T> = void Function(T item, UserAction action);

enum UserAction {
  SHOW,
  EDIT,
  SELECT,
  LOAD,
  OPTIONS,
  REACT,
  RATE, // review
  COMMENT,
  SHARE,
  DELETE,
  REPORT,
  FOLLOW,
  ACCEPT,
  REFUSE,
  BAN,
  BOOKMARK,
  PICK, // add to cart
}
