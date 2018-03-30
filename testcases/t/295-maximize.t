#!perl
# vim:ts=4:sw=4:expandtab
#
# Please read the following documents before working on tests:
# • https://build.i3wm.org/docs/testsuite.html
#   (or docs/testsuite)
#
# • https://build.i3wm.org/docs/lib-i3test.html
#   (alternatively: perldoc ./testcases/lib/i3test.pm)
#
# • https://build.i3wm.org/docs/ipc.html
#   (or docs/ipc)
#
# • http://onyxneon.com/books/modern_perl/modern_perl_a4.pdf
#   (unless you are already familiar with Perl)
#
# TODO: Description of this file.
use i3test;

my $i3 = i3(get_socket_path());

my $tmp = fresh_workspace;

# get the output of this workspace
my $tree = $i3->get_tree->recv;
my @outputs = @{$tree->{nodes}};
my $output;
for my $o (@outputs) {
    # get the first CT_CON of each output
    my $content = first { $_->{type} eq 'con' } @{$o->{nodes}};
    if (defined(first { $_->{name} eq $tmp } @{$content->{nodes}})) {
        $output = $o;
        last;
    }
}

##################################
# map a window, then maximize it
##################################

my $original_rect = X11::XCB::Rect->new(x => 0, y => 0, width => 30, height => 30);

my $window = open_window(
    rect => $original_rect,
    dont_map => 1,
);

isa_ok($window, 'X11::XCB::Window');

is_deeply($window->rect, $original_rect, "rect unmodified before mapping");

$window->map;

wait_for_map $window;

# open another container to make the window get only half of the screen
cmd 'open';

my $new_rect = $window->rect;
ok(!eq_hash($new_rect, $original_rect), "Window got repositioned");
$original_rect = $new_rect;

$window->maximize(true);

sync_with_i3;

$new_rect = $window->rect;
ok(!eq_hash($new_rect, $original_rect), "Window got repositioned after maximize");

my $orect = $output->{rect};
my $wrect = $new_rect;

# see if the window really is maximized. 20 px for borders are allowed
# TODO(justin): re-examine this logic
my $threshold = 20;
ok(($wrect->{x} - $orect->{x}) < $threshold, 'x coordinate maximize');
ok(($wrect->{y} - $orect->{y}) < $threshold, 'y coordinate maximize');
ok(abs($wrect->{width} - $orect->{width}) < $threshold, 'width coordinate maximize');
ok(abs($wrect->{height} - $orect->{height}) < $threshold, 'height coordinate maximize');


$window->unmap;

# TODO

# TODO: more tests

done_testing;
