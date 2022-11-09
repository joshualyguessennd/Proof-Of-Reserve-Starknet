export function uintFromParts(low: number, high: number): BigInt {
  return BigInt(high) * 2n ** 128n + BigInt(low);
}
