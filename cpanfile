# To use: cpanm --installdeps .
requires 'Mojo::UserAgent';
requires 'Mojo::Promise';
requires 'Moo';
requires 'strictures', '>=2, <3';
requires 'namespace::clean';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Memory::Cycle';
};
