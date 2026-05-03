# sample-long — stress test for the line-numbers gutter

This file is intentionally long (over 500 lines) to validate the gutter behavior in `MarkdownEditor`:

- gutter width grows from 2 to 3 digits as line numbers cross 100
- soft-wrapped continuation lines should NOT receive a number
- coloration syntactique cohabite avec la gutter sans interférence
- scroll vertical synchronise correctement les numéros

## A very long line to force soft-wrapping

This single paragraph is intentionally one extremely long line of prose that will overflow the editor width and soft-wrap multiple times depending on the window size, and the goal is precisely to verify that the second, third, and fourth visual lines of this same paragraph do not display a line number in the gutter — only the first visual line should — which is the Xcode/VS Code convention adopted in the spec.

## Code block test

```swift
final class LineNumberRulerView: NSRulerView {
    private weak var observedTextView: NSTextView?
    private var notificationTokens: [NSObjectProtocol] = []

    override func drawHashMarksAndLabels(in rect: NSRect) {
        // The gutter draws here — should not flicker on scroll.
    }
}
```

## Lists

- First bullet
- Second bullet
- Third bullet
  - Nested A
  - Nested B
1. Ordered one
2. Ordered two
3. Ordered three

> A blockquote line.
> Another blockquote line.

## Filler — short lines stress

Filler line 1 — quick brown fox jumps over the lazy dog.
Filler line 2 — quick brown fox jumps over the lazy dog.
Filler line 3 — quick brown fox jumps over the lazy dog.
Filler line 4 — quick brown fox jumps over the lazy dog.
Filler line 5 — quick brown fox jumps over the lazy dog.
Filler line 6 — quick brown fox jumps over the lazy dog.
Filler line 7 — quick brown fox jumps over the lazy dog.
Filler line 8 — quick brown fox jumps over the lazy dog.
Filler line 9 — quick brown fox jumps over the lazy dog.
Filler line 10 — quick brown fox jumps over the lazy dog.
Filler line 11 — quick brown fox jumps over the lazy dog.
Filler line 12 — quick brown fox jumps over the lazy dog.
Filler line 13 — *italic note* and `inline code`
Filler line 14 — quick brown fox jumps over the lazy dog.
Filler line 15 — quick brown fox jumps over the lazy dog.
Filler line 16 — quick brown fox jumps over the lazy dog.
Filler line 17 — quick brown fox jumps over the lazy dog.
Filler line 18 — quick brown fox jumps over the lazy dog.
Filler line 19 — quick brown fox jumps over the lazy dog.
Filler line 20 — quick brown fox jumps over the lazy dog.
Filler line 21 — quick brown fox jumps over the lazy dog.
Filler line 22 — quick brown fox jumps over the lazy dog.
Filler line 23 — quick brown fox jumps over the lazy dog.
Filler line 24 — quick brown fox jumps over the lazy dog.
- Bullet at filler 25 with a tiny **bold** segment
Filler line 26 — *italic note* and `inline code`
Filler line 27 — quick brown fox jumps over the lazy dog.
Filler line 28 — quick brown fox jumps over the lazy dog.
Filler line 29 — quick brown fox jumps over the lazy dog.
Filler line 30 — quick brown fox jumps over the lazy dog.
Filler line 31 — quick brown fox jumps over the lazy dog.
Filler line 32 — quick brown fox jumps over the lazy dog.
Filler line 33 — quick brown fox jumps over the lazy dog.
Filler line 34 — quick brown fox jumps over the lazy dog.
Filler line 35 — quick brown fox jumps over the lazy dog.
Filler line 36 — quick brown fox jumps over the lazy dog.
Filler line 37 — quick brown fox jumps over the lazy dog.
Filler line 38 — quick brown fox jumps over the lazy dog.
Filler line 39 — *italic note* and `inline code`
Filler line 40 — quick brown fox jumps over the lazy dog.
Filler line 41 — quick brown fox jumps over the lazy dog.
Filler line 42 — quick brown fox jumps over the lazy dog.
Filler line 43 — quick brown fox jumps over the lazy dog.
Filler line 44 — quick brown fox jumps over the lazy dog.
Filler line 45 — quick brown fox jumps over the lazy dog.
Filler line 46 — quick brown fox jumps over the lazy dog.
Filler line 47 — quick brown fox jumps over the lazy dog.
Filler line 48 — quick brown fox jumps over the lazy dog.
Filler line 49 — quick brown fox jumps over the lazy dog.

