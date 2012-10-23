package KPW2012::Web::Patch::Markdown;

use strict;
use warnings;

package Text::Markdown;
{
    no warnings 'redefine';

sub _Markdown {
#
# Main function. The order in which other subs are called here is
# essential. Link and image substitutions need to happen before
# _EscapeSpecialChars(), so that any *'s or _'s in the <a>
# and <img> tags get encoded.
#
    my ($self, $text, $options) = @_;

    $text = $self->_CleanUpDoc($text);

    # Turn block-level HTML elements into hash entries, and interpret markdown in them if they have a 'markdown="1"' attribute
    $text = $self->_HashHTMLBlocks($text, {interpret_markdown_on_attribute => 1});

    $text = $self->_RunBlockGamut($text, {wrap_in_p_tags => 1});

    $text = $self->_UnescapeSpecialChars($text);

    $text = $self->_ConvertCopyright($text);

    return $text . "\n";
}

sub _HashHTMLBlocks {
    my ($self, $text, $options) = @_;
    my $less_than_tab = $self->{tab_width} - 1;

    # Hashify HTML blocks (protect from further interpretation by encoding to an md5):
    # We only want to do this for block-level HTML tags, such as headers,
    # lists, and tables. That's because we still want to wrap <p>s around
    # "paragraphs" that are wrapped in non-block-level tags, such as anchors,
    # phrase emphasis, and spans. The list of tags we're looking for is
    # hard-coded:
    my $block_tags = qr{
          (?:
            p         |  div     |  h[1-6]  |  blockquote  |  pre       |  table  |
            dl        |  ol      |  ul      |  script      |  noscript  |  form   |
            fieldset  |  iframe  |  math    |  ins         |  del
          )
        }x;

    my $tag_attrs = qr{
                        (?:                 # Match one attr name/value pair
                            \s+             # There needs to be at least some whitespace
                                            # before each attribute name.
                            [\w.:_-]+       # Attribute name
                            \s*=\s*
                            (?:
                                ".+?"       # "Attribute value"
                             |
                                '.+?'       # 'Attribute value'
                             |
                                [^\s]+?      # AttributeValue (HTML5)
                            )
                        )*                  # Zero or more
                    }x;

    my $empty_tag = qr{< \w+ $tag_attrs \s* />}oxms;
    my $open_tag =  qr{< $block_tags $tag_attrs \s* >}oxms;
    my $close_tag = undef;       # let Text::Balanced handle this
    my $prefix_pattern = undef;  # Text::Balanced
    my $markdown_attr = qr{ \s* markdown \s* = \s* (['"]) (.*?) \1 }xs;

    use Text::Balanced qw(gen_extract_tagged);
    my $extract_block = gen_extract_tagged($open_tag, $close_tag, $prefix_pattern, { ignore => [$empty_tag] });

    my @chunks;
    # parse each line, looking for block-level HTML tags
    my %interpret_markdowns;
    while ($text =~ s{^(([ ]{0,$less_than_tab}<)?.*\n)}{}m) {
        my $cur_line = $1;
        if (defined $2) {
            # current line could be start of code block

            my ($tag, $remainder, $prefix, $opening_tag, $text_in_tag, $closing_tag) = $extract_block->($cur_line . $text);
            if ($tag) {
                if ($options->{interpret_markdown_on_attribute} and $opening_tag =~ s/$markdown_attr//i) {
                    my $markdown = $2;
                    if ($markdown =~ /^(1|on|yes)$/) {
                        $text_in_tag = $self->_StripLinkDefinitions($text_in_tag);

                        # interpret markdown and reconstruct $tag to include the interpreted $text_in_tag
                        my $wrap_in_p_tags = $opening_tag =~ /^<(div|iframe)/;
                        $tag = $prefix . $opening_tag . "\n"
                          . $self->_RunBlockGamut($text_in_tag, {wrap_in_p_tags => $wrap_in_p_tags})
                          . "\n" . $closing_tag
                        ;
                        $interpret_markdowns{ _md5_utf8($tag) } = {
                            prefix         => $prefix,
                            opening_tag    => $opening_tag,
                            text_in_tag    => $text_in_tag,
                            wrap_in_p_tags => $wrap_in_p_tags,
                            closing_tag    => $closing_tag,
                        }
                    } else {
                        # just remove the markdown="0" attribute
                        $tag = $prefix . $opening_tag . $text_in_tag . $closing_tag;
                    }
                }
                my $key = _md5_utf8($tag);
                $self->{_html_blocks}{$key} = $tag;
                push @chunks, "\n\n" . $key . "\n\n";
                $text = $remainder;
            }
            else {
                # No tag match, so toss $cur_line into @chunks
                push @chunks, $cur_line;
            }
        }
        else {
            # current line could NOT be start of code block
            push @chunks, $cur_line;
        }

    }
    push @chunks, $text;  # whatever is left

    $text = join '', @chunks;

    $text = $self->_StripLinkDefinitions($text);
    for my $key ( keys %interpret_markdowns ) {
        my $val = $interpret_markdowns{$key};
        my $tag
            = $val->{prefix} . $val->{opening_tag} . "\n"
            . $self->_RunBlockGamut($val->{text_in_tag}, {wrap_in_p_tags => $val->{wrap_in_p_tags}})
            . "\n" . $val->{closing_tag}
            ;

        $self->{_html_blocks}{$key} = $tag;
    }

    return $text;
}

}

package Text::MultiMarkdown;
{
    no warnings 'redefine';

sub _Markdown {
#
# Main function. The order in which other subs are called here is
# essential. Link and image substitutions need to happen before
# _EscapeSpecialChars(), so that any *'s or _'s in the <a>
# and <img> tags get encoded.
#
# Can't think of any good way to make this inherit from the Markdown version as ordering is so important, so I've left it.
    my ($self, $text) = @_;

    $text = $self->_CleanUpDoc($text);

    # MMD only. Strip out MetaData
    $text = $self->_ParseMetaData($text) if ($self->{use_metadata} || $self->{strip_metadata});

    # Turn block-level HTML blocks into hash entries
    $text = $self->_HashHTMLBlocks($text, {interpret_markdown_on_attribute => 1});

    # MMD only
    $text = $self->_StripMarkdownReferences($text);

    $text = $self->_RunBlockGamut($text, {wrap_in_p_tags => 1});

    # MMD Only
    $text = $self->_DoMarkdownCitations($text) unless $self->{disable_bibliography};
    $text = $self->_DoFootnotes($text) unless $self->{disable_footnotes};

    $text = $self->_UnescapeSpecialChars($text);

    # MMD Only
    # This must follow _UnescapeSpecialChars
    $text = $self->_UnescapeWikiWords($text);
    $text = $self->_FixFootnoteParagraphs($text) unless $self->{disable_footnotes}; # TODO: remove. Doesn't make any difference to test suite pass/failure
    $text .= $self->_PrintFootnotes() unless $self->{disable_footnotes};
    $text .= $self->_PrintMarkdownBibliography() unless $self->{disable_bibliography};

    $text = $self->_ConvertCopyright($text);

    # MMD Only
    if (lc($self->{document_format}) =~ /^complete\s*$/) {
        return $self->_xhtmlMetaData() . "<body>\n" . $text . "\n</body>\n</html>";
    }
    else {
        return $self->_textMetaData() . $text . "\n";
    }

}

}

1;
