Swift Performance Playground
============================

This is a skeleton Swift Playground for visualizing the time complexity of
algorithms.

![Playground and resulting chart for two example algorithms]

Usage
-----

To see a working example, open `Performance.playground` and scroll to the
bottom. Once you run the Playground (`CMD + SHIFT + RET`), the resulting time
chart (plotting time in seconds over the input size) will start drawing in the
live view.

To test your own algorithms, customize the contents of the `Chart Display` and
`Measurements` sections.

Measurements are driven by an input data specification. The following is an
example specification that steps from 1 to 1,000,000 multiplying the current
size by 4 in each step and returning an accordingly sized randomized array of
integers.

``` {.swift}
let input = Timekeeper.InputSpec(
    minSize: 1,
    maxSize: 1000000,
    step: { $0 * 4 }) { inputSize in
        (0..<inputSize).shuffled()
    }
```

The specification is then handed to the time keeper together with the algorithm
to be measured.

``` {.swift}
timekeeper.measure(input: input, blocks: [
    { data in
        _ = data.sorted()
    }
])
```

Todo List
---------

-   Add labels & grid lines in non-logarithmic mode
-   Add a legend

Known Issues
------------

Occasionally and especially when choosing two large inputs the Playground will
hang and refuse to restart. You'll have to force-kill and relaunch Xcode in this
case.

License
-------

Swift Performance Playground is licensed under the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

  [Playground and resulting chart for two example algorithms]: screenshot.png