## Marker at filler line 50

Filler line 51 — quick brown fox jumps over the lazy dog.
Filler line 52 — *italic note* and `inline code`
Filler line 53 — quick brown fox jumps over the lazy dog.
Filler line 54 — quick brown fox jumps over the lazy dog.
Filler line 55 — quick brown fox jumps over the lazy dog.
Filler line 56 — quick brown fox jumps over the lazy dog.
Filler line 57 — quick brown fox jumps over the lazy dog.
Filler line 58 — quick brown fox jumps over the lazy dog.
Filler line 59 — quick brown fox jumps over the lazy dog.
Filler line 60 — quick brown fox jumps over the lazy dog.
Filler line 61 — quick brown fox jumps over the lazy dog.
Filler line 62 — quick brown fox jumps over the lazy dog.
Filler line 63 — quick brown fox jumps over the lazy dog.
Filler line 64 — quick brown fox jumps over the lazy dog.
Filler line 65 — *italic note* and `inline code`
Filler line 66 — quick brown fox jumps over the lazy dog.
Filler line 67 — quick brown fox jumps over the lazy dog.
Filler line 68 — quick brown fox jumps over the lazy dog.
Filler line 69 — quick brown fox jumps over the lazy dog.
Filler line 70 — quick brown fox jumps over the lazy dog.
Filler line 71 — quick brown fox jumps over the lazy dog.
Filler line 72 — quick brown fox jumps over the lazy dog.
Filler line 73 — quick brown fox jumps over the lazy dog.
Filler line 74 — quick brown fox jumps over the lazy dog.
- Bullet at filler 75 with a tiny **bold** segment
Filler line 76 — quick brown fox jumps over the lazy dog.
Filler line 77 — quick brown fox jumps over the lazy dog.
Filler line 78 — *italic note* and `inline code`
Filler line 79 — quick brown fox jumps over the lazy dog.
Filler line 80 — quick brown fox jumps over the lazy dog.
Filler line 81 — quick brown fox jumps over the lazy dog.
Filler line 82 — quick brown fox jumps over the lazy dog.
Filler line 83 — quick brown fox jumps over the lazy dog.
Filler line 84 — quick brown fox jumps over the lazy dog.
Filler line 85 — quick brown fox jumps over the lazy dog.
Filler line 86 — quick brown fox jumps over the lazy dog.
Filler line 87 — quick brown fox jumps over the lazy dog.
Filler line 88 — quick brown fox jumps over the lazy dog.
Filler line 89 — quick brown fox jumps over the lazy dog.
Filler line 90 — quick brown fox jumps over the lazy dog.
Filler line 91 — *italic note* and `inline code`
Filler line 92 — quick brown fox jumps over the lazy dog.
Filler line 93 — quick brown fox jumps over the lazy dog.
Filler line 94 — quick brown fox jumps over the lazy dog.
Filler line 95 — quick brown fox jumps over the lazy dog.
Filler line 96 — quick brown fox jumps over the lazy dog.
Filler line 97 — quick brown fox jumps over the lazy dog.
Filler line 98 — quick brown fox jumps over the lazy dog.
Filler line 99 — quick brown fox jumps over the lazy dog.

## Marker at filler line 100

