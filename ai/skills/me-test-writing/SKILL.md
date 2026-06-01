---
name: test-writing
description: Here is instructions how to write tests.
---

1. Test cases should be readable by humans. I.e. testcase should be up to 30-40 lines long. 
2. Use language constructions to make code readable. Simple is better than complex.
3. All common code should be extracted to helper functions.
4. Helper functions should be named descriptively.
5. Helper functions should be placed in the same file as the test case. After test case it used in or describe block it used in, or at the end of a file if used in many describe blocks.
6. Keep comments minimal — Elixir code is mostly self-explanatory. Prefer expressing intent through descriptive names and language constructs over comments. Acceptable comments: section separators (e.g. `# Helpers`), and short notes that capture something non-obvious (a race, an off-by-one, a structural constraint) as a hint for a future reader or LLM. Where a construct fits (`@doc` / `@moduledoc`), use it instead of a comment.

