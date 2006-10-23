package Catalyst::Helper::View::InstantCRUD;

use version; $VERSION = qv('0.0.4');

use warnings;
use strict;
use Carp;
use Path::Class;
use HTML::Widget::Element::DoubleSelect;

sub mk_compclass {
    my ( $self, $helper, $attrs, $schema) = @_;
    my @classes = map {
        $attrs->{many_to_many_relation_table}{$schema->class($_)->table} ? () : $_
    } @{$attrs->{classes}};

    my $dir = dir( $helper->{dir}, 'root' );
    $helper->mk_dir($dir);

    # TT View
    $helper->mk_component( $helper->{app}, 'view', $helper->{name}, 'TT' );
    
    # table menu
    my $table_menu = '| <a href="[% base %]">Home</a> | <a href="[% base %]restricted">Restricted Area </a> |';
    for my $c (@classes) {
        $table_menu .= ' <a href="[% base %]' . lc($c) . qq{">$c</a> |};
    }
    $helper->mk_file( file( $dir, 'table_menu' ), $table_menu );
   
    # static files
    $helper->render_file( home => file( $dir, 'home' ) );
    $helper->render_file( restricted => file( $dir, 'restricted' ) );
    $helper->mk_file( file( $dir, 'wrapper' ), $helper->get_file( __PACKAGE__, 'wrapper' ) );
    $helper->mk_file( file( $dir, 'login' ), $helper->get_file( __PACKAGE__, 'login' ) );
    my $staticdir = dir( $helper->{dir}, 'root', 'static' );
    $helper->mk_dir( $staticdir );
    $helper->render_file( style => file( $staticdir, 'pagingandsort.css' ) );

    # javascript
    $helper->mk_file( file( $staticdir, 'doubleselect.js' ),
        HTML::Widget::Element::DoubleSelect->js_lib );
    
    # templates
    for my $class (@classes){
        my $classdir = dir( $helper->{dir}, 'root', $class );
        $helper->mk_dir( $classdir );
        $helper->mk_file( file( $classdir, $_ ), $helper->get_file( __PACKAGE__, $_ ) )
        for qw/edit destroy pager/;
        my @fields;
        my @field_configs;
#        warn "fconf: " . Dumper(@{$attrs->{config}{$class}{fields}});
        for my $fconf ( @{$attrs->{config}{$class}} ){
            if( $fconf->{widget_element} and !( $fconf->{widget_element}[0] eq 'Password') ) {
                push @fields, $fconf->{name};
                push @field_configs, $fconf;
            }
        }
        my $fields = join "', '", @fields;
        $helper->{fields} = "[ '$fields' ]";
        $helper->{field_configs} = \@field_configs;
        $helper->render_file( list => file( $classdir, 'list' ));
        $helper->render_file( view => file( $classdir, 'view' ));
    }
    return 1;
}

1; # Magic true value required at end of module
__DATA__

=begin pod_to_ignore

__list__
[% TAGS <+ +> %]
<table>
<tr>
<+ FOR column = field_configs +>
<+- IF column.widget_element.1 == 'multiple' -+>
<th> <+ column.name +> </th>
<+ ELSE +>
<th> [% order_by_column_link('<+ column.name +>', '<+ column.label+>') %] </th>
<+ END +>
<+ END +> 
</tr>
[% WHILE (row = result.next) %]
    <tr>
    <+ FOR column = field_configs +>
    <td>
    <+ IF column.widget_element.1 == 'multiple' +>
    [% FOR val = row.<+ column.name +>; val; ', '; END %]
    <+ ELSE +>
    [%  row.<+ column.name +> %]
    <+ END +>
    </td>
    <+ END +> 
    [% SET id = row.$pri %]
    <td><a href="[% c.uri_for( 'view', id ) %]">View</a></td>
    <td><a href="[% c.uri_for( 'edit', id ) %]">Edit</a></td>
    <td><a href="[% c.uri_for( 'destroy', id ) %]">Destroy</a></td>
    </tr>
[% END %]
</table>
[% PROCESS pager %]
<br/>
<a href="[% c.uri_for( 'add' ) %]">Add</a>

__view__
[% TAGS <+ +> %]
<+ FOR column = field_configs +>
<b><+ column.label +>:</b> 
    <+ IF column.widget_element.1 == 'multiple' +>
    [% FOR val = item.<+ column.name +>; val; ', '; END %]
    <+ ELSE +>
    [%  item.<+ column.name +> %]
    <+ END +>
    <br/>
<+ END +>
<hr />
<a href="[% c.uri_for( 'list' ) %]">List</a>


__compclass__
package [% class %];
use base Catalyst::Example::Controller::InstantCRUD;
use strict;

1;
__wrapper__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>[% appname %]</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="[%base%]static/pagingandsort.css" type="text/css" rel="stylesheet"/>
<script src="[%base%]static/doubleselect.js" type="text/javascript" /></script>
</head>
<body>
<div class="table_menu">
[% PROCESS table_menu %]
</div>
<div class="content">
[% content %]
</div>
</body>
</html>
__login__
[% widget %]
__edit__
[% widget %]
<br>
<a href="[% c.uri_for( 'list' ) %]">List</a>
__pager__
<div id="pager">
Results: [% pager.first %] to [% pager.last %] from [% pager.total_entries %]<br />
[%  IF pager.last_page > 1 %]
[%-     FOR page = [ pager.first_page .. pager.last_page ] -%]
[%-         IF page == pager.current_page -%]
<b>[%-          page -%]</b>
[%-         ELSE -%]
<a href="[% c.request.uri_with( 'page' => page )%]">[% page %]</a>
[%-         END -%]
&nbsp;
[%      END -%]
[%- END -%]
</div>

__destroy__
[% destroywidget %]
<br>
<a href="[% c.uri_for( 'list' ) %]">List</a>


__restricted__
This is the restricted area - available only after loggin in.
__home__
This is an application generated by  
<a href="http://search.cpan.org/~zby/Catalyst-Example-InstantCRUD-v0.0.9/lib/Catalyst/Example/InstantCRUD.pm">Catalyst::Example::InstantCRUD</a>
- a generator of simple database applications for the 
<a href="http://catalyst.perl.org">Catalyst</a> framework.
See also 
<a href="http://cpansearch.perl.org/dist/Catalyst/lib/Catalyst/Manual/Intro.pod">Catalyst::Manual::Intro</a>
and
<a href="http://cpansearch.perl.org/dist/Catalyst/lib/Catalyst/Manual/Tutorial.pod">Catalyst::Manual::Tutorial</a>
__style__
/* HTML TAGS */

body {
    font: bold 12px Verdana, sans-serif;
}

.content {
    padding: 12px;
    margin-top: 1px;  
    margin-bottom:0px;
    margin-left: 15px; 
    margin-right: 15px;
    border-color: #000000;
    border-top: 0px;
    border-bottom: 0px;
    border-left: 1px;
    border-right: 1px;
}

A { 
    text-decoration: none; 
    color:#225 
}
A:hover { 
    text-decoration: underline; 
    color:#222 
}

#title {
    z-index: 6;
    width: 100%;
    height: 18px;
    margin-top: 10px;
    font-size: 90%;
    border-bottom: 1px solid #ddf;
    text-align: left;
}