Filler line 101 — quick brown fox jumps over the lazy dog.
Filler line 102 — quick brown fox jumps over the lazy dog.
Filler line 103 — quick brown fox jumps over the lazy dog.
Filler line 104 — *italic note* and `inline code`
Filler line 105 — quick brown fox jumps over the lazy dog.
Filler line 106 — quick brown fox jumps over the lazy dog.
Filler line 107 — quick brown fox jumps over the lazy dog.
Filler line 108 — quick brown fox jumps over the lazy dog.
Filler line 109 — quick brown fox jumps over the lazy dog.
Filler line 110 — quick brown fox jumps over the lazy dog.
Filler line 111 — quick brown fox jumps over the lazy dog.
Filler line 112 — quick brown fox jumps over the lazy dog.
Filler line 113 — quick brown fox jumps over the lazy dog.
Filler line 114 — quick brown fox jumps over the lazy dog.
Filler line 115 — quick brown fox jumps over the lazy dog.
Filler line 116 — quick brown fox jumps over the lazy dog.
Filler line 117 — *italic note* and `inline code`
Filler line 118 — quick brown fox jumps over the lazy dog.
Filler line 119 — quick brown fox jumps over the lazy dog.
Filler line 120 — quick brown fox jumps over the lazy dog.
Filler line 121 — quick brown fox jumps over the lazy dog.
Filler line 122 — quick brown fox jumps over the lazy dog.
Filler line 123 — quick brown fox jumps over the lazy dog.
Filler line 124 — quick brown fox jumps over the lazy dog.
- Bullet at filler 125 with a tiny **bold** segment
Filler line 126 — quick brown fox jumps over the lazy dog.
Filler line 127 — quick brown fox jumps over the lazy dog.
Filler line 128 — quick brown fox jumps over the lazy dog.
Filler line 129 — quick brown fox jumps over the lazy dog.
Filler line 130 — *italic note* and `inline code`
Filler line 131 — quick brown fox jumps over the lazy dog.
Filler line 132 — quick brown fox jumps over the lazy dog.
Filler line 133 — quick brown fox jumps over the lazy dog.
Filler line 134 — quick brown fox jumps over the lazy dog.
Filler line 135 — quick brown fox jumps over the lazy dog.
Filler line 136 — quick brown fox jumps over the lazy dog.
Filler line 137 — quick brown fox jumps over the lazy dog.
Filler line 138 — quick brown fox jumps over the lazy dog.
Filler line 139 — quick brown fox jumps over the lazy dog.
Filler line 140 — quick brown fox jumps over the lazy dog.
Filler line 141 — quick brown fox jumps over the lazy dog.
Filler line 142 — quick brown fox jumps over the lazy dog.
Filler line 143 — *italic note* and `inline code`
Filler line 144 — quick brown fox jumps over the lazy dog.
Filler line 145 — quick brown fox jumps over the lazy dog.
Filler line 146 — quick brown fox jumps over the lazy dog.
Filler line 147 — quick brown fox jumps over the lazy dog.
Filler line 148 — quick brown fox jumps over the lazy dog.
Filler line 149 — quick brown fox jumps over the lazy dog.

## Marker at filler line 150

