package obvie;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Path;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.time.Duration;
import java.util.Date;
import java.util.InvalidPropertiesFormatException;
import java.util.Properties;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;

import org.apache.lucene.index.IndexWriter;
import org.xml.sax.SAXException;

import alix.lucene.Alix;
import alix.lucene.SrcFormat;
import alix.lucene.XMLIndexer;
import alix.lucene.analysis.FrAnalyzer;
import alix.lucene.util.Cooc;
import alix.util.Dir;

public class Base
{
  public static String APP = "Obvie";
  static public void index(File file, int threads) throws IOException, NoSuchFieldException, ParserConfigurationException, SAXException, InterruptedException, TransformerException 
  {
    String name = file.getName().replaceFirst("\\..+$", "");
    if (!file.exists()) throw new FileNotFoundException("\n  ["+APP+"] "+file.getAbsolutePath()+"\nFichier de propriétés introuvable ");
    Properties props = new Properties();
    try {
      props.loadFromXML(new FileInputStream(file));
    }
    catch (InvalidPropertiesFormatException e) {
      throw new InvalidPropertiesFormatException("\n  ["+APP+"] "+file+"\nXML, erreur dans le fichier de propriétés.\n"
          +"cf. https://docs.oracle.com/javase/8/docs/api/java/util/Properties.html");
    }
    catch (IOException e) {
      throw new IOException("\n  ["+APP+"] "+file.getAbsolutePath()+"\nLecture impossible du fichier de propriétés.");
    }
    String src = props.getProperty("src");
    if (src == null) throw new NoSuchFieldException("\n  ["+APP+"] "+file+"\n<entry key=\"src\"> est requis pour indiquer le chemin des fichiers XML/TEI à indexer."
        + "\nLes jokers sont autorisés, par exemple : ../../corpus/*.xml");
    String[] globs = src.split(" *[;:] *");
    // resolve globs relative to the folder of the properties field
    File base = file.getParentFile().getCanonicalFile();
    for (int i=0; i < globs.length; i++) {
      if (!globs[i].startsWith("/")) globs[i] = new File(base, globs[i]).getCanonicalPath();
    }
    // test here if it's folder ?
    long time = System.nanoTime();
    
    String tmpName = "000_obvie";
    // indexer d'abord dans un index temporaire
    File tmpDir = new File(file.getParentFile(), tmpName);
    if (tmpDir.exists()) {
      long modified = tmpDir.lastModified();
      Duration duration = Duration.ofMillis(System.currentTimeMillis() - modified);
      throw new IOException("\n  ["+APP+"] Un autre processus d'indexation semble en cours depuis "+duration+"\n" + tmpDir
          + "\nSi vous pensez que c’est une erreur, vous devez supprimez vous-mêmes ce dossier.");
    }
    Path tmpPath = tmpDir.toPath();
    Runtime.getRuntime().addShutdownHook(new Thread() {
      @Override
      public void run() {
        if (!tmpDir.exists()) return;
        System.out.println("Interruption inattendue du processus d'indexation, vos bases n’ont pas été modifiées. Suppression de l'index temporaire :\n" + tmpPath);
        try {
          TimeUnit.SECONDS.sleep(1);
          int timeout = 10;
          while (!tmpDir.canWrite()) {
            TimeUnit.SECONDS.sleep(1);
            if(--timeout == 0) throw new IOException("\n  ["+APP+"] Impossible de suppimer l'index temporaire\n" + tmpDir);
          }
          Dir.rm(tmpDir);
          // Encore là ?
          while (tmpDir.exists()) {
            TimeUnit.SECONDS.sleep(1);
            Dir.rm(tmpDir);
            if(--timeout == 0) throw new IOException("\n  ["+APP+"] Impossible de suppimer l'index temporaire\n" + tmpDir);
          }
        }
        catch (Exception e) {
          e.printStackTrace();
        }
      }
    });
    Alix alix = Alix.instance(tmpPath, new FrAnalyzer());
    // Alix alix = Alix.instance(path, "org.apache.lucene.analysis.core.WhitespaceAnalyzer");
    IndexWriter writer = alix.writer();
    XMLIndexer.index(writer, globs, SrcFormat.tei, threads);
    // index here will be committed and merged but need to be closed for cooccurrences
    writer.close();
    Cooc cooc = new Cooc(alix, "text");
    cooc.write();
    System.out.println("["+APP+"] "+name+" indexé en " + ((System.nanoTime() - time) / 1000000) + " ms.");
    
    TimeZone tz = TimeZone.getTimeZone("UTC");
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd_HH:mm:ss");
    df.setTimeZone(tz);
    File oldDir = new File(file.getParentFile(), "_"+name+"_"+df.format(new Date()));
    File theDir = new File(file.getParentFile(), name);
    System.out.println(theDir);
    if (theDir.exists()) {
      theDir.renameTo(oldDir);
      System.out.println("["+APP+"] Par précaution, votre ancien index a été conservé dans le dossier :\n"+oldDir);
    }
    tmpDir.renameTo(theDir);
  }
  public static void main(String[] args) throws Exception
  {
    if (args == null || args.length < 1) {
      System.out.println("["+APP+"] usage");
      System.out.println("WEB-INF$ java -cp lib/obvie.jar bases/ma_base.xml");
      System.exit(1);
    }
    int threads = Runtime.getRuntime().availableProcessors() - 1;
    int i = 0;
    try {
      int n = Integer.parseInt(args[0]);
      if (n > 0 && n < threads) threads = n;
      i++;
      System.out.println("["+APP+"] threads="+threads);
    }
    catch (NumberFormatException e) {
      
    }
    if (i >= args.length) {
      System.out.println("["+APP+"] usage");
      System.out.println("WEB-INF$ java -cp lib/obvie.jar bases/ma_base.xml");
      System.exit(1);
    }
    for(; i < args.length; i++) {
      index(new File(args[i]), threads);
    }
  }
}
