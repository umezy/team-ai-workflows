# Sample API reference

> Sample knowledge for the search demo. Replace with your SDK's real API reference.

## createWidget(options)

Creates a widget and returns its id.

- `options.name` (string, required) — display name of the widget
- `options.color` (string, optional) — hex color, defaults to `#ffffff`

Returns: `widgetId` (string)

## destroyWidget(widgetId)

Destroys the widget. Destroying an unknown id is a no-op, not an error.

## Known pitfall

`createWidget` must not be called before the runtime is ready; wait for the `ready` event first, or the call silently returns `null`.