Filler line 151 — quick brown fox jumps over the lazy dog.
Filler line 152 — quick brown fox jumps over the lazy dog.
Filler line 153 — quick brown fox jumps over the lazy dog.
Filler line 154 — quick brown fox jumps over the lazy dog.
Filler line 155 — quick brown fox jumps over the lazy dog.
Filler line 156 — *italic note* and `inline code`
Filler line 157 — quick brown fox jumps over the lazy dog.
Filler line 158 — quick brown fox jumps over the lazy dog.
Filler line 159 — quick brown fox jumps over the lazy dog.
Filler line 160 — quick brown fox jumps over the lazy dog.
Filler line 161 — quick brown fox jumps over the lazy dog.
Filler line 162 — quick brown fox jumps over the lazy dog.
Filler line 163 — quick brown fox jumps over the lazy dog.
Filler line 164 — quick brown fox jumps over the lazy dog.
Filler line 165 — quick brown fox jumps over the lazy dog.
Filler line 166 — quick brown fox jumps over the lazy dog.
Filler line 167 — quick brown fox jumps over the lazy dog.
Filler line 168 — quick brown fox jumps over the lazy dog.
Filler line 169 — *italic note* and `inline code`
Filler line 170 — quick brown fox jumps over the lazy dog.
Filler line 171 — quick brown fox jumps over the lazy dog.
Filler line 172 — quick brown fox jumps over the lazy dog.
Filler line 173 — quick brown fox jumps over the lazy dog.
Filler line 174 — quick brown fox jumps over the lazy dog.
- Bullet at filler 175 with a tiny **bold** segment
Filler line 176 — quick brown fox jumps over the lazy dog.
Filler line 177 — quick brown fox jumps over the lazy dog.
Filler line 178 — quick brown fox jumps over the lazy dog.
Filler line 179 — quick brown fox jumps over the lazy dog.
Filler line 180 — quick brown fox jumps over the lazy dog.
Filler line 181 — quick brown fox jumps over the lazy dog.
Filler line 182 — *italic note* and `inline code`
Filler line 183 — quick brown fox jumps over the lazy dog.
Filler line 184 — quick brown fox jumps over the lazy dog.
Filler line 185 — quick brown fox jumps over the lazy dog.
Filler line 186 — quick brown fox jumps over the lazy dog.
Filler line 187 — quick brown fox jumps over the lazy dog.
Filler line 188 — quick brown fox jumps over the lazy dog.
Filler line 189 — quick brown fox jumps over the lazy dog.
Filler line 190 — quick brown fox jumps over the lazy dog.
Filler line 191 — quick brown fox jumps over the lazy dog.
Filler line 192 — quick brown fox jumps over the lazy dog.
Filler line 193 — quick brown fox jumps over the lazy dog.
Filler line 194 — quick brown fox jumps over the lazy dog.
Filler line 195 — *italic note* and `inline code`
Filler line 196 — quick brown fox jumps over the lazy dog.
Filler line 197 — quick brown fox jumps over the lazy dog.
Filler line 198 — quick brown fox jumps over the lazy dog.
Filler line 199 — quick brown fox jumps over the lazy dog.

## Marker at filler line 200

Filler line 201 — quick brown fox jumps over the lazy dog.
Filler line 202 — quick brown fox jumps over the lazy dog.
Filler line 203 — quick brown fox jumps over the lazy dog.
Filler line 204 — quick brown fox jumps over the lazy dog.
Filler line 205 — quick brown fox jumps over the lazy dog.
Filler line 206 — quick brown fox jumps over the lazy dog.
Filler line 207 — quick brown fox jumps over the lazy dog.
Filler line 208 — *italic note* and `inline code`
Filler line 209 — quick brown fox jumps over the lazy dog.
Filler line 210 — quick brown fox jumps over the lazy dog.
Filler line 211 — quick brown fox jumps over the lazy dog.
Filler line 212 — quick brown fox jumps over the lazy dog.
Filler line 213 — quick brown fox jumps over the lazy dog.
Filler line 214 — quick brown fox jumps over the lazy dog.
Filler line 215 — quick brown fox jumps over the lazy dog.
Filler line 216 — quick brown fox jumps over the lazy dog.
Filler line 217 — quick brown fox jumps over the lazy dog.
Filler line 218 — quick brown fox jumps over the lazy dog.
Filler line 219 — quick brown fox jumps over the lazy dog.
Filler line 220 — quick brown fox jumps over the lazy dog.
Filler line 221 — *italic note* and `inline code`
Filler line 222 — quick brown fox jumps over the lazy dog.
Filler line 223 — quick brown fox jumps over the lazy dog.
Filler line 224 — quick brown fox jumps over the lazy dog.
- Bullet at filler 225 with a tiny **bold** segment
Filler line 226 — quick brown fox jumps over the lazy dog.
Filler line 227 — quick brown fox jumps over the lazy dog.
Filler line 228 — quick brown fox jumps over the lazy dog.
Filler line 229 — quick brown fox jumps over the lazy dog.
Filler line 230 — quick brown fox jumps over the lazy dog.
Filler line 231 — quick brown fox jumps over the lazy dog.
Filler line 232 — quick brown fox jumps over the lazy dog.
Filler line 233 — quick brown fox jumps over the lazy dog.
Filler line 234 — *italic note* and `inline code`
Filler line 235 — quick brown fox jumps over the lazy dog.
Filler line 236 — quick brown fox jumps over the lazy dog.
Filler line 237 — quick brown fox jumps over the lazy dog.
Filler line 238 — quick brown fox jumps over the lazy dog.
Filler line 239 — quick brown fox jumps over the lazy dog.
Filler line 240 — quick brown fox jumps over the lazy dog.
Filler line 241 — quick brown fox jumps over the lazy dog.
Filler line 242 — quick brown fox jumps over the lazy dog.
Filler line 243 — quick brown fox jumps over the lazy dog.
Filler line 244 — quick brown fox jumps over the lazy dog.
Filler line 245 — quick brown fox jumps over the lazy dog.
Filler line 246 — quick brown fox jumps over the lazy dog.
Filler line 247 — *italic note* and `inline code`
Filler line 248 — quick brown fox jumps over the lazy dog.
Filler line 249 — quick brown fox jumps over the lazy dog.

