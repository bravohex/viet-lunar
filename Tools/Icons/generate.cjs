// Static Lucide assets only: no JavaScript or third-party renderer ships in the app.
const fs = require('node:fs')
const path = require('node:path')
const { Resvg } = require('@resvg/resvg-js')
const root = path.resolve(__dirname, '../..')
const assets = path.join(root, 'App/Resources/Assets.xcassets')
const lucide = path.dirname(require.resolve('lucide-static/package.json'))
const icons = {
  LucideCalendarDays: 'calendar-days',
  LucideChevronLeft: 'chevron-left',
  LucideChevronRight: 'chevron-right',
  LucideCalendarCheck: 'calendar-check',
  LucideSettings: 'settings',
  LucideInfo: 'info',
  LucidePower: 'power',
  LucideFlag: 'flag',
  LucideBookmark: 'bookmark',
  LucideTriangleAlert: 'triangle-alert'
}
const json = value => JSON.stringify(value, null, 2) + '\n'
const source = name => fs.readFileSync(path.join(lucide, 'icons', `${name}.svg`), 'utf8')
const outputs = new Map()
for (const [asset, name] of Object.entries(icons)) {
  const directory = path.join(assets, `${asset}.imageset`)
  // SVG currentColor is resolved explicitly for Apple's asset compiler;
  // template rendering supplies the actual light/dark/disabled foreground.
  outputs.set(path.join(directory, `${name}.svg`), source(name).replaceAll('currentColor', '#000000'))
  outputs.set(path.join(directory, 'Contents.json'), json({
    images: [{ filename: `${name}.svg`, idiom: 'universal' }],
    info: { author: 'xcode', version: 1 },
    properties: { 'preserves-vector-representation': true, 'template-rendering-intent': 'template' }
  }))
}
// The official calendar-days glyph on a plain macOS tile replaces the custom
// illustrated app icon. Only the tile/color/layout is app-specific.
const glyph = source('calendar-days').replace(/<!--[\s\S]*?-->/g, '')
  .replace('width="24"', 'x="192" y="192" width="640"').replace('height="24"', 'height="640"')
  .replaceAll('currentColor', '#ffffff')
const appSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect x="96" y="96" width="832" height="832" rx="184" fill="#C53630"/>${glyph}</svg>`
const images = []
for (const size of [16, 32, 128, 256, 512]) {
  for (const scale of [1, 2]) {
    const filename = `icon_${size}x${size}${scale === 2 ? '@2x' : ''}.png`
    const pixels = size * scale
    const renderer = new Resvg(appSVG, { fitTo: { mode: 'width', value: pixels } })
    const png = renderer.render().asPng()
    if (png.readUInt32BE(16) !== pixels || png.readUInt32BE(20) !== pixels) throw new Error(`Wrong icon dimensions: ${filename}`)
    outputs.set(path.join(assets, 'AppIcon.appiconset', filename), png)
    images.push({ filename, idiom: 'mac', scale: `${scale}x`, size: `${size}x${size}` })
  }
}
outputs.set(path.join(assets, 'AppIcon.appiconset/Contents.json'), json({ images, info: { author: 'xcode', version: 1 } }))
outputs.set(path.join(root, 'App/Resources/Lucide-LICENSE.txt'), fs.readFileSync(path.join(lucide, 'LICENSE')))
const args = process.argv.slice(2)
if (args.length && (args.length !== 1 || args[0] !== '--check')) throw new Error('Usage: node generate.cjs [--check]')
for (const [file, value] of outputs) {
  const bytes = Buffer.isBuffer(value) ? value : Buffer.from(value)
  if (args[0] === '--check') {
    if (!fs.existsSync(file) || !fs.readFileSync(file).equals(bytes)) throw new Error(`Stale or missing asset: ${path.relative(root, file)}`)
  } else {
    fs.mkdirSync(path.dirname(file), { recursive: true })
    fs.writeFileSync(file, bytes)
  }
}
console.log(`${args[0] === '--check' ? 'Verified' : 'Generated'} ${outputs.size} files from lucide-static ${require('lucide-static/package.json').version}.`)