input.submit:hover {
    color: #fff;
    background-color: #7d95b5;
}

table { 
    border: 0px solid; 
    background-color: #ffffff;
}

th {
    background-color: #b5cadc;
    border: 1px solid #778;
    font: bold 12px Verdana, sans-serif;
}

tr.alternate { background-color:#e3eaf0; }
tr:hover { background-color: #b5cadc; }
td { font: 12px Verdana, sans-serif; }


td { font: 12px Verdana, sans-serif; }

.action {
    border: 1px outset #7d95b5;
}

.action:hover {
    color: #fff;
    text-decoration: none;
    background-color: #7d95b5;
}

.pager {
    font: 11px Arial, Helvetica, sans-serif;
    text-align: center;
    border: solid 1px #e2e2e2;
    border-left: 0;
    border-right: 0;
    padding-top: 10px;
    padding-bottom: 10px;
    margin: 0px;
    background-color: #f3f6f8;
}

.pager a {
    padding: 2px 6px;
    border: solid 1px #ddd;
    background: #fff;
    text-decoration: none;
}

.pager a:visited {
    padding: 2px 6px;
    border: solid 1px #ddd;
    background: #fff;
    text-decoration: none;
}

.pager .current-page {
    padding: 2px 6px;
    font-weight: bold;
    vertical-align: top;
}

.pager a:hover {
    color: #fff;
    background: #7d95b5;
    border-color: #036;
    text-decoration: none;
}

/* IDs */

#widget_submit
{
	display: block;
	margin: 0 0 1em 0;
	border: 0 solid #000000;
	border-top: 0 solid #000000;
	padding: 0 1em 1em 1em;
}

#widget
{
	display: block;
	margin: 0 0 1em 0;
	border: 1px solid #FFFFFF;
	/*border-top: 1px solid #000000;*/
	padding: 0 1em 1em 1em;
        background-color: #f3f6f8;
        font: 11px sans-serif;
}

#widget fieldset
{
	display: block;
	margin: 0 0 1em 0;
	border: 0 solid #FFFFFF;
	/*border-top: 1px solid #000000;*/
	border-top: 0 solid #000000;
	padding: 0 1em 1em 1em;
}

#widget fieldset.radio
{
	margin: 0 0 0 -1em;
	border: 0 solid #FFFFFF;
}

#widget fieldset.radio input
{
	position: static;
	clear: both;
	float: left;
        font: 12px sans-serif;
}

#widget fieldset.radio label
{
	position: relative;
	top: -1.25em;
	display: inline;
	width: auto;
	margin: 0 0 0 8em;
	font-weight: bold;
	font-weight: normal;
}

#widget fieldset.radio legend
{
	float: left;
	font-weight: bold;
}

#widget input
{
	position: relative;
	top: -1.4em;
	left: 8em;
	display: block;
        font: 12px sans-serif;
	font-weight: normal;
}

#widget input.submit
{
	clear: both;
	display: block;
	position: relative;
	top: -1.4em;
	left: 8em;
}

.allornone_errors,
.equal_errors,
.empty_errors,
.in_errors,
.ascii_errors,
.any_errors,
.callback_errors,
.date_errors,
.datetime_errors,
.dependon_errors,
.email_errors,
.http_errors,
.integer_errors,
.lenght_errors,
.maybe_errors,
.number_errors,
.printable_errors,
.range_errors,
.regex_errors,
.string_errors,
.time_errors,
.all_errors      
{
        display: block;
}

.error_messages
{
        clear: right;
        float: left;
        display: block;
        width: 80%;
        margin-top: -15px;
        margin-left: 96px;
	padding-bottom: 0px;
        font-weight: normal;
        color: #d00;
}

.doubleselect
{
	display: block;
}

.doubleselect_left
{
	position: relative;
        float: left;
}

.doubleselect_right
{
	position: relative;
        float: left;
        margin-left: 5px;
}

.doubleselect_buttons
{
	position: relative;
        float: left;
        margin-left: 5px;
        margin-top: 20px;
}

.doubleselect_button_left
{
	position: relative;
        float: left;
}

.doubleselect_button_right
{
	position: relative;
        float: left;
}

.label_comments
{
        display: block;
        width: 8em;
        margin-top: 0px;
        font: 11px sans-serif;
        font-weight: normal;
}

#widget label
{
	clear: both;
	float: left;
	display: block;
	width: 100%;
	margin-top: 10px;
	font-weight: bold;
}

#widget select
{
	position: relative;
	top: -1.4em;
	left: 8em;
	display: block;
	width: 10em;
	font-weight: normal;
        font: 12px sans-serif;
}

#widget textarea
{
	position: relative;
	top: -1.4em;
	left: 8em;
	display: block;
	font-weight: normal;
        font: 12px sans-serif;
}
__END__

=head1 NAME

Catalyst::Helper::Controller::InstantCRUD - [One line description of module's purpose here]


=head1 VERSION

This document describes Catalyst::Helper::Controller::InstantCRUD version 0.0.1


=head1 SYNOPSIS

    use Catalyst::Helper::Controller::InstantCRUD;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

=head2 METHODS

=over 4

=item mk_compclass

=back

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Catalyst::Helper::Controller::InstantCRUD requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-helper-controller-instantcrud@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

<Zbigniew Lukasiak>  C<< <<zz bb yy @ gmail.com>> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, <Zbigniew Lukasiak> C<< <<zz bb yy @ gmail.com>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