## Marker at filler line 250

Filler line 251 — quick brown fox jumps over the lazy dog.
Filler line 252 — quick brown fox jumps over the lazy dog.
Filler line 253 — quick brown fox jumps over the lazy dog.
Filler line 254 — quick brown fox jumps over the lazy dog.
Filler line 255 — quick brown fox jumps over the lazy dog.
Filler line 256 — quick brown fox jumps over the lazy dog.
Filler line 257 — quick brown fox jumps over the lazy dog.
Filler line 258 — quick brown fox jumps over the lazy dog.
Filler line 259 — quick brown fox jumps over the lazy dog.
Filler line 260 — *italic note* and `inline code`
Filler line 261 — quick brown fox jumps over the lazy dog.
Filler line 262 — quick brown fox jumps over the lazy dog.
Filler line 263 — quick brown fox jumps over the lazy dog.
Filler line 264 — quick brown fox jumps over the lazy dog.
Filler line 265 — quick brown fox jumps over the lazy dog.
Filler line 266 — quick brown fox jumps over the lazy dog.
Filler line 267 — quick brown fox jumps over the lazy dog.
Filler line 268 — quick brown fox jumps over the lazy dog.
Filler line 269 — quick brown fox jumps over the lazy dog.
Filler line 270 — quick brown fox jumps over the lazy dog.
Filler line 271 — quick brown fox jumps over the lazy dog.
Filler line 272 — quick brown fox jumps over the lazy dog.
Filler line 273 — *italic note* and `inline code`
Filler line 274 — quick brown fox jumps over the lazy dog.
- Bullet at filler 275 with a tiny **bold** segment
Filler line 276 — quick brown fox jumps over the lazy dog.
Filler line 277 — quick brown fox jumps over the lazy dog.
Filler line 278 — quick brown fox jumps over the lazy dog.
Filler line 279 — quick brown fox jumps over the lazy dog.
Filler line 280 — quick brown fox jumps over the lazy dog.
Filler line 281 — quick brown fox jumps over the lazy dog.
Filler line 282 — quick brown fox jumps over the lazy dog.
Filler line 283 — quick brown fox jumps over the lazy dog.
Filler line 284 — quick brown fox jumps over the lazy dog.
Filler line 285 — quick brown fox jumps over the lazy dog.
Filler line 286 — *italic note* and `inline code`
Filler line 287 — quick brown fox jumps over the lazy dog.
Filler line 288 — quick brown fox jumps over the lazy dog.
Filler line 289 — quick brown fox jumps over the lazy dog.
Filler line 290 — quick brown fox jumps over the lazy dog.
Filler line 291 — quick brown fox jumps over the lazy dog.
Filler line 292 — quick brown fox jumps over the lazy dog.
Filler line 293 — quick brown fox jumps over the lazy dog.
Filler line 294 — quick brown fox jumps over the lazy dog.
Filler line 295 — quick brown fox jumps over the lazy dog.
Filler line 296 — quick brown fox jumps over the lazy dog.
Filler line 297 — quick brown fox jumps over the lazy dog.
Filler line 298 — quick brown fox jumps over the lazy dog.
Filler line 299 — *italic note* and `inline code`

