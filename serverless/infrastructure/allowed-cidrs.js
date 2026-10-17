// ALLOWED_SSH_CIDR="1.2.3.4/32,5.6.7.8/32" → SSH CIDRs of the firewall. Empty = any IPv4 (key-only).
const CIDR = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\/(\d|[12]\d|3[0-2])$/

module.exports = () => {
  const cidrs = (process.env.ALLOWED_SSH_CIDR || '')
    .split(',')
    .map((cidr) => cidr.trim())
    .filter(Boolean)

  if (cidrs.length === 0) {
    return ['0.0.0.0/0']
  }
  for (const cidr of cidrs) {
    const match = CIDR.exec(cidr)
    if (!match || match.slice(1, 5).some((octet) => Number(octet) > 255)) {
      throw new Error(`ALLOWED_SSH_CIDR has an invalid IPv4 CIDR: ${cidr}`)
    }
  }
  return cidrs
}
