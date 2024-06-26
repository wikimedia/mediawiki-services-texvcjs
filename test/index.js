"use strict";
var assert = require('assert');
var texvcinfo = require('../');
var testcases = [
    {input: '', options: '', out: []},
    {
        input: '\\mathbb{x}',
        options: {format: "tree"},
        out: [["FUN1nb", ["\\mathbb"], ["CURLY", [["LITERAL", ["x"]]]]]]
    },
    {
        input: '\\mathbb{x}',
        options: {format: "identifier"},
        out: ['\\mathbb{x}']
    },
    {
        input: '\\mathbb{x}',
        options: {format: "list"},
        out: [["FUN1nb", "\\mathbb"], ["CURLY", ""], ["LITERAL", "x"]]
    }, {
        input: '\\mathbb{x}',
        options: {format: "json"},
        out: {
            "name": "ARRAY",
            "children": [{
                "name": "FUN1nb",
                "children": [{"name": "\\mathbb"}, {
                    "name": "CURLY",
                    "children": [{
                        "name": "ARRAY",
                        "children": [{
                            "name": "LITERAL",
                            "children":  [{"name": "x"}]
                        }]
                    }]
                }]
            }]
        }

    }, {
        input: '\\mathbb{x}',
        options: {format: "all"},
        out: {
            identifier: ['\\mathbb{x}'],
            tree: [["FUN1nb", ["\\mathbb"], ["CURLY", [["LITERAL", ["x"]]]]]],
            list: [["FUN1nb", "\\mathbb"], ["CURLY", ""], ["LITERAL", "x"]]
        }
    }, {
        input: '\\invalid',
        out: {
            "column": undefined,
            "details": "\\invalid",
            "line": undefined,
            "offset": undefined,
            "status": "F"
        }
    }, {
        input: '\\left(',
        out: {
            "column": undefined,
            "details": "SyntaxError: Expected \"-\", \"[\", \"\\\\\", \"\\\\begin\", \"\\\\begin{\", \"]\", \"^\", \"_\", \"{\", [ \\t\\n\\r], [%$], [().], [,:;?!'], [/|], [0-9], [><~], [\\-+*=], or [a-zA-Z] but end of input found.",
            "line": undefined,
            "offset": undefined,
            "status": "S"
        }
    }
];

describe('Index', function () {
    testcases.forEach(function (tc) {
        var input = tc.input;
        var options = tc.options;
        var output = tc.out;
        it('should correctly handle ' + JSON.stringify(input) + 'with option' + JSON.stringify(options), function () {
            assert.deepStrictEqual(texvcinfo.texvcinfo(input, options), output);
        });
    });
    it('should throw an exception in debug mode', function () {
        try {
            // assert.throws might be alternative
            texvcinfo.texvcinfo('\\left(', {debug: true});
            assert.fail('this code should not be reached');
        } catch (e) {
            assert.equal(e.name, 'SyntaxError');
        }
    });
    it('should handle type-errors', function () {
        const actual = texvcinfo.texvcinfo(
            {length: 1},
            {format: "json", flatTree: true});
        assert.strictEqual(actual.status,'-');
        assert.match(actual.details,/TypeError:/);
        assert.match(actual.details,/undefined/);
    })
});