## Marker at filler line 300

Filler line 301 — quick brown fox jumps over the lazy dog.
Filler line 302 — quick brown fox jumps over the lazy dog.
Filler line 303 — quick brown fox jumps over the lazy dog.
Filler line 304 — quick brown fox jumps over the lazy dog.
Filler line 305 — quick brown fox jumps over the lazy dog.
Filler line 306 — quick brown fox jumps over the lazy dog.
Filler line 307 — quick brown fox jumps over the lazy dog.
Filler line 308 — quick brown fox jumps over the lazy dog.
Filler line 309 — quick brown fox jumps over the lazy dog.
Filler line 310 — quick brown fox jumps over the lazy dog.
Filler line 311 — quick brown fox jumps over the lazy dog.
Filler line 312 — *italic note* and `inline code`
Filler line 313 — quick brown fox jumps over the lazy dog.
Filler line 314 — quick brown fox jumps over the lazy dog.
Filler line 315 — quick brown fox jumps over the lazy dog.
Filler line 316 — quick brown fox jumps over the lazy dog.
Filler line 317 — quick brown fox jumps over the lazy dog.
Filler line 318 — quick brown fox jumps over the lazy dog.
Filler line 319 — quick brown fox jumps over the lazy dog.
Filler line 320 — quick brown fox jumps over the lazy dog.
Filler line 321 — quick brown fox jumps over the lazy dog.
Filler line 322 — quick brown fox jumps over the lazy dog.
Filler line 323 — quick brown fox jumps over the lazy dog.
Filler line 324 — quick brown fox jumps over the lazy dog.
- Bullet at filler 325 with a tiny **bold** segment
Filler line 326 — quick brown fox jumps over the lazy dog.
Filler line 327 — quick brown fox jumps over the lazy dog.
Filler line 328 — quick brown fox jumps over the lazy dog.
Filler line 329 — quick brown fox jumps over the lazy dog.
Filler line 330 — quick brown fox jumps over the lazy dog.
Filler line 331 — quick brown fox jumps over the lazy dog.
Filler line 332 — quick brown fox jumps over the lazy dog.
Filler line 333 — quick brown fox jumps over the lazy dog.
Filler line 334 — quick brown fox jumps over the lazy dog.
Filler line 335 — quick brown fox jumps over the lazy dog.
Filler line 336 — quick brown fox jumps over the lazy dog.
Filler line 337 — quick brown fox jumps over the lazy dog.
Filler line 338 — *italic note* and `inline code`
Filler line 339 — quick brown fox jumps over the lazy dog.
Filler line 340 — quick brown fox jumps over the lazy dog.
Filler line 341 — quick brown fox jumps over the lazy dog.
Filler line 342 — quick brown fox jumps over the lazy dog.
Filler line 343 — quick brown fox jumps over the lazy dog.
Filler line 344 — quick brown fox jumps over the lazy dog.
Filler line 345 — quick brown fox jumps over the lazy dog.
Filler line 346 — quick brown fox jumps over the lazy dog.
Filler line 347 — quick brown fox jumps over the lazy dog.
Filler line 348 — quick brown fox jumps over the lazy dog.
Filler line 349 — quick brown fox jumps over the lazy dog.

## Marker at filler line 350

