<%@ page language="java" pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="com.github.oeuvres.alix.fr.Tag"%>
<%@ page import="com.github.oeuvres.alix.fr.TagFilter"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FormIterator.Order"%>

<%!
/**
 * Options for filters by grammatical types
 */
public enum OptionCat implements Option {

    ALL(
        "Tout", 
        null
    ), 
    NOSTOP(
        "Mots “pleins”", 
        new TagFilter().set(Tag.NOSTOP)
    ),
    SUB(
        "Substantifs", 
        new TagFilter().set(Tag.SUB)
    ),
    NAME(
        "Noms propres",
        new TagFilter().setGroup(Tag.NAME)
    ),
    VERB(
        "Verbes", 
        new TagFilter().set(Tag.VERB)
    ),
    ADJ(
        "Adjectifs",
        new TagFilter().set(Tag.ADJ).set(Tag.VERBger)
    ),
    ADV(
        "Adverbes",
        new TagFilter().set(Tag.ADV)
    ),
    STOP(
        "Mots grammaticaux",
        new TagFilter().setAll().clearGroup(Tag.SUB).clearGroup(Tag.NAME).clear(Tag.VERB).clear(Tag.ADJ).clear(0)
    ),
    UKNOWN(
        "Mots inconnus",
        new TagFilter().set(0)
    ),
    LOC(
        "Locutions",
        new TagFilter().set(Tag.LOC)
    ),
    PERS("Personnes",
        new TagFilter().set(Tag.NAME).set(Tag.NAMEpers).set(Tag.NAMEpersf).set(Tag.NAMEpersm).set(Tag.NAMEauthor).set(Tag.NAMEfict)
    ),
    PLACE(
        "Lieux", 
        new TagFilter().set(Tag.NAMEplace)
    ),
    RS(
        "Autres noms propres",
        new TagFilter().set(Tag.NAME).set(Tag.NAMEevent).set(Tag.NAMEgod).set(Tag.NAMEorg).set(Tag.NAMEpeople)
    ),
    ;
    
    final public String label;
    final public TagFilter tags;

    private OptionCat(final String label, final TagFilter tags) {
        this.label = label;
        this.tags = tags;
    }

    public TagFilter tags()
    {
        return tags;
    }

    public String label()
    {
        return label;
    }

    public String hint()
    {
        return null;
    }
}


/**
 * Label for sort order in an enumeration of forms.
 */
public enum OptionOrder implements Option {
    SCORE("pertinence", null, Order.SCORE), 
    FREQ("occurrences", null, Order.FREQ),
    HITS("nb de textes", null, Order.HITS), 
    OCCS("Total occurrences", null, Order.OCCS),
    DOCS("Total textes", null, Order.DOCS), 
    ALPHA("alphabétique", null, Order.ALPHA),;

    private OptionOrder(final String label, final String hint, Order order) {
        this.label = label;
        this.hint = hint;
        this.order = order;
    }

    final public Order order;
    final public String label;
    final public String hint;

    public String label()
    {
        return label;
    }

    public String hint()
    {
        return hint;
    }

    public Order order()
    {
        return order;
    }

}
%>