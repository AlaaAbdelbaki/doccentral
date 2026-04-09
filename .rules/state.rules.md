# State Management Rules

## Provider Patterns
- Riverpod 3.x.x exclusively with code generation
- Only use `@riverpod` and `@Riverpod` annotations
- Scoped vs global providers naming conventions

## Provider Interaction
- Only top-level widgets (ConsumerWidget) read/write providers
- Lower-level widgets receive provider actions via callbacks
- Expose services to UI via providers only

## Testing
- Providers must include unit tests

## Performance Rules

- Avoid unnecessary provider rebuilds
- Use selective listening (ref.watch/select)
- Avoid large widget rebuilds
- Prefer const constructors when possible