Filler line 351 — *italic note* and `inline code`
Filler line 352 — quick brown fox jumps over the lazy dog.
Filler line 353 — quick brown fox jumps over the lazy dog.
Filler line 354 — quick brown fox jumps over the lazy dog.
Filler line 355 — quick brown fox jumps over the lazy dog.
Filler line 356 — quick brown fox jumps over the lazy dog.
Filler line 357 — quick brown fox jumps over the lazy dog.
Filler line 358 — quick brown fox jumps over the lazy dog.
Filler line 359 — quick brown fox jumps over the lazy dog.
Filler line 360 — quick brown fox jumps over the lazy dog.
Filler line 361 — quick brown fox jumps over the lazy dog.
Filler line 362 — quick brown fox jumps over the lazy dog.
Filler line 363 — quick brown fox jumps over the lazy dog.
Filler line 364 — *italic note* and `inline code`
Filler line 365 — quick brown fox jumps over the lazy dog.
Filler line 366 — quick brown fox jumps over the lazy dog.
Filler line 367 — quick brown fox jumps over the lazy dog.
Filler line 368 — quick brown fox jumps over the lazy dog.
Filler line 369 — quick brown fox jumps over the lazy dog.
Filler line 370 — quick brown fox jumps over the lazy dog.
Filler line 371 — quick brown fox jumps over the lazy dog.
Filler line 372 — quick brown fox jumps over the lazy dog.
Filler line 373 — quick brown fox jumps over the lazy dog.
Filler line 374 — quick brown fox jumps over the lazy dog.
- Bullet at filler 375 with a tiny **bold** segment
Filler line 376 — quick brown fox jumps over the lazy dog.
Filler line 377 — *italic note* and `inline code`
Filler line 378 — quick brown fox jumps over the lazy dog.
Filler line 379 — quick brown fox jumps over the lazy dog.
Filler line 380 — quick brown fox jumps over the lazy dog.
Filler line 381 — quick brown fox jumps over the lazy dog.
Filler line 382 — quick brown fox jumps over the lazy dog.
Filler line 383 — quick brown fox jumps over the lazy dog.
Filler line 384 — quick brown fox jumps over the lazy dog.
Filler line 385 — quick brown fox jumps over the lazy dog.
Filler line 386 — quick brown fox jumps over the lazy dog.
Filler line 387 — quick brown fox jumps over the lazy dog.
Filler line 388 — quick brown fox jumps over the lazy dog.
Filler line 389 — quick brown fox jumps over the lazy dog.
Filler line 390 — *italic note* and `inline code`
Filler line 391 — quick brown fox jumps over the lazy dog.
Filler line 392 — quick brown fox jumps over the lazy dog.
Filler line 393 — quick brown fox jumps over the lazy dog.
Filler line 394 — quick brown fox jumps over the lazy dog.
Filler line 395 — quick brown fox jumps over the lazy dog.
Filler line 396 — quick brown fox jumps over the lazy dog.
Filler line 397 — quick brown fox jumps over the lazy dog.
Filler line 398 — quick brown fox jumps over the lazy dog.
Filler line 399 — quick brown fox jumps over the lazy dog.

## Marker at filler line 400

