<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.nio.file.Paths" %>
<%!
static public enum Tab {
  freqs("Mots", "index.jsp", "Fréquences par mots", new String[]{"book", "ranking"}) {
  },
  books("Livres", "books.jsp", "Fréquences par livres", new String[]{"ranking", "q"}) {
  },
  kwic("Concordance", "kwic.jsp", "Recherche de mot", new String[]{"book", "ranking", "q"}) {
  },
  ;
  
  final public String label;
  final public String href;
  final public String hint;
  final public String[] pars;
  private Tab(final String label, final String href, final String hint, final String[] pars) {  
    this.label = label ;
    this.href = href;
    this.hint = hint;
    if (pars == null) this.pars = new String[0];
    else this.pars = pars;
  }

  public static String nav(final HttpServletRequest request)
  {
    StringBuilder sb = new StringBuilder();
    boolean first = true;
    for(Tab tab:Tab.values()) {
      tab.a(sb, request);
      sb.append("\n");
    }
    return sb.toString();
  }
  
  public void a(final StringBuilder sb, final HttpServletRequest request)
  {
    String here = request.getRequestURI();
    here = here.substring(here.lastIndexOf('/'));

    sb.append("<a");
    sb.append(" href=\"").append(this.href);
    boolean first = true;
    for (String par: pars) {
      String value = request.getParameter(par);
      if (value == null) continue;
      if (first) {
        first = false;
        sb.append("?");
      }
      else {
        sb.append("&amp;");
      }
      sb.append(par).append("=").append(value);
    }
    sb.append("\"");
    if (hint != null) sb.append(" title=\"").append(hint).append("\"");
    sb.append(" class=\"tab");
    if (here.equals("") && this.href.startsWith("index"))  sb.append(" selected");
    else if (this.href.equals("index")) sb.append(" selected");
    sb.append("\"");
    sb.append(">");
    sb.append(label);
    sb.append("</a>");
  }
}

%>
<nav class="tabs">
  <%= Tab.nav(request) %>
</nav>