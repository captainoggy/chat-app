// a fairly simple deep merge based on: https://gist.github.com/ahtcx/0cd94e62691f539160b32ecda18af3d6
export function merge(...objects) {
  const isObject = obj => obj && typeof obj === "object";

  function deepMergeInner(target, source) {
    Object.keys(source).forEach(key => {
      const targetValue = target[key];
      const sourceValue = source[key];

      if (Array.isArray(targetValue) && Array.isArray(sourceValue)) {
        target[key] = targetValue.concat(sourceValue);
      } else if (isObject(targetValue) && isObject(sourceValue)) {
        target[key] = deepMergeInner(
          Object.assign({}, targetValue),
          sourceValue
        );
      } else {
        target[key] = sourceValue;
      }
    });

    return target;
  }

  if (objects.some(object => object && !isObject(object))) {
    throw new Error('deepMerge: all values should be of type "object"');
  }

  const target = objects.shift();
  let source;

  while ((source = objects.shift())) {
    deepMergeInner(target, source || {});
  }

  return target;
}
