#!/usr/bin/env raku

enum Commands (
    INC => "+",
    DEC => "-",
    RIGHT => ">",
    LEFT => "<",
    PRINT => ".",
    INPUT => ","
);

grammar Parser {
    rule TOP { <compound>+ }
    rule compound {
        <block> | <cmd>
    }
    rule block {
        "["<compound>*"]"
    }

    token cmd { $(INC) | $(DEC) | $(RIGHT) | $(LEFT) | $(PRINT) | $(INPUT) }
}

sub eval_tree(%state, $tree) {
    for $tree<compound> -> $compound {
        eval_compound(%state, $compound);
    }
}

sub eval_compound(%state, $compound) {
    if $compound<block> {
        eval_block(%state, $compound.<block>)
    }
    elsif $compound<cmd> {
        eval_cmd(%state, $compound.<cmd>)
    }
}

sub eval_block(%state, $block) {
    while %state<data>[%state<dp>] != 0 {
        for $block<compound> -> $compound {
            eval_compound(%state, $compound);
        }
    }
}

sub eval_cmd(%state, $cmd) {
    my $dp = %state<dp>;
    given $cmd {
        when INC {
            ++%state<data>[$dp];
        }
        when DEC {
            --%state<data>[$dp];
        }
        when RIGHT {
            ++%state<dp>;
            %state<data>.append(0) if %state<data>.elems >= %state<dp>;
        }
        when LEFT {
            --%state<dp>;
            die "Data pointer cannot be negative" if %state<dp> < 0;
        }
        when PRINT {
            print %state<data>[$dp].chr;
        }
        when INPUT {
            my $input = prompt(":");
            die "Input must be one byte" if $input.chars != 1;

            %state<data>[$dp] = $input.ord;
        }
    }
}

sub MAIN() {
    my $code = prompt();

    # Reset STDIN
    $*IN.close;
    $*IN = open "/dev/tty";

    my $tree = Parser.parse: $code;
    my %state = (
        dp => 0,
        data => Array[Int].new(0)
    );

    eval_tree(%state, $tree);
}
