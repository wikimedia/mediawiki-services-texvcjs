"use strict";
var assert = require('assert');
var texvcinfo = require('../');
var testcases = [
    {
        input: '',
        out: {
            "checked": "",
            "identifiers": [],
            requiredPackages: [],
            "success": true,
            endsWithDot: false
        }
    },
    {
        input: '{\\cos(x).}',
        out: {
            "checked": "{\\cos(x).}",
            "identifiers": ['x'],
            requiredPackages: [],
            endsWithDot: true,
            "success": true
        }
    },
    {
        input: '{\\cos\\left(x.\\right)}',
        out: {
            "checked": "{\\cos \\left(x.\\right)}",
            "identifiers": ['x'],
            requiredPackages: [],
            endsWithDot: false,
            "success": true
        }
    },
    {
        input: '\\mathbb{x}',
        out: {
            "checked": "\\mathbb {x} ",
            "identifiers": [
                "\\mathbb{x}"
            ],
            requiredPackages: ['ams'],
            "success": true,
            endsWithDot: false
        }
    },
    {
        input: 'a+\\badfunc-b',
        out: {
            "column": 3,
            "details": "\\badfunc",
            "error": {
                "expected": [],
                "found": "\\badfunc",
                "location": {
                    "end": {
                        "column": 11,
                        "line": 1,
                        "offset": 10
                    },
                    "start": {
                        "column": 3,
                        "line": 1,
                        "offset": 2
                    }
                },
                "message": "Illegal TeX function",
                "name": "SyntaxError"
            },
            "line": 1,
            "offset": 2,
            "status": "F",
            "success": false,
            "warnings": []
        }
    },
    {
        input: '\\sin\\left(x)',
        out: {
            "column": 13,
            "details": "SyntaxError: Expected \"\\\\\", \"\\\\begin\", \"\\\\begin{\", \"]\", \"^\", \"_\", \"{\", [ \\t\\n\\r], [!'*-\\-0-;=?A-Za-z], [%$], [(-).-/[|], or [><~] but end of input found.",
            "error": {
                "expected": [
                    {
                        "ignoreCase": false,
                        "inverted": false,
                        "parts": [
                            " ",
                            "\t",
                            "\n",
                            "\r",
                        ],
                        "type": "class",
                        "unicode": false,
                    },
                    {
                        "ignoreCase": false,
                        "text": "_",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "text": "^",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "inverted": false,
                        "parts": [
                            "!",
                            "'",
                            [
                                "*",
                                "-",
                            ],
                            [
                                "0",
                                ";",
                            ],
                            "=",
                            "?",
                            [
                                "A",
                                "Z",
                            ],
                            [
                                "a",
                                "z",
                            ],
                        ],
                        "type": "class",
                        "unicode": false,
                    },
                    {
                        "ignoreCase": false,
                        "text": "\\",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "text": "\\",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "inverted": false,
                        "parts": [
                            ">",
                            "<",
                            "~",
                        ],
                        "type": "class",
                        "unicode": false,
                    },
                    {
                        "ignoreCase": false,
                        "inverted": false,
                        "parts": [
                            "%",
                            "$",
                        ],
                        "type": "class",
                        "unicode": false,
                    },
                    {
                        "ignoreCase": false,
                        "inverted": false,
                        "parts": [
                            [
                                "(",
                                ")",
                            ],
                            [
                                ".",
                                "/",
                            ],
                            "[",
                            "|",
                        ],
                        "type": "class",
                        "unicode": false,
                    },
                    {
                        "ignoreCase": false,
                        "text": "\\",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "text": "{",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "text": "\\begin",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "text": "\\begin{",
                        "type": "literal",
                    },
                    {
                        "ignoreCase": false,
                        "text": "]",
                        "type": "literal",
                    },
                ],
                "found": null,
                "location": {
                    "end": {
                        "column": 13,
                        "line": 1,
                        "offset": 12,
                    },
                    "start": {
                        "column": 13,
                        "line": 1,
                        "offset": 12,
                    },
                },
                "message": "Expected \"\\\\\", \"\\\\begin\", \"\\\\begin{\", \"]\", \"^\", \"_\", \"{\", [ \\t\\n\\r], [!'*-\\-0-;=?A-Za-z], [%$], [(-).-/[|], or [><~] but end of input found.",
                "name": "SyntaxError",
            },
            "line": 1,
            "offset": 12,
            "status": "S",
            "success": false,
            "warnings": [],
        }
    },
    {
        input: '\\ce{H2O}',
        options: {usemhchem: true},
        out: {
            "checked": "{\\ce {H2O}}",
            "endsWithDot": false,
            "identifiers": [],
            "requiredPackages": [
                "mhchem"
            ],
            "success": true
        }
    }, {
        input: '\\ce{H2O}',
        out: {
            "error": {
                "detail": "mhchem package required.",
                "found": "\\ce",
                "message": "Attempting to use the $\\ce$ command outside of a chemistry environment.",
                "name": "SyntaxError",
                "status": "C"
            },
            "success": false
        }
    },
    {
        input: '\\ce {\\log}',
        options: {usemhchem: true},
        out: {
            "checked": "{\\ce {\\log }}",
            "endsWithDot": false,
            "identifiers": [],
            "requiredPackages": [
                "mhchem"
            ],
            "success": true,
            "warnings": [
                {
                    "details": {
                        "column": 10,
                        "details": "SyntaxError: Expected [a-zA-Z] but \"}\" found.",
                        "error": {
                            "expected": [
                                {
                                    "ignoreCase": false,
                                    "inverted": false,
                                    "parts": [
                                        [
                                            "a",
                                            "z"
                                        ],
                                        [
                                            "A",
                                            "Z"
                                        ],
                                    ],
                                    "type": "class",
                                    "unicode": false
                                }
                            ],
                            "found": "}",
                            "location": {
                                "end": {
                                    "column": 11,
                                    "line": 1,
                                    "offset": 10,
                                },
                                "start": {
                                    "column": 10,
                                    "line": 1,
                                    "offset": 9,
                                },
                            },
                            "message": "Expected [a-zA-Z] but \"}\" found.",
                            "name": "SyntaxError",
                        },
                        "line": 1,
                        "offset": 9,
                        "status": "S",
                        "success": false,
                        "warnings": [],
                    },
                    "type": "mhchem-deprecation"
                }
            ]
        }
    },
    {
        input: '\\ce{a{b^c}}',
        options: {usemhchem: true},
        out: {
            "success": true,
            "checked": "{\\ce {a{b^{c}}}}",
            "requiredPackages": [
                "mhchem"
            ],
            "identifiers": [
                "a",
                "b",
                "c"
            ],
            "endsWithDot": false,
            "warnings": [
                {
                    "details": {
                        "column": 8,
                        "details": "SyntaxError: Expected \"}\" or valid UTF-16 sequences but \"^\" found.",
                        "error": {
                            "expected": [
                                {
                                    "description": "valid UTF-16 sequences",
                                    "type": "other"
                                },
                                {
                                    "ignoreCase": false,
                                    "text": "}",
                                    "type": "literal",
                                },
                            ],
                            "found": "^",
                            "location": {
                                "end": {
                                    "column": 9,
                                    "line": 1,
                                    "offset": 8,
                                },
                                "start": {
                                    "column": 8,
                                    "line": 1,
                                    "offset": 7,
                                }
                            },
                            "message": "Expected \"}\" or valid UTF-16 sequences but \"^\" found.",
                            "name": "SyntaxError",
                        },
                        "line": 1,
                        "offset": 7,
                        "status": "S",
                        "success": false,
                        "warnings": [],
                    },
                    "type": "mhchem-deprecation"
                }
            ]
        }
    }
];

describe('Feedback', function () {
    testcases.forEach(function (tc) {
        var input = tc.input;
        var output = tc.out;
        var options = tc.options;
        it('should give adequate feedback ' + JSON.stringify(input), function () {
            assert.deepEqual(texvcinfo.feedback(input, options), output);
        });
    });
});