Filler line 401 — quick brown fox jumps over the lazy dog.
Filler line 402 — quick brown fox jumps over the lazy dog.
Filler line 403 — *italic note* and `inline code`
Filler line 404 — quick brown fox jumps over the lazy dog.
Filler line 405 — quick brown fox jumps over the lazy dog.
Filler line 406 — quick brown fox jumps over the lazy dog.
Filler line 407 — quick brown fox jumps over the lazy dog.
Filler line 408 — quick brown fox jumps over the lazy dog.
Filler line 409 — quick brown fox jumps over the lazy dog.
Filler line 410 — quick brown fox jumps over the lazy dog.
Filler line 411 — quick brown fox jumps over the lazy dog.
Filler line 412 — quick brown fox jumps over the lazy dog.
Filler line 413 — quick brown fox jumps over the lazy dog.
Filler line 414 — quick brown fox jumps over the lazy dog.
Filler line 415 — quick brown fox jumps over the lazy dog.
Filler line 416 — *italic note* and `inline code`
Filler line 417 — quick brown fox jumps over the lazy dog.
Filler line 418 — quick brown fox jumps over the lazy dog.
Filler line 419 — quick brown fox jumps over the lazy dog.
Filler line 420 — quick brown fox jumps over the lazy dog.
Filler line 421 — quick brown fox jumps over the lazy dog.
Filler line 422 — quick brown fox jumps over the lazy dog.
Filler line 423 — quick brown fox jumps over the lazy dog.
Filler line 424 — quick brown fox jumps over the lazy dog.
- Bullet at filler 425 with a tiny **bold** segment
Filler line 426 — quick brown fox jumps over the lazy dog.
Filler line 427 — quick brown fox jumps over the lazy dog.
Filler line 428 — quick brown fox jumps over the lazy dog.
Filler line 429 — *italic note* and `inline code`
Filler line 430 — quick brown fox jumps over the lazy dog.
Filler line 431 — quick brown fox jumps over the lazy dog.
Filler line 432 — quick brown fox jumps over the lazy dog.
Filler line 433 — quick brown fox jumps over the lazy dog.
Filler line 434 — quick brown fox jumps over the lazy dog.
Filler line 435 — quick brown fox jumps over the lazy dog.
Filler line 436 — quick brown fox jumps over the lazy dog.
Filler line 437 — quick brown fox jumps over the lazy dog.
Filler line 438 — quick brown fox jumps over the lazy dog.
Filler line 439 — quick brown fox jumps over the lazy dog.
Filler line 440 — quick brown fox jumps over the lazy dog.
Filler line 441 — quick brown fox jumps over the lazy dog.
Filler line 442 — *italic note* and `inline code`
Filler line 443 — quick brown fox jumps over the lazy dog.
Filler line 444 — quick brown fox jumps over the lazy dog.
Filler line 445 — quick brown fox jumps over the lazy dog.
Filler line 446 — quick brown fox jumps over the lazy dog.
Filler line 447 — quick brown fox jumps over the lazy dog.
Filler line 448 — quick brown fox jumps over the lazy dog.
Filler line 449 — quick brown fox jumps over the lazy dog.

## Marker at filler line 450

Filler line 451 — quick brown fox jumps over the lazy dog.
Filler line 452 — quick brown fox jumps over the lazy dog.
Filler line 453 — quick brown fox jumps over the lazy dog.
Filler line 454 — quick brown fox jumps over the lazy dog.
Filler line 455 — *italic note* and `inline code`
Filler line 456 — quick brown fox jumps over the lazy dog.
Filler line 457 — quick brown fox jumps over the lazy dog.
Filler line 458 — quick brown fox jumps over the lazy dog.
Filler line 459 — quick brown fox jumps over the lazy dog.
Filler line 460 — quick brown fox jumps over the lazy dog.
Filler line 461 — quick brown fox jumps over the lazy dog.
Filler line 462 — quick brown fox jumps over the lazy dog.
Filler line 463 — quick brown fox jumps over the lazy dog.
Filler line 464 — quick brown fox jumps over the lazy dog.
Filler line 465 — quick brown fox jumps over the lazy dog.
Filler line 466 — quick brown fox jumps over the lazy dog.
Filler line 467 — quick brown fox jumps over the lazy dog.
Filler line 468 — *italic note* and `inline code`
Filler line 469 — quick brown fox jumps over the lazy dog.
Filler line 470 — quick brown fox jumps over the lazy dog.
Filler line 471 — quick brown fox jumps over the lazy dog.
Filler line 472 — quick brown fox jumps over the lazy dog.
Filler line 473 — quick brown fox jumps over the lazy dog.
Filler line 474 — quick brown fox jumps over the lazy dog.
- Bullet at filler 475 with a tiny **bold** segment
Filler line 476 — quick brown fox jumps over the lazy dog.
Filler line 477 — quick brown fox jumps over the lazy dog.
Filler line 478 — quick brown fox jumps over the lazy dog.
Filler line 479 — quick brown fox jumps over the lazy dog.
Filler line 480 — quick brown fox jumps over the lazy dog.

