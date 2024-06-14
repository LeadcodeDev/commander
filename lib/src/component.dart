/// An abstract interface for a component.
/// A component is a part of a system that has a specific function and can operate independently.
/// This interface defines a contract for components that can handle certain tasks and produce a result of type [T].
abstract interface class Component<T> {
  /// Handles the task of this component and produces a result.
  /// This method is asynchronous and returns a [Future] that completes with the result of type [T].
  Future<T> handle();
}
