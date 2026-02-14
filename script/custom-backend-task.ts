export async function checkColorSupport(_input, context) {
  const noColor = "NO_COLOR" in context.env;
  const forceColor = "FORCE_COLOR" in context.env;
  const isTTY = !!process.stdout.isTTY;
  return !noColor && (forceColor || isTTY);
}
