const assert = require('node:assert/strict')
const { test } = require('node:test')
const { execFileSync } = require('node:child_process')
const { getEvents, serializeCalendar, generateCalendar } = require('./generate.cjs')

test('each year has public holidays and observances without a projected leave period', () => {
  const events = getEvents()
  assert.equal(events.length, 2116)
  for (let year = 2000; year <= 2050; year++) {
    const annual = events.filter(e => e.date.startsWith(String(year)))
    assert.equal(annual.length, year < 2026 ? 41 : 42)
    assert.equal(annual.filter(e => e.type === 'public').length, year < 2026 ? 6 : 7)
    assert.ok(annual.every(e => e.dayCount === 1))
    assert.ok(annual.every(e => !e.name.includes('Kỳ nghỉ')))
  }
})

test('known Vietnamese lunar dates and a separate single-day New Year eve', () => {
  const events = getEvents()
  for (const [date, name] of [
    ['20260217', 'Tết Nguyên đán'], ['20270206', 'Tết Nguyên đán'],
    ['20280126', 'Tết Nguyên đán'], ['20260426', 'Giỗ Tổ Hùng Vương'],
    ['20260925', 'Tết Trung thu'], ['20270915', 'Tết Trung thu'],
    ['20281003', 'Tết Trung thu'], ['20260216', 'Giao thừa tết Nguyên đán'],
    ['20400205', 'Tết ông Công, ông Táo']
  ]) assert.ok(events.some(e => e.date === date && e.name === name), `${date}: ${name}`)
  assert.equal(events.find(e => e.name === 'Giao thừa tết Nguyên đán').type, 'observance')
  assert.ok(events.some(e => e.date === '20261120' && e.type === 'observance'))
})

test('effective dates and historical book-day names follow source rules', () => {
  const events = getEvents()
  assert.ok(!events.some(e => e.date === '20251124'))
  assert.ok(events.some(e => e.date === '20261124' && e.type === 'public'))
  assert.equal(events.find(e => e.date === '20210421').name, 'Ngày Sách Việt Nam')
  assert.equal(events.find(e => e.date === '20220421').name, 'Ngày Sách và Văn hóa đọc Việt Nam')
})

test('ICS is deterministic, bounded, unique and uses date-only events', () => {
  const text = generateCalendar()
  assert.equal(text, generateCalendar())
  assert.ok(Buffer.byteLength(text) < 1048576)
  assert.ok(!text.includes('RRULE:'))
  assert.ok(text.includes('X-WR-TIMEZONE:Asia/Ho_Chi_Minh'))
  assert.ok(text.includes('DESCRIPTION:observance'))
  const lines = text.split('\r\n')
  assert.ok(lines.every(line => Buffer.byteLength(line) <= 75))
  assert.ok(!text.replaceAll('\r\n', '').includes('\n'))
  const unfolded = text.replace(/\r\n /g, '')
  const uids = unfolded.split('\r\n').filter(line => line.startsWith('UID:'))
  assert.equal(new Set(uids).size, 2116)
  assert.equal(uids.length, 2116)
  assert.equal((unfolded.match(/DTSTART;VALUE=DATE:\d{8}\r\n/g) || []).length, 2116)
})

test('serialization escapes text and folds UTF-8 without corrupting characters', () => {
  const name = 'Tiếng Việt; dấu phẩy, dấu \\ và\nxuống dòng '.repeat(5)
  const text = serializeCalendar([{ date: '20260101', name, type: 'observance', dayCount: 1, rule: '01-01' }])
  const unfolded = text.replace(/\r\n /g, '')
  assert.ok(unfolded.includes('SUMMARY:' + name.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll(';', '\\;').replaceAll(',', '\\,')))
  assert.ok(!text.includes('\uFFFD'))
  assert.ok(text.split('\r\n').every(line => Buffer.byteLength(line) <= 75))
  assert.throws(() => serializeCalendar([{ date: '20260101', name: 'Unknown', type: 'optional', dayCount: 1, rule: '01-01' }]), /type/)
})

test('generation is independent of machine timezone', () => {
  const run = tz => execFileSync(process.execPath, ['-e', "process.stdout.write(require('./generate.cjs').generateCalendar())"], {
    cwd: __dirname, env: { ...process.env, TZ: tz }, maxBuffer: 2 * 1024 * 1024
  })
  assert.deepEqual(run('Pacific/Honolulu'), run('Asia/Tokyo'))
